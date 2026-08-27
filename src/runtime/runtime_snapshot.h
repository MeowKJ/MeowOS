#pragma once

#include <atomic>
#include <cstdint>
#include <memory>
#include <string>

namespace meow {

struct RuntimeSnapshot {
    std::uint64_t sequence = 0;
    int cpuPercent = -1;
    int memoryPercent = -1;
    int gpuPercent = -1;
    int displayRotation = 0;
    std::string foregroundApp;
};

// Lock-free readers of immutable state. Writers replace the whole snapshot;
// readers never observe a partially updated collection of metrics.
class RuntimeSnapshotStore final {
public:
    RuntimeSnapshotStore();

    std::shared_ptr<const RuntimeSnapshot> read() const;
    void publish(RuntimeSnapshot snapshot);

private:
    std::shared_ptr<const RuntimeSnapshot> snapshot_;
};

} // namespace meow
