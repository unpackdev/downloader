pragma solidity ^0.5.5;


contract Time {
    function getTime() public view returns (uint256) {
        uint256 t = block.timestamp;
        return t;
    }
}