#include "runtime_snapshot.h"

#include <utility>

namespace meow {

RuntimeSnapshotStore::RuntimeSnapshotStore()
    : snapshot_(std::make_shared<const RuntimeSnapshot>())
{
}

std::shared_ptr<const RuntimeSnapshot> RuntimeSnapshotStore::read() const
{
    return std::atomic_load_explicit(&snapshot_, std::memory_order_acquire);
}

void RuntimeSnapshotStore::publish(RuntimeSnapshot snapshot)
{
    std::shared_ptr<const RuntimeSnapshot> next(
        new RuntimeSnapshot(std::move(snapshot)));
    std::atomic_store_explicit(&snapshot_, std::move(next), std::memory_order_release);
}

} // namespace meow
