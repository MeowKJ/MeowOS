#pragma once

#include <atomic>
#include <condition_variable>
#include <cstddef>
#include <cstdint>
#include <functional>
#include <future>
#include <mutex>
#include <memory>
#include <queue>
#include <thread>
#include <vector>

namespace meow {

enum class TaskPriority : std::uint8_t {
    Critical = 0,
    Interactive = 1,
    Background = 2
};

// Small bounded-priority executor for the platform runtime. UI and input code
// never runs here directly; they submit work and receive a future/event back.
class TaskScheduler final {
public:
    explicit TaskScheduler(std::size_t workerCount = 0);
    ~TaskScheduler();

    TaskScheduler(const TaskScheduler &) = delete;
    TaskScheduler &operator=(const TaskScheduler &) = delete;

    std::future<void> submit(TaskPriority priority, std::function<void()> task);
    void shutdown();
    std::size_t workerCount() const;
    std::size_t pendingTasks() const;

private:
    struct WorkItem {
        TaskPriority priority;
        std::uint64_t sequence;
        std::function<void()> task;
    };

    struct WorkOrder {
        bool operator()(const WorkItem &left, const WorkItem &right) const;
    };

    void workerLoop();

    mutable std::mutex mutex_;
    std::condition_variable wakeup_;
    std::priority_queue<WorkItem, std::vector<WorkItem>, WorkOrder> queue_;
    std::vector<std::thread> workers_;
    std::atomic<std::uint64_t> nextSequence_{0};
    bool stopping_ = false;
};

} // namespace meow
