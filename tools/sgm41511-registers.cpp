#include <cerrno>
#include <cstdint>
#include <cstdio>
#include <cstdlib>
#include <cstring>
#include <fcntl.h>
#include <linux/i2c-dev.h>
#include <linux/i2c.h>
#include <sys/ioctl.h>
#include <unistd.h>

static bool readRegister(int fd, unsigned short address, unsigned char reg,
                         unsigned char *value, unsigned short length = 1)
{
    i2c_msg messages[2] = {};
    messages[0].addr = address;
    messages[0].len = 1;
    messages[0].buf = &reg;
    messages[1].addr = address;
    messages[1].flags = I2C_M_RD;
    messages[1].len = length;
    messages[1].buf = value;
    i2c_rdwr_ioctl_data transaction = {messages, 2};
    return ioctl(fd, I2C_RDWR, &transaction) >= 0;
}

int main(int argc, char **argv)
{
    const char *device = argc > 1 ? argv[1] : "/dev/i2c-1";
    const int fd = open(device, O_RDWR | O_CLOEXEC);
    if (fd < 0) {
        std::fprintf(stderr, "open %s: %s\n", device, std::strerror(errno));
        return EXIT_FAILURE;
    }
    unsigned char registers[12] = {};
    for (unsigned char reg = 0; reg < sizeof(registers); ++reg) {
        if (!readRegister(fd, 0x6b, reg, &registers[reg])) {
            std::fprintf(stderr, "read REG%02X: %s\n", reg, std::strerror(errno));
            close(fd);
            return EXIT_FAILURE;
        }
        std::printf("REG%02X=0x%02X%s", reg, registers[reg], reg == 11 ? "\n" : " ");
    }
    const int inputLimitMa = 100 + (registers[0] & 0x1f) * 100;
    const int fastChargeMa = (registers[2] & 0x3f) * 60;
    const int watchdogSeconds[] = {0, 40, 80, 160};
    const int watchdog = watchdogSeconds[(registers[5] >> 4) & 0x03];
    std::printf("SGM_ID=0x%02X IINDPM=%dmA ICHG=%dmA WATCHDOG=%ds\n",
                registers[11] & 0x7c, inputLimitMa, fastChargeMa, watchdog);

    unsigned char voltageBytes[2] = {};
    unsigned char currentBytes[2] = {};
    unsigned char socBytes[2] = {};
    if (readRegister(fd, 0x55, 0x08, voltageBytes, 2)
            && readRegister(fd, 0x55, 0x14, currentBytes, 2)
            && readRegister(fd, 0x55, 0x2c, socBytes, 2)) {
        const int voltageMv = voltageBytes[0] | (voltageBytes[1] << 8);
        const std::int16_t currentMa = static_cast<std::int16_t>(currentBytes[0]
                                                                 | (currentBytes[1] << 8));
        const int soc = socBytes[0] | (socBytes[1] << 8);
        std::printf("BQ_VOLTAGE=%dmV BQ_CURRENT=%dmA BQ_SOC=%d%%\n",
                    voltageMv, static_cast<int>(currentMa), soc);
    }
    close(fd);
    return (registers[11] & 0x7c) == 0x14 ? EXIT_SUCCESS : EXIT_FAILURE;
}
