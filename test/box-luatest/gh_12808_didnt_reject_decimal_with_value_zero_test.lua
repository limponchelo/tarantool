local t = require('luatest')
local g = t.group()
local server = require('luatest.server')

g.before_all(function(cg)
    cg.server = server:new{alias = 'master'}
    cg.server:start()
end)

g.after_all(function(cg)
    cg.server:drop()
end)

g.before_each(function(cg)
    cg.server:exec(function()
        box.schema.space.create('test', {
            format = {
                {name = 'a', type = 'unsigned'},
                {name = 'b', type = 'decimal32', scale = 9},
            },
        })
        box.space.test:create_index('pk')
    end)
end)

g.after_each(function(cg)
    cg.server:exec(function()
        box.space.test:drop()
    end)
end)

g.test_decimal_zero_fits_fixed_point = function(cg)
    cg.server:exec(function()
        local decimal = require('decimal')
        local t = require('luatest')

        t.assert(pcall(function()
            box.space.test:replace{1, decimal.new('0.123456789')}
        end), 'non-zero value within range fits')

        t.assert(pcall(function()
            box.space.test:replace{1, decimal.new('0')}
        end), "decimal.new('0') fits")

        t.assert(pcall(function()
            box.space.test:replace{1, decimal.new(0)}
        end), 'decimal.new(0) fits')

        t.assert(pcall(function()
            box.space.test:replace{1, decimal.new('0.000000000')}
        end), "decimal.new('0.000000000') fits")

        t.assert(pcall(function()
            box.space.test:replace{1, decimal.new('0.000000001')}
        end), 'smallest non-zero value fits')

        local ok = pcall(function()
            box.space.test:replace{1, decimal.new('1.000000000')}
        end)
        t.assert_not(ok, 'out-of-range value is still rejected')

        local ok2 = pcall(function()
            box.space.test:replace{1, decimal.new('-1.000000000')}
        end)
        t.assert_not(ok2, 'negative out-of-range value is still rejected')
    end)
end