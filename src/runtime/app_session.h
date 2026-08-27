#pragma once

#include <string>

namespace meow {

enum class AppSessionState {
    Stopped,
    Starting,
    Running,
    Stopping,
    Failed
};

// Pure state machine. Process/display/input adapters will be attached later;
// this keeps application policy independent from Qt and systemd details.
class AppSession final {
public:
    explicit AppSession(std::string appId);

    const std::string &appId() const { return appId_; }
    AppSessionState state() const { return state_; }
    bool requestStart();
    bool markRunning();
    bool requestStop();
    bool markStopped();
    bool markFailed();

private:
    std::string appId_;
    AppSessionState state_ = AppSessionState::Stopped;
};

} // namespace meow
