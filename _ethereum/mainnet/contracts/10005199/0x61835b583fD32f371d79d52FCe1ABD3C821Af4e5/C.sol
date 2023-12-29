/**
 *Submitted for verification at Etherscan.io on 2020-05-05
*/

pragma solidity >0.6.4 <0.7.0;

contract C {
    uint256 immutable decimals;
    address public immutable owner;

    constructor(uint8 _decimals) public {
        decimals = _decimals;
        owner = msg.sender;
    }
    
    function returnStuff() public returns (uint256) {
        uint256 tmp = 25;
        return tmp * decimals;
    }
}