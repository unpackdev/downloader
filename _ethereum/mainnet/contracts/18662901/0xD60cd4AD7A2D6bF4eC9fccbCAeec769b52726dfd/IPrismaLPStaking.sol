// SPDX-License-Identifier: MIT
pragma solidity 0.8.19;

interface IPrismaLPStaking {
    function deposit(address receiver, uint256 amount) external returns (bool);
    function withdraw(address receiver, uint256 amount) external returns (bool);
    function claimReward(
        address receiver
    ) external returns (uint256 prismaAmount, uint256 crvAmount, uint256 cvxAmount);
    function claimableReward(
        address account
    ) external view returns (uint256 prismaAmount, uint256 crvAmount, uint256 cvxAmount);
    function fetchRewards() external;
}