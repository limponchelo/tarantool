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

g.test_decimal_zero_fits_fixed_point = function(cg)
    for i = 1, 3 do
        local decimal_type
        if i == 1 then
            decimal_type = 'decimal32'
        elseif i == 2 then
            decimal_type = 'decimal64'
        elseif i == 3 then
            decimal_type = 'decimal128'
        end

        local scale
        if decimal_type == 'decimal32' then
            scale = 9
        elseif decimal_type == 'decimal64' then
            scale = 18
        elseif decimal_type == 'decimal128' then
            scale = 38
        end

        cg.server:exec(function(decimal_type, scale)
            local decimal = require('decimal')
            local t = require('luatest')

            box.schema.space.create('test', {
                format = {
                    {name = 'a', type = 'unsigned'},
                    {name = 'b', type = decimal_type, scale = scale},
                },
            })
            box.space.test:create_index('pk')

            t.assert(pcall(function()
                box.space.test:replace{1, decimal.new('0')}
            end), decimal_type .. ": decimal.new('0') fits")

            t.assert(pcall(function()
                box.space.test:replace{1, decimal.new(0)}
            end), decimal_type .. ': decimal.new(0) fits')

            t.assert(pcall(function()
                box.space.test:replace{1, decimal.new('0.' .. string.rep('0', scale))}
            end), decimal_type .. ': zero with scale zero digits fits')

            t.assert(pcall(function()
                box.space.test:replace{1, decimal.new('-0.' .. string.rep('0', scale))}
            end), decimal_type .. ': negative zero with scale zero digits fits')

            t.assert(pcall(function()
                box.space.test:replace{1, decimal.new('0.' .. string.rep('0', 1000))}
            end), decimal_type .. ': zero with 1000 zero digits still fits')

            box.space.test:drop()
        end, {decimal_type, scale})
    end
end