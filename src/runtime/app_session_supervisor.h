#pragma once

#include "app_session.h"

#include <memory>
#include <string>

namespace meow {

// Policy-only foreground session owner. Process launch/kill is deliberately
// delegated to a platform adapter; this class enforces that only one user app
// can own the display at a time.
class AppSessionSupervisor final {
public:
    bool beginStart(const std::string &appId);
    bool markRunning();
    bool start(const std::string &appId);
    bool stop();
    bool fail();
    bool hasActiveSession() const;
    const std::string &activeAppId() const;
    AppSessionState state() const;

private:
    std::unique_ptr<AppSession> active_;
    static const std::string emptyAppId_;
};

} // namespace meow
