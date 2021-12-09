package main

import (
	"fmt"
	"time"

	"github.com/vmihailenco/msgpack/v5"
	"golang.org/x/sys/unix"
)

func main() {

	// opts := tarantool.Opts{User: "user", Pass: "password"}
	// conn, err := tarantool.Connect("/home/amitichev/code/tarantool-test/test.socket", opts)
	// if err != nil {
	// 	fmt.Println("Connection refused:", err)
	// }
	// start := time.Now()
	// for i := 0; i != 1e5; i++ {
	// 	conn.Insert("test", []interface{}{uint(i)})
	// }
	// fmt.Println(time.Since(start))

	id, err := unix.SysvShmGet(1499, 1024, unix.IPC_CREAT|0o644)
	if err != nil {
		fmt.Println("Confusion with shmem", err)
	}
	b, err := unix.SysvShmAttach(id, 0, 0)
	if err != nil {
		fmt.Println("Confusion with shmat", err)
	}
	type RequestStruct struct {
		Val uint
	}
	start := time.Now()
	for i := 0; i != 1e5; i++ {
		for {
			if b[0] == 0 {
				data, _ := msgpack.Marshal(&RequestStruct{Val: uint(1e5 + 1 + i)})
				copy(b, data)
				break
			}

		}
	}
	fmt.Println(time.Since(start))

	fmt.Println(id)

}
