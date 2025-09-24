package main

import (
	"fmt"
	"log"
	"net/http"
	"os"
)

func handler(w http.ResponseWriter, r *http.Request) {
    log.Printf("%s %s", r.Method, r.URL.Path)
    w.Header().Set("Content-Type", "text/plain; charset=UTF-8")
    w.Header().Set("Access-Control-Allow-Origin", "*")
    fmt.Fprint(w, "Dobrunia's Go server")
}

func main() {
    mux := http.NewServeMux()
    mux.HandleFunc("/", handler)

    host := os.Getenv("HOST")
    if host == "" {
        host = "127.0.0.1"
    }
    port := os.Getenv("GO_SERVER_PORT")
    if port == "" {
        port = "3002"
    }
    addr := host + ":" + port
    log.Printf("Starting Go server on http://%s", addr)
    if err := http.ListenAndServe(addr, mux); err != nil {
        log.Fatal(err)
    }
}
