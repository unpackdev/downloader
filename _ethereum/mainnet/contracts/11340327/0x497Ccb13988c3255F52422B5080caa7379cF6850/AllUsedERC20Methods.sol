// SPDX-License-Identifier: ISC

pragma solidity ^0.7.5;

contract AllUsedERC20Methods {
    function name() public pure returns (string memory) {
        return 'AllUsedERC20Methods';
    }

    function symbol() public pure returns (string memory) {
        return 'ALLERC20';
    }

    function decimals() public pure returns (uint8) {
        return 18;
    }

    function totalSupply() public pure returns (uint256) {
        return 10**9;
    }
}
