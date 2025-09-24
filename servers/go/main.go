package main

import (
	"fmt"
	"log"
	"net/http"
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

    addr := "127.0.0.1:3002"
    log.Printf("Starting Go server on http://%s", addr)
    if err := http.ListenAndServe(addr, mux); err != nil {
        log.Fatal(err)
    }
}
