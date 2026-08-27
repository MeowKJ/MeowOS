#include "app_session.h"

#include <utility>

namespace meow {

AppSession::AppSession(std::string appId)
    : appId_(std::move(appId))
{
}

bool AppSession::requestStart()
{
    if (state_ != AppSessionState::Stopped && state_ != AppSessionState::Failed)
        return false;
    state_ = AppSessionState::Starting;
    return true;
}

bool AppSession::markRunning()
{
    if (state_ != AppSessionState::Starting)
        return false;
    state_ = AppSessionState::Running;
    return true;
}

bool AppSession::requestStop()
{
    if (state_ != AppSessionState::Running && state_ != AppSessionState::Starting)
        return false;
    state_ = AppSessionState::Stopping;
    return true;
}

bool AppSession::markStopped()
{
    if (state_ != AppSessionState::Stopping)
        return false;
    state_ = AppSessionState::Stopped;
    return true;
}

bool AppSession::markFailed()
{
    if (state_ == AppSessionState::Stopped)
        return false;
    state_ = AppSessionState::Failed;
    return true;
}

} // namespace meow
