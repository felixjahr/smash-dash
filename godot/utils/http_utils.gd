extends Node
class_name HttpUtils


static func request(parent: Node, url: String, method: int, body: Variant = null, headers: Array[String] = []) -> Variant:
	var http := HTTPRequest.new()
	parent.add_child(http)

	var request_body := ""
	if body != null:
		request_body = JSON.stringify(body)

	var final_headers := ["Content-Type: application/json"]
	final_headers.append_array(headers)

	var err := http.request(url, final_headers, method, request_body)

	if err != OK:
		http.queue_free()
		push_error("Request failed to start")
		return null

	var result = await http.request_completed
	http.queue_free()

	var response_code = result[1]
	var response_body: PackedByteArray = result[3]
	var text := response_body.get_string_from_utf8()

	if response_code < 200 or response_code >= 300:
		push_error("HTTP error: %s" % response_code)
		return null
	
	if text.strip_edges().is_empty():
		return null
	return JSON.parse_string(text)
