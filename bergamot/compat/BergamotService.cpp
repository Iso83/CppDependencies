#include "translator/service.h"

namespace marian::bergamot {

Logger::Logger(const Config& config)
    : marianLoggers_(createLoggers())
{
    for (auto& logger : marianLoggers_)
        setLoggingLevel(*logger, config.level);
}

Logger::~Logger()
{
    for (auto& logger : marianLoggers_)
        if (logger)
            spdlog::drop(logger->name());
}

BlockingService::~BlockingService() = default;

} // namespace marian::bergamot
