extends "res://addons/gut/test.gd"


func test_netplayer_create() -> void:
	var net_player = Netcode.NetPlayer.new()
	var initial_size = net_player.messages.size()

	assert_not_null(net_player)
	assert_true(net_player.messages.size() == initial_size)

	for i in range(initial_size):
		assert_eq(net_player.get_input(i), Globals.GameInput.NONE)


func test_netplayer_input_for_frame() -> void:
	var inputs := [Globals.GameInput.NONE, Globals.GameInput.UP, Globals.GameInput.DOWN, Globals.GameInput.CHARGE]
	var net_player = Netcode.NetPlayer.new()
	var initial_size = net_player.messages.size()

	for i in range(100):
		var input = inputs[randi() % inputs.size()]
		net_player.set_input(input, i)
		assert_eq(net_player.get_input(i), input)

	assert_true(net_player.messages.size() == initial_size)


func test_netplayer_delayed_input_for_frame() -> void:
	var inputs := [Globals.GameInput.NONE, Globals.GameInput.UP, Globals.GameInput.DOWN, Globals.GameInput.CHARGE]

	var test_inputs := []
	for _i in range(100):
		test_inputs.append(inputs[randi() % inputs.size()])

	var input_delay = 36
	var net_player = Netcode.NetPlayer.new(input_delay)
	var initial_size = net_player.messages.size()

	for i in range(input_delay):
		net_player.set_input(test_inputs[i], i)

	for i in range(input_delay, 100):
		net_player.set_input(test_inputs[i], i)
		assert_eq(net_player.get_input(i), test_inputs[i - input_delay])

	for i in range(100, 100 + input_delay):
		assert_eq(net_player.get_input(i), test_inputs[i - input_delay])

	assert_true(net_player.messages.size() == initial_size)


func test_netplayer_input_delay_exceeded_without_delay() -> void:
	var net_player = Netcode.NetPlayer.new()
	assert_true(net_player.has_input_delay_exceeded(0))

	var inputs_received = 0
	net_player.set_input(Globals.GameInput.NONE, inputs_received)
	assert_false(net_player.has_input_delay_exceeded(inputs_received))
	assert_true(net_player.has_input_delay_exceeded(inputs_received + 1))

	inputs_received = 6
	for i in range(inputs_received + 1):
		net_player.set_input(Globals.GameInput.NONE, i)

	assert_false(net_player.has_input_delay_exceeded(inputs_received))
	assert_true(net_player.has_input_delay_exceeded(inputs_received + 1))


func test_netplayer_input_delay_exceeded_with_delay() -> void:
	var input_delay = 10
	var net_player = Netcode.NetPlayer.new(input_delay)

	for i in range(input_delay):
		assert_false(net_player.has_input_delay_exceeded(i))
	assert_true(net_player.has_input_delay_exceeded(input_delay))

	var inputs_received = 6
	for i in range(inputs_received):
		net_player.set_input(Globals.GameInput.NONE, i)

	for i in range(input_delay + inputs_received):
		assert_false(net_player.has_input_delay_exceeded(i))
	assert_true(net_player.has_input_delay_exceeded(input_delay + inputs_received))


func test_netplayer_input_delay_exceeded_with_unordered_inputs() -> void:
	var input_delay = 10
	var net_player = Netcode.NetPlayer.new(input_delay)

	for i in range(input_delay):
		assert_false(net_player.has_input_delay_exceeded(i))
	assert_true(net_player.has_input_delay_exceeded(input_delay))

	var inputs_received = 6
	for i in range(inputs_received - 1, -1, -1):
		net_player.set_input(Globals.GameInput.NONE, i)

	for i in range(input_delay + inputs_received - 1, -1, -1):
		assert_false(net_player.has_input_delay_exceeded(i))
	assert_true(net_player.has_input_delay_exceeded(input_delay + inputs_received))

