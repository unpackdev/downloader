pragma solidity ^0.6.0;


contract ActionLogger {
    event Log(string indexed _type, address indexed owner, uint256 _first, uint256 _second);

    function logEvent(string memory _type, address _owner, uint256 _first, uint256 _second) public {
        emit Log(_type, _owner, _first, _second);
    }
}
