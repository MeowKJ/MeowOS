#include "runtime/app_session.h"
#include "runtime/task_scheduler.h"
#include "runtime/app_session_supervisor.h"
#include "hal/hal_interfaces.h"

#include <atomic>
#include <cassert>
#include <thread>
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
    scheduler.shutdown();
    return 0;
}
