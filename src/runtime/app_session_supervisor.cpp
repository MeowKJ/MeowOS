#include "app_session_supervisor.h"

namespace meow {

const std::string AppSessionSupervisor::emptyAppId_;

bool AppSessionSupervisor::beginStart(const std::string &appId)
{
    if (appId.empty() || active_) return false;
    std::unique_ptr<AppSession> candidate(new AppSession(appId));
    if (!candidate->requestStart()) return false;
    active_ = std::move(candidate);
    return true;
}

bool AppSessionSupervisor::markRunning()
{
    return active_ && active_->markRunning();
}

bool AppSessionSupervisor::start(const std::string &appId)
{
    return beginStart(appId) && markRunning();
}

bool AppSessionSupervisor::stop()
{
    if (!active_ || !active_->requestStop() || !active_->markStopped()) return false;
    active_.reset();
    return true;
}

bool AppSessionSupervisor::fail()
{
    if (!active_ || !active_->markFailed()) return false;
    active_.reset();
    return true;
}

bool AppSessionSupervisor::hasActiveSession() const { return static_cast<bool>(active_); }

const std::string &AppSessionSupervisor::activeAppId() const
{
    return active_ ? active_->appId() : emptyAppId_;
}

AppSessionState AppSessionSupervisor::state() const
{
    return active_ ? active_->state() : AppSessionState::Stopped;
}

} // namespace meow
