package main

import (
	"fmt"
	"os/user"
	"time"
)

func main() {
	// Get current time
	currentTime := time.Now()
	hour := currentTime.Hour()

	// Determine greeting based on time of day
	var greeting string
	switch {
	case hour < 12:
		greeting = "Good morning"
	case hour < 17:
		greeting = "Good afternoon"
	default:
		greeting = "Good evening"
	}

	// Get username
	currentUser, err := user.Current()
	if err != nil {
		fmt.Println("Hello there, couldn't determine your username!")
		return
	}

	// Print greeting with username
	fmt.Printf("%s, %s!\n", greeting, currentUser.Username)
}
