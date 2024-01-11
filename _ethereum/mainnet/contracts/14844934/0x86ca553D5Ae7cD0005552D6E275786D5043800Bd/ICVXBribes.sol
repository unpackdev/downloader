// SPDX-License-Identifier: MIT
pragma solidity 0.6.12;

interface ICVXBribes {
    function getReward(address _account, address _token) external;
    function getRewards(address _account, address[] calldata _tokens) external;
}