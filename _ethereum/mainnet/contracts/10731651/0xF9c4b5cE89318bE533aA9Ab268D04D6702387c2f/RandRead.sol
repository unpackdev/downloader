pragma solidity ^0.6.0;

contract RandRead {
    constructor() public {
        
    }
    
    function readFrom(uint128 x, uint128 y) public returns(uint256) {
        uint256 s = 0;
        for (uint128 i = x; i < y; i++) {
            s = s + address(i).balance;
        }
        return s;
    }
}