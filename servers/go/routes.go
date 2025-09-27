package main

import "net/http"

// registerRoutes centralizes HTTP route wiring.
func registerRoutes(mux *http.ServeMux) {
    mux.Handle("/go/ssh/connect", withLogging("ssh_connect", withCORS(http.HandlerFunc(sshConnectHandler))))
    mux.Handle("/go/ssh/disconnect", withLogging("ssh_disconnect", withCORS(http.HandlerFunc(sshDisconnectHandler))))
    mux.Handle("/go/ssh/execute", withLogging("ssh_execute", withCORS(http.HandlerFunc(sshExecuteHandler))))
    mux.Handle("/go/data/processes", withLogging("processes", withCORS(http.HandlerFunc(processesHandler))))
    mux.Handle("/go/data/ports", withLogging("ports", withCORS(http.HandlerFunc(portsHandler))))
    mux.Handle("/go/data/connections", withLogging("connections", withCORS(http.HandlerFunc(connectionsHandler))))
    mux.Handle("/go/data/client-ips", withLogging("client_ips", withCORS(http.HandlerFunc(clientIpsHandler))))
    mux.Handle("/go/data/process-logs", withLogging("process_logs", withCORS(http.HandlerFunc(processLogsHandler))))
    mux.Handle("/go/data/resources", withLogging("resources", withCORS(http.HandlerFunc(resourcesHandler))))
    mux.Handle("/go/data/network", withLogging("network", withCORS(http.HandlerFunc(networkHandler))))
    mux.Handle("/go/process/action", withLogging("process_action", withCORS(http.HandlerFunc(processActionHandler))))
    mux.Handle("/go/data/services", withLogging("services", withCORS(http.HandlerFunc(servicesHandler))))
    mux.Handle("/go/data/disk-usage", withLogging("disk_usage", withCORS(http.HandlerFunc(diskUsageHandler))))
    mux.Handle("/go/data/users", withLogging("users", withCORS(http.HandlerFunc(usersHandler))))
    mux.Handle("/go/data/system-info", withLogging("system_info", withCORS(http.HandlerFunc(systemInfoHandler))))
    mux.Handle("/go/ssh/status", withLogging("ssh_status", withCORS(http.HandlerFunc(sshStatusHandler))))
    mux.Handle("/health", withLogging("health", withCORS(http.HandlerFunc(healthHandler))))

    // network endpoints
    mux.Handle("/go/network/devices", withLogging("network_devices", withCORS(http.HandlerFunc(networkDevicesHandler))))
    mux.Handle("/go/network/packets", withLogging("network_packets", withCORS(http.HandlerFunc(networkPacketsHandler))))
}


