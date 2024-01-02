// SPDX-License-Identifier: MIT
pragma solidity 0.8.23;

contract Revert {
    receive() external payable {
        require(false);
    }

    fallback() external payable {
        require(false);
    }
}