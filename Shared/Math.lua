local Math = {}

Math.Lerp = function(min, max, p)
    return min + ((max-min) * p)
end

Math.Variate = function(v, p)
    local variation = math.random() * (2 * p) - p  -- Gera um número entre -p e +p
    return v * (1 + variation)
end

Math.FloorDecimal = function(v, num)
    local r = 10 ^ num
    return math.floor(v * r) / r
end

return Math