// Copyright 2019-2025 The Inspektor Gadget authors
//
// Licensed under the Apache License, Version 2.0 (the "License");
// you may not use this file except in compliance with the License.
// You may obtain a copy of the License at
//
//     http://www.apache.org/licenses/LICENSE-2.0
//
// Unless required by applicable law or agreed to in writing, software
// distributed under the License is distributed on an "AS IS" BASIS,
// WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
// See the License for the specific language governing permissions and
// limitations under the License.

package main

import (
	"flag"
	"fmt"
	"os"
	"os/signal"
	"syscall"

	containerhook "github.com/alban/alterseccomp/pkg/container-hook"
	"github.com/inspektor-gadget/inspektor-gadget/pkg/utils/host"
)

func callback(notif containerhook.ContainerEvent) {
}

func main() {
	host.Init(host.Config{})

	flag.Parse()
	var err error

	if !containerhook.Supported() {
		fmt.Printf("containerhook not supported\n")
		os.Exit(1)
	}

	notifier, err := containerhook.NewContainerNotifier(callback)
	if err != nil {
		fmt.Printf("containerhook failed: %v\n", err)
		os.Exit(1)
	}
	defer notifier.Close()

	// Graceful shutdown
	exit := make(chan os.Signal, 1)
	signal.Notify(exit, syscall.SIGINT, syscall.SIGTERM)
	<-exit
}
