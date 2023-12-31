// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface IFraudVRF {
    function requestRandomWords(uint256 vault, uint256 reward, address user) external;
}