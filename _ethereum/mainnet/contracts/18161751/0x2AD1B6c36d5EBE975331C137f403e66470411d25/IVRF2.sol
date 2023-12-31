// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface IVRF2 {
    function requestRandomWords() external returns (uint256 requestId);
}
