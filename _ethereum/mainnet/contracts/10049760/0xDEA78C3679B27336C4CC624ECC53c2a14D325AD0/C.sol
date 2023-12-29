pragma solidity >0.6.4 <0.7.0;

contract C {
    uint8 immutable decimals;
    address public immutable owner;

    constructor(uint8 _decimals) public {
        decimals = _decimals;
        owner = msg.sender;
    }
    
    function herpderp24() public view returns (uint256) {
        uint256 tmp = 25;
        return tmp * decimals;
    }
}