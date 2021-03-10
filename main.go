package main

import (
	"context"
	"fmt"
	"html/template"
	"io/ioutil"
	"log"
	"math/rand"
	"net/http"
	"os"
	"os/signal"
	"strings"
	"time"
)

var templates = template.Must(template.ParseFiles(
	"./templates/main.css",
	"./templates/index.html",
))

var images []string

func main() {
	rand.Seed(time.Now().Unix())
	getImages()
	mux := http.NewServeMux()
	mux.HandleFunc("/", indexHandler)
	mux.HandleFunc("/css", cssHandler)
	mux.Handle("/images/", checkWebP(http.FileServer(http.Dir("./"))))

	log.Print("Starting server.")
	server := http.Server{
		Addr:              ":8080",
		Handler:           requestLogger(mux),
	}
	go func(){
		_ = server.ListenAndServe()
	}()
	stop := make(chan os.Signal, 1)
	signal.Notify(stop, os.Interrupt, os.Kill)
	<-stop
	ctx, cancel := context.WithTimeout(context.Background(), 5*time.Second)
	defer cancel()
	if err := server.Shutdown(ctx); err != nil {
		log.Fatalf("Unable to shutdown: %s", err.Error())
	}
	log.Print("Finishing server.")
}

func requestLogger(targetMux http.Handler) http.Handler {
	return http.HandlerFunc(func(w http.ResponseWriter, r *http.Request) {
		targetMux.ServeHTTP(w, r)
		requesterIP := r.RemoteAddr
		log.Printf(
			"%s\t\t%s\t\t%s\t",
			requesterIP,
			r.Method,
			r.RequestURI,
		)
	})
}

func checkWebP(fn http.Handler) http.Handler {
	return http.HandlerFunc(func(rw http.ResponseWriter, req *http.Request) {
		if webp := strings.Contains(req.Header.Get("Accept"),"image/webp"); webp {
			webp := req.URL.Path + ".webp"
			_, err := os.Stat(fmt.Sprintf("./%s", webp))
			if err == nil {
				req.URL.Path = webp
			}
		}
		fn.ServeHTTP(rw, req)
	})
}

func getImages() {
	files, err := ioutil.ReadDir("./images")
	if err != nil {
		log.Fatal(err)
	}
	for _, f := range files {
		images = append(images, f.Name())
	}
}

func cssHandler(writer http.ResponseWriter, _ *http.Request) {
	writer.Header().Set("Content-Type", "text/css; charset=utf-8")
	err := templates.ExecuteTemplate(writer, "main.css", images[rand.Intn(len(images))])
	if err != nil {
		log.Printf("Fucked up: %s", err.Error())
		writer.WriteHeader(http.StatusInternalServerError)
		return
	}
}

func indexHandler(writer http.ResponseWriter, request *http.Request) {
	if request.URL.Path == "/" {
		err := templates.ExecuteTemplate(writer, "index.html", "")
		if err != nil {
			log.Printf("Fucked up: %s", err.Error())
			writer.WriteHeader(http.StatusInternalServerError)
			return
		}
	} else {
		writer.WriteHeader(http.StatusNotFound)
	}
}



