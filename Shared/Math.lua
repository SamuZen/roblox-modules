local Math = {}

local SUFFIXES = { "", "K", "M", "B", "T", "Qa", "Qi" }

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

Math.FormatCompact = function(n)
	if n < 1000 then
		return tostring(n)
	end
	local i = math.floor(math.log(n, 1000))
	local short = math.floor(n / (1000 ^ i) * 10) / 10
	local fmt = if short % 1 == 0 then "%d%s" else "%.1f%s"
	return string.format(fmt, short, SUFFIXES[i + 1])
end

return Math