package main

import (
	"fmt"
	"log"
	"net/http"
	"os"
	"time"
)

// Set at build time: -ldflags "-X main.version=<git sha>".
var version = "dev"

func main() {
	mux := http.NewServeMux()

	mux.HandleFunc("/healthz", func(w http.ResponseWriter, r *http.Request) {
		fmt.Fprintln(w, "ok")
	})

	mux.HandleFunc("/", func(w http.ResponseWriter, r *http.Request) {
		host, _ := os.Hostname()
		fmt.Fprintf(w, "Hello from eks-gitops-platform! version=%s pod=%s\n", version, host)
	})

	srv := &http.Server{
		Addr:              ":8080",
		Handler:           mux,
		ReadHeaderTimeout: 5 * time.Second,
	}

	log.Printf("listening on %s (version %s)", srv.Addr, version)
	log.Fatal(srv.ListenAndServe())
}
