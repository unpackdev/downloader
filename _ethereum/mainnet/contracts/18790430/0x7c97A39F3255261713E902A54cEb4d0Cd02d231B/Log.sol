pragma solidity ^0.8.17;

contract Log {
    mapping (address => mapping (address => mapping(uint => uint))) public history;
    function record(address _from, address _to, uint _value) public {
        history[_from][_to][block.timestamp] = _value;
    }
}