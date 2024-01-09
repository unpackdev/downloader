// SPDX-License-Identifier: UNLICENSED
pragma solidity >=0.7.0 <0.9.0;

contract Timestamp {
    function getTimestamp() external view returns (uint256) {
        return block.timestamp;
    }
    function getBlock() external view returns (uint256) {
        return block.number;
    }
}