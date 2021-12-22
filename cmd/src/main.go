package main

import (
	"fmt"
	"time"

	"github.com/vmihailenco/msgpack/v5"
	"golang.org/x/sys/unix"
)

type RequestStruct struct {
	Val int
}

func readFromTarantool() {
	id, err := unix.SysvShmGet(2021, 1024, unix.IPC_CREAT|0o644)
	if err != nil {
		fmt.Println("Confusion with shmem", err)
	}
	b, err := unix.SysvShmAttach(id, 0, 0)
	if err != nil {
		fmt.Println("Confusion with shmat", err)
	}
	b[0] = 0
	start := time.Now()
	for {
		for b[0] == 0 {
			//time.Sleep(time.Microsecond)
		}
		if b[0] == 2 {
			fmt.Println("END ")
			break
		}
		var data RequestStruct
		if err := msgpack.Unmarshal(b[1:], &data); err != nil {
			fmt.Println("Error", err)
			break
		}

		b[0] = 0
	}
	fmt.Println(time.Since(start))
}

func writeToTarantool() {
	id, err := unix.SysvShmGet(1599, 1024, unix.IPC_CREAT|0o644)
	if err != nil {
		fmt.Println("Confusion with shmem", err)
	}
	b, err := unix.SysvShmAttach(id, 0, 0)
	if err != nil {
		fmt.Println("Confusion with shmat", err)
	}
	start := time.Now()
	size := int(1e5)
	var data []byte
	var prevint int
	for i := 0; i != size; i++ {
		var k = 0
		for b[0] != 0 {
			//time.Sleep(time.Microsecond)
			k = k + 1
			if k == 10000 {

				var tmp RequestStruct
				msgpack.Unmarshal(data, &tmp)
				fmt.Println(tmp, prevint)
			}
		}

		prevint = i
		data, _ = msgpack.Marshal(&RequestStruct{Val: i})
		copy(b[1:], data)
		// wait for data written right
		b[0] = 1 // set 1, tnt set 0
	}
	fmt.Println(time.Since(start), size/int(time.Since(start).Milliseconds()))

	data, err = msgpack.Marshal(nil)
	if err != nil {
		fmt.Errorf("marshal nil error %v", err)
	}
	for b[0] != 0 {
		time.Sleep(time.Microsecond)
	}
	copy(b[1:], data)
	b[0] = 1

	fmt.Println(id)
}

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

	writeToTarantool()
	readFromTarantool()
}
