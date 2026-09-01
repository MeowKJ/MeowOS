#include "app_session_supervisor.h"

namespace meow {

bool AppSessionSupervisor::beginStart(const std::string &appId)
{
    std::lock_guard<std::mutex> lock(mutex_);
    if (appId.empty() || active_) return false;
    std::unique_ptr<AppSession> candidate(new AppSession(appId));
    if (!candidate->requestStart()) return false;
    active_ = std::move(candidate);
    return true;
}

bool AppSessionSupervisor::markRunning()
{
    std::lock_guard<std::mutex> lock(mutex_);
    return active_ && active_->markRunning();
}

bool AppSessionSupervisor::start(const std::string &appId)
{
    return beginStart(appId) && markRunning();
}

bool AppSessionSupervisor::stop()
{
    std::lock_guard<std::mutex> lock(mutex_);
    if (!active_ || !active_->requestStop() || !active_->markStopped()) return false;
    active_.reset();
    return true;
}

bool AppSessionSupervisor::fail()
{
    std::lock_guard<std::mutex> lock(mutex_);
    if (!active_ || !active_->markFailed()) return false;
    active_.reset();
    return true;
}

bool AppSessionSupervisor::hasActiveSession() const { std::lock_guard<std::mutex> lock(mutex_); return static_cast<bool>(active_); }

std::string AppSessionSupervisor::activeAppId() const
{
    std::lock_guard<std::mutex> lock(mutex_);
    return active_ ? active_->appId() : std::string();
}

AppSessionState AppSessionSupervisor::state() const
{
    std::lock_guard<std::mutex> lock(mutex_);
    return active_ ? active_->state() : AppSessionState::Stopped;
}

} // namespace meow
