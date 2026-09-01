#include "task_scheduler.h"

#include <algorithm>
#include <stdexcept>

namespace meow {

TaskScheduler::TaskScheduler(std::size_t workerCount, std::size_t maxPendingTasks)
    : maxPendingTasks_(std::max<std::size_t>(1, maxPendingTasks))
{
    if (workerCount == 0)
        workerCount = std::max<std::size_t>(2, std::thread::hardware_concurrency());
    workers_.reserve(workerCount);
    for (std::size_t i = 0; i < workerCount; ++i)
        workers_.emplace_back(&TaskScheduler::workerLoop, this);
}

TaskScheduler::~TaskScheduler()
{
    shutdown();
}

bool TaskScheduler::WorkOrder::operator()(const WorkItem &left, const WorkItem &right) const
{
    if (left.priority != right.priority)
        return static_cast<unsigned>(left.priority) > static_cast<unsigned>(right.priority);
    return left.sequence > right.sequence;
}

std::future<void> TaskScheduler::submit(TaskPriority priority, std::function<void()> task)
{
    std::shared_ptr<std::packaged_task<void()>> packaged(
        new std::packaged_task<void()>(std::move(task)));
    std::future<void> result = packaged->get_future();
    {
        std::lock_guard<std::mutex> lock(mutex_);
        if (stopping_)
            throw std::runtime_error("TaskScheduler is stopped");
        if (queue_.size() >= maxPendingTasks_)
            throw std::runtime_error("TaskScheduler queue is full");
        queue_.push(WorkItem{priority, nextSequence_.fetch_add(1),
                             [packaged]() { (*packaged)(); }});
        submittedTasks_.fetch_add(1, std::memory_order_relaxed);
        std::size_t peak = peakPendingTasks_.load(std::memory_order_relaxed);
        while (queue_.size() > peak && !peakPendingTasks_.compare_exchange_weak(
                   peak, queue_.size(), std::memory_order_relaxed)) {}
    }
    wakeup_.notify_one();
    return result;
}

bool TaskScheduler::trySubmit(TaskPriority priority, std::function<void()> task)
{
    try { (void)submit(priority, std::move(task)); return true; }
    catch (const std::exception &) {
        rejectedTasks_.fetch_add(1, std::memory_order_relaxed);
        return false;
    }
}

void TaskScheduler::shutdown()
{
    {
        std::lock_guard<std::mutex> lock(mutex_);
        if (stopping_)
            return;
        stopping_ = true;
    }
    wakeup_.notify_all();
    for (std::thread &worker : workers_) {
        if (worker.joinable())
            worker.join();
    }
    workers_.clear();
}

std::size_t TaskScheduler::workerCount() const
{
    return workers_.size();
}

std::size_t TaskScheduler::pendingTasks() const
{
    std::lock_guard<std::mutex> lock(mutex_);
    return queue_.size();
}

std::size_t TaskScheduler::runningTasks() const
{
    return runningTasks_.load(std::memory_order_acquire);
}

void TaskScheduler::workerLoop()
{
    for (;;) {
        WorkItem item;
        {
            std::unique_lock<std::mutex> lock(mutex_);
            wakeup_.wait(lock, [this] { return stopping_ || !queue_.empty(); });
            if (stopping_ && queue_.empty())
                return;
            item = queue_.top();
            queue_.pop();
        }
        runningTasks_.fetch_add(1, std::memory_order_acq_rel);
        try {
            item.task();
        } catch (...) {
            // A malformed direct WorkItem must not kill the worker or leave
            // the observability counter permanently elevated.
        }
        completedTasks_.fetch_add(1, std::memory_order_relaxed);
        runningTasks_.fetch_sub(1, std::memory_order_acq_rel);
    }
}

SchedulerStats TaskScheduler::stats() const
{
    SchedulerStats value;
    value.pending = pendingTasks();
    value.running = runningTasks();
    value.submitted = submittedTasks_.load(std::memory_order_relaxed);
    value.completed = completedTasks_.load(std::memory_order_relaxed);
    value.rejected = rejectedTasks_.load(std::memory_order_relaxed);
    value.peakPending = peakPendingTasks_.load(std::memory_order_relaxed);
    return value;
}

} // namespace meow
