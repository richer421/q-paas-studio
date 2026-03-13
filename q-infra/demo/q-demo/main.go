package main

import (
	"encoding/json"
	"log"
	"net/http"
	"os"
)

func main() {
	mux := http.NewServeMux()
	mux.HandleFunc("/healthz", func(w http.ResponseWriter, r *http.Request) {
		w.WriteHeader(http.StatusOK)
		_, _ = w.Write([]byte("ok"))
	})
	mux.HandleFunc("/", func(w http.ResponseWriter, r *http.Request) {
		_ = json.NewEncoder(w).Encode(map[string]string{
			"service": "q-demo",
			"version": os.Getenv("APP_VERSION"),
		})
	})

	addr := ":8080"
	log.Printf("q-demo listening on %s", addr)
	log.Fatal(http.ListenAndServe(addr, mux))
}
