local HttpService = game:GetService("HttpService")

local Promise = require(script.Parent.Promise)

local HttpError = require(script.Error)
local HttpResponse = require(script.Response)

local lastRequestId = 0

local Http = {}

Http.Error = HttpError
Http.Response = HttpResponse

local function performRequest(requestParams)
	local requestId = lastRequestId + 1
	lastRequestId = requestId

	return Promise.new(function(resolve, reject)
		coroutine.wrap(function()
			local success, response = pcall(function()
				return HttpService:RequestAsync(requestParams)
			end)

			if success then
				resolve(HttpResponse.fromRobloxResponse(response))
			else
				reject(HttpError.fromRobloxErrorString(response))
			end
		end)()
	end)
end

function Http.get(url)
	return performRequest({
		Url = url,
		Method = "GET",
	})
end

function Http.post(url, body)
	return performRequest({
		Url = url,
		Method = "POST",
		Body = body,
	})
end

function Http.jsonEncode(object)
	return HttpService:JSONEncode(object)
end

function Http.jsonDecode(source)
	return HttpService:JSONDecode(source)
end

return Http
