pragma solidity ^0.4.23;

contract Gas {
    function gas() public view returns (uint256) {
        return gasleft();
    }
}