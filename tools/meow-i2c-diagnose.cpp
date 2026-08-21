#include <cerrno>
#include <cstdlib>
#include <cstdio>
#include <cstring>
#include <fcntl.h>
#include <linux/i2c-dev.h>
#include <linux/i2c.h>
#include <sys/ioctl.h>
#include <unistd.h>

static void result(const char *method, int rc, unsigned value = 0)
{
    if (rc >= 0) std::printf("%-12s ACK 0x%04x\n", method, value);
    else std::printf("%-12s NACK errno=%d (%s)\n", method, errno, std::strerror(errno));
}

int main(int argc, char **argv)
{
    if (argc != 5) {
        std::fprintf(stderr, "usage: %s /dev/i2c-N address register length\n", argv[0]);
        return 2;
    }
    const int address = static_cast<int>(std::strtol(argv[2], nullptr, 0));
    unsigned char reg = static_cast<unsigned char>(std::strtol(argv[3], nullptr, 0));
    const int length = static_cast<int>(std::strtol(argv[4], nullptr, 0));
    if (length != 1 && length != 2) return 2;
    const int fd = ::open(argv[1], O_RDWR | O_CLOEXEC);
    if (fd < 0) { std::perror("open"); return 1; }

    unsigned long funcs = 0;
    if (::ioctl(fd, I2C_FUNCS, &funcs) == 0) std::printf("adapter_funcs=0x%lx\n", funcs);

    unsigned char combinedData[2] = {};
    i2c_msg messages[2] = {};
    messages[0].addr = address;
    messages[0].len = 1;
    messages[0].buf = &reg;
    messages[1].addr = address;
    messages[1].flags = I2C_M_RD;
    messages[1].len = static_cast<__u16>(length);
    messages[1].buf = combinedData;
    i2c_rdwr_ioctl_data transaction = { messages, 2 };
    errno = 0;
    int rc = ::ioctl(fd, I2C_RDWR, &transaction);
    result("combined", rc, combinedData[0] | (combinedData[1] << 8));

    ::usleep(100000);
    errno = 0;
    rc = ::ioctl(fd, I2C_SLAVE, address);
    if (rc >= 0) rc = (::write(fd, &reg, 1) == 1) ? 0 : -1;
    result("pointer-write", rc);
    if (rc >= 0) {
        ::usleep(100000);
        rc = (::read(fd, combinedData, length) == length) ? 0 : -1;
    }
    result("raw-read", rc, combinedData[0] | (combinedData[1] << 8));

    ::usleep(100000);
    union i2c_smbus_data smbusData = {};
    i2c_smbus_ioctl_data smbus = {};
    smbus.read_write = I2C_SMBUS_READ;
    smbus.command = reg;
    smbus.size = length == 2 ? I2C_SMBUS_WORD_DATA : I2C_SMBUS_BYTE_DATA;
    smbus.data = &smbusData;
    errno = 0;
    rc = ::ioctl(fd, I2C_SMBUS, &smbus);
    result("smbus-data", rc, length == 2 ? smbusData.word : smbusData.byte);

    ::usleep(100000);
    smbus.size = I2C_SMBUS_BYTE_DATA;
    errno = 0;
    rc = ::ioctl(fd, I2C_SMBUS, &smbus);
    result("smbus-byte", rc, smbusData.byte);

    ::close(fd);
    return 0;
}
