local fiber = require('fiber')
local ffi=require'ffi'
local msgpack=require('msgpack')
local clock = require('clock')
ffi.cdef[[
    int shmget(size_t key, size_t size, int shmflg);
    void *shmat(int shmid, const void *shmaddr, int shmflg);
    void *memset(void *s, int c, size_t n);
]]

box.cfg{
    listen = "/home/amitichev/code/tarantool-test/test.socket",

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



local function getdata()
    local sm_id = ffi.C.shmget(1499, 1024, 932)
    local sm_data = ffi.cast("char*", ffi.C.shmat(sm_id, ffi.cast("void*", 0), 0))
    while true do
        local data = msgpack.decode(sm_data, 1024)
        if type(data) == "table" then
            box.space["test"]:insert{data.Val}
        end
        ffi.C.memset(sm_data, 0, 1024)
        fiber.yield()

    end
end


-- start = clock.monotonic()
-- for i = 1,1e5 do
--     box.space.test:insert{i}
-- end
-- print(clock.monotonic() - start)
-- box.space.test:truncate()

fiber.new(getdata)