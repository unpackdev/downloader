pragma solidity ^0.5.0;


contract ViewCallGasLimit {
    function check(uint _a) public view returns(uint256) {
        return gasleft();
    }
}