#include "runtime/app_session.h"
#include "runtime/task_scheduler.h"
#include "runtime/app_session_supervisor.h"
#include "runtime/runtime_snapshot.h"
#include "hal/hal_interfaces.h"

#include <atomic>
#include <cassert>
#include <future>
#include <mutex>
#include <thread>
#include <stdexcept>
#include <utility>
#include <vector>

namespace {
class MockDisplay final : public meow::IDisplayHal {
public:
    explicit MockDisplay(meow::DisplayGeometry geometry) : geometry_(geometry) {}
    meow::DisplayGeometry geometry() const override { return geometry_; }
    bool setBrightnessPercent(int) override { return true; }
private:
    meow::DisplayGeometry geometry_;
};

class MockInput final : public meow::IInputHal {
public:
    bool setDisplayGeometry(const meow::DisplayGeometry &geometry) override
    {
        geometry_ = geometry;
        return geometry.logicalWidth > 0 && geometry.logicalHeight > 0;
    }
    bool start() override { return geometry_.logicalWidth > 0; }
    void stop() override {}
    std::string deviceName() const override { return "mock-touch"; }
private:
    meow::DisplayGeometry geometry_;
};
} // namespace

int main()
{
    const meow::DisplayGeometry geometry = meow::makeLogicalGeometry(800, 1280, 90);
    assert(geometry.logicalWidth == 1280 && geometry.logicalHeight == 800);
    const meow::TouchPoint topLeft = meow::transformTouchPoint({0, 0}, 800, 1280, 90);
    assert(topLeft.x == 1279 && topLeft.y == 0);
    MockDisplay display(geometry);
    MockInput input;
    assert(!input.start());
    assert(input.setDisplayGeometry(display.geometry()));
    assert(input.start());

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
    assert(supervisor.beginStart("reaction-game"));
    assert(supervisor.state() == meow::AppSessionState::Starting);
    assert(!supervisor.beginStart("another-app"));
    assert(supervisor.markRunning());
    assert(supervisor.stop());
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

    meow::TaskScheduler priorityScheduler(1, 8);
    std::promise<void> priorityRelease;
    std::future<void> priorityGate = priorityRelease.get_future();
    std::vector<int> order;
    std::mutex orderMutex;
    const std::future<void> blocker = priorityScheduler.submit(meow::TaskPriority::Critical,
        [&priorityGate, &order, &orderMutex] {
            { std::lock_guard<std::mutex> lock(orderMutex); order.push_back(0); }
            priorityGate.wait();
        });
    while (priorityScheduler.runningTasks() == 0) std::this_thread::yield();
    const std::future<void> low = priorityScheduler.submit(meow::TaskPriority::Background,
        [&order, &orderMutex] { std::lock_guard<std::mutex> lock(orderMutex); order.push_back(1); });
    const std::future<void> high = priorityScheduler.submit(meow::TaskPriority::Critical,
        [&order, &orderMutex] { std::lock_guard<std::mutex> lock(orderMutex); order.push_back(2); });
    priorityRelease.set_value();
    blocker.get();
    high.get();
    low.get();
    assert(order.size() == 3 && order[0] == 0 && order[1] == 2 && order[2] == 1);
    priorityScheduler.shutdown();

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
