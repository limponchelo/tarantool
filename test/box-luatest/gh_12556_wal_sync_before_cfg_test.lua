local t = require('luatest')
local g = t.group()

g.test_wal_sync_before_cfg = function()
    t.assert_error_msg_equals('Please call box.cfg{} first',
                               box.ctl.wal_sync)
end
