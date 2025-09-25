package main

import (
	"log"
	"net/http"
)

func main() {
    mux := http.NewServeMux()
    registerRoutes(mux)

    addr := "127.0.0.1:3002"
    log.Printf("Starting Go server on http://%s", addr)
    if err := http.ListenAndServe(addr, mux); err != nil {
        log.Fatal(err)
    }
}
