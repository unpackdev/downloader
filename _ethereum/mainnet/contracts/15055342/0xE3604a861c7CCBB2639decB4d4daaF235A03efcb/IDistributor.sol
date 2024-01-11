// SPDX-License-Identifier: MIT
pragma solidity 0.8.9;


interface IDistributor {
    function rewardToken() external view returns (address);
    function reserves() external view returns (uint);

    function stake(uint amount) external;
    function unstake(uint amount) external;
    function claim() external;
    function exit() external;

    function notifyRewardDistributed(uint rewardAmount) external;
    function stakeBehalf(address account, uint amount) external;
}
