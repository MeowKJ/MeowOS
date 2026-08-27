#include "runtime/app_session.h"
#include "runtime/task_scheduler.h"
#include "runtime/app_session_supervisor.h"
#include "runtime/runtime_snapshot.h"
#include "hal/hal_interfaces.h"

#include <atomic>
#include <cassert>
#include <thread>
#include <stdexcept>
#include <utility>
#include <vector>

int main()
{
    const meow::DisplayGeometry geometry = meow::makeLogicalGeometry(800, 1280, 90);
    assert(geometry.logicalWidth == 1280 && geometry.logicalHeight == 800);
    const meow::TouchPoint topLeft = meow::transformTouchPoint({0, 0}, 800, 1280, 90);
    assert(topLeft.x == 1279 && topLeft.y == 0);

    meow::AppSession session("mindustry");
    assert(session.requestStart());
    assert(session.markRunning());
    assert(session.requestStop());
    assert(session.markStopped());

    meow::AppSessionSupervisor supervisor;
    assert(supervisor.start("mindustry"));
    assert(supervisor.activeAppId() == "mindustry");
    assert(!supervisor.start("another-app"));
    assert(supervisor.stop());
    assert(!supervisor.hasActiveSession());
    assert(supervisor.start("settings"));
    assert(supervisor.fail());

    meow::TaskScheduler scheduler(4);
    std::atomic<int> completed(0);
    std::vector<std::future<void>> jobs;
    for (int i = 0; i < 32; ++i) {
        jobs.push_back(scheduler.submit(meow::TaskPriority::Background, [&completed] {
            std::this_thread::yield();
            ++completed;
        }));
    }
    for (std::future<void> &job : jobs)
        job.get();
    assert(completed.load() == 32);
    assert(scheduler.runningTasks() == 0);
    scheduler.shutdown();

    meow::TaskScheduler bounded(1, 1);
    std::promise<void> release;
    std::future<void> gate = release.get_future();
    const std::future<void> first = bounded.submit(meow::TaskPriority::Background,
                                                    [&gate] { gate.wait(); });
    bool rejected = false;
    try {
        bounded.submit(meow::TaskPriority::Background, [] {});
        bounded.submit(meow::TaskPriority::Background, [] {});
    } catch (const std::runtime_error &) {
        rejected = true;
    }
    assert(rejected);
    release.set_value();
    first.wait();
    bounded.shutdown();

    meow::RuntimeSnapshotStore snapshots;
    std::atomic<bool> publishing(true);
    std::thread writer([&snapshots, &publishing] {
        for (std::uint64_t i = 1; i <= 1000; ++i) {
            meow::RuntimeSnapshot snapshot;
            snapshot.sequence = i;
            snapshot.cpuPercent = static_cast<int>(i % 101);
            snapshot.foregroundApp = "mindustry";
            snapshots.publish(std::move(snapshot));
        }
        publishing.store(false);
    });
    std::uint64_t lastSequence = 0;
    while (publishing.load() || snapshots.read()->sequence < 1000) {
        const std::shared_ptr<const meow::RuntimeSnapshot> current = snapshots.read();
        assert(current->sequence >= lastSequence);
        assert(current->cpuPercent < 0 || current->cpuPercent <= 100);
        lastSequence = current->sequence;
    }
    writer.join();
    assert(snapshots.read()->sequence == 1000);
    return 0;
}
