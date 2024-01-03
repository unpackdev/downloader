// SPDX-License-Identifier: ISC

pragma solidity ^0.7.5;

contract UniToken {
    address public token0;
    address public token1;

    constructor(address _token0, address _token1) {
        token0 = _token0;
        token1 = _token1;
    }


    function symbol() public pure returns (string memory) {
        return "UNI-V2";
    }
}
