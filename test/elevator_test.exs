defmodule ElevatorTest do
  use ExUnit.Case
  doctest Elevator.Elevator

  setup do
    context = %ElevatorContext{lowest_floor: -2, highest_floor: 8}
    initial_state = %Elevator{ current: 0, action: :idle, status: :ok, queue: [], context: context }
    
    pid = spawn fn () -> Elevator.Elevator.start_elevator(initial_state) end

    { :ok, initial_state: initial_state, pid: pid }
  end

  @tag timeout: 30
  test "starts an elevator", %{ initial_state: initial_state, pid: pid } do
    
    state = get_info pid

    assert state == initial_state
    
    dismount_elevator pid
  end

  test "the elevator moves on every clock tick", %{ initial_state: initial_state, pid: pid } do

    request_floors pid, [2]

    # 3.5s would give us enough time for the elevator to move
    :timer.sleep(2500)

    state = get_info pid

    assert state != initial_state
    assert state.action != initial_state.action
    assert state.current > initial_state.current

    dismount_elevator pid
  end

  test "valid floors get added to the queue upon request", %{ initial_state: initial_state, pid: pid } do

    request_floors pid, [2, 5, -1, 2, 10, 8]

    expected_queue = [2, 5, -1, 8]

    state = get_info pid

    assert state.queue == expected_queue

    dismount_elevator pid
  end

  defp request_floors(pid, floors) do
    for floor <- floors do
      send pid, { :request, floor }
    end
  end

  defp get_info(pid) do
    send pid, { :get_info, self() }

    receive do
      { :returned_info, state } -> state
    end
  end

  defp dismount_elevator(pid) do
    send pid, { :dismount }
  end
end
