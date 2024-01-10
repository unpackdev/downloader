// SPDX-License-Identifier: MIT

pragma solidity 0.8.13;

contract BlockTime {
    function getTime() external view returns (uint256) {
        return block.timestamp;
    }
}