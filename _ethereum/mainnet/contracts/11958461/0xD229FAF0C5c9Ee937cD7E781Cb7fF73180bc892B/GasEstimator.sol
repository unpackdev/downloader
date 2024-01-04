// SPDX-License-Identifier: MIT

pragma solidity ^0.7.6;


contract GasEstimator {
    function gaslimit() external view returns (uint256) {
        return gasleft();
    }
}