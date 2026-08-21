#include <cerrno>
#include <cstdio>
#include <cstdlib>
#include <fcntl.h>
#include <linux/i2c-dev.h>
#include <linux/i2c.h>
#include <sys/ioctl.h>
#include <unistd.h>

int main(int argc, char **argv)
{
    if (argc != 5) {
        std::fprintf(stderr, "usage: %s /dev/i2c-N address register length\n", argv[0]);
        return 2;
    }
    const int address = static_cast<int>(std::strtol(argv[2], nullptr, 0));
    const unsigned char reg = static_cast<unsigned char>(std::strtol(argv[3], nullptr, 0));
    const int length = static_cast<int>(std::strtol(argv[4], nullptr, 0));
    if (address < 0x03 || address > 0x77 || length < 1 || length > 32) return 2;

    const int fd = ::open(argv[1], O_RDWR);
    if (fd < 0) {
        std::perror("open");
        return 1;
    }
    unsigned char data[32] = {};
    i2c_msg messages[2] = {};
    messages[0].addr = static_cast<__u16>(address);
    messages[0].len = 1;
    messages[0].buf = const_cast<unsigned char *>(&reg);
    messages[1].addr = static_cast<__u16>(address);
    messages[1].flags = I2C_M_RD;
    messages[1].len = static_cast<__u16>(length);
    messages[1].buf = data;
    i2c_rdwr_ioctl_data transaction = { messages, 2 };
    if (::ioctl(fd, I2C_RDWR, &transaction) < 0) {
        std::perror("I2C_RDWR");
        ::close(fd);
        return 1;
    }
    for (int i = 0; i < length; ++i) std::printf("%s%02x", i ? " " : "", data[i]);
    std::printf("\n");
    ::close(fd);
    return 0;
}
