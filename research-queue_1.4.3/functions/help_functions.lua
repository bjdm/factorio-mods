function any(array, value_in_array) --checks if any item in an array is true
	local anyTrue = false
	for k, v in pairs(array) do
		if v[value_in_array] then anyTrue = true end
	end
	return anyTrue
end

function all(array, value_in_array) --checks if all items in an array are true
	local allTrue = true
	for k, v in pairs(array) do
		if not v[value_in_array] then allTrue = false end
	end
	return allTrue
end

function matches(array, value_in_array, match_this)		--check if any item in array1 matches any item in array2. 
	local matchFound = false
	for k1, v1 in pairs(array) do
		for k2, v2 in pairs(match_this) do
			if v1[value_in_array] == v2 then matchFound = true end
		end
	end
	return matchFound
end