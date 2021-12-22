local fiber = require('fiber')
local ffi=require'ffi'
local msgpack=require('msgpack')
local clock = require('clock')
local log = require('log')
ffi.cdef[[
    int shmget(size_t key, size_t size, int shmflg);
    void *shmat(int shmid, const void *shmaddr, int shmflg);
    void *memset(void *s, int c, size_t n);
]]

box.cfg{
    --listen = "/home/amitichev/code/tarantool-test/test.socket",
}

box.schema.create_space('test', {if_not_exists=true})
box.space.test:create_index('pk', {if_not_exists=true})
box.space.test:truncate()

box.schema.create_space('config', {if_not_exists=true})
box.space.config:create_index('pk', {if_not_exists=true})
box.space.config:truncate()

box.schema.user.create('user', {password='password', if_not_exists=true})
box.schema.user.grant('user', 'write,read', 'space', 'test' , {if_not_exists=true})
box.schema.user.grant('user', 'write,read', 'space', 'config' , {if_not_exists=true})

box.space["test"]:truncate()
box.snapshot()

local function getdata()
    jit.off(true)
    local sm_id = ffi.C.shmget(1599, 1024, 932)
    local sm_data = ffi.cast("char*", ffi.C.shmat(sm_id, ffi.cast("void*", 0), 0))
    sm_data[0] = 0
    while true do
        while sm_data[0] == 0 do
            fiber.yield()
        end
        assert(sm_data[0] == 1, tostring(sm_data[0]))
        assert(sm_data[0] == 1, tostring(sm_data[0]))
        
        local data, err = msgpack.decode(sm_data+1, 1023)
        assert(sm_data[0] == 1, tostring(sm_data[0]))
        assert(sm_data[0] == 1, tostring(sm_data[0]))
        if data == box.NULL then
            print('data ', 'nil')
            break
        end
        if type(data) == "table" then
            box.space["test"]:insert{data.Val}
            sm_data[0] = 0
        end
    end
    print('---', box.space["test"]:len(), i)
end


local function senddata()
    local sm_id = ffi.C.shmget(2021, 1024, 932)
    local sm_data = ffi.cast("char*", ffi.C.shmat(sm_id, ffi.cast("void*", 0), 0))
    
    for _, tuple in box.space["test"]:pairs() do
        while sm_data[0] ~= 0 do 
            fiber.yield()
        end
        local data = msgpack.encode({['Val']=tuple[1]})
        ffi.copy(sm_data+1, data) 
        sm_data[0] = 1
    end

    print('all done')

    while sm_data[0] == 1 do 
        fiber.sleep(0.01)
    end
    local data = msgpack.encode(box.NULL)
    
    ffi.copy(sm_data+1, data) 
    sm_data[0] = 2
end

-- start = clock.monotonic()
-- for i = 1,1e5 do
--     box.space.test:insert{i}
-- end
-- print(clock.monotonic() - start)
-- box.space.test:truncate()

print(box.space["test"]:len())
getdata()
print('GetData end')
senddata()
print('SendData end')