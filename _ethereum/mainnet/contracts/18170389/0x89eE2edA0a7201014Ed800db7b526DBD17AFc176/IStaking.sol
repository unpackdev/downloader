// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

interface IStaking {
    function refreshReward(address _account) external;
}
