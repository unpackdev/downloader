// SPDX-License-Identifier: MIT
pragma solidity >=0.4.24;

// https://docs.synthetix.io/contracts/source/interfaces/istakingrewards
interface IStakingRewards {
    // Views

    function balanceOf(address account) external view returns (uint256);

    function earned(address account) external view returns (uint256);

    function getRewardForDuration() external view returns (uint256);

    function lastTimeRewardApplicable() external view returns (uint256);

    function rewardPerToken() external view returns (uint256);

    function totalStaked() external view returns (uint256);

    // Mutative

    function exit() external;

    function stake(
        uint256 amount,
        bytes32 root_,
        bytes32[] calldata proof_
    ) external;

    function withdraw(uint256 amount) external;
}
