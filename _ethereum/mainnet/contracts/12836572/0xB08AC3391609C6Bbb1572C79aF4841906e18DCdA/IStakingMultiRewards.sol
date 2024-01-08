// SPDX-License-Identifier: MIT
pragma solidity >=0.4.24;

// https://docs.synthetix.io/contracts/source/interfaces/istakingrewards
interface IStakingMultiRewards {

    function totalSupply() external view returns(uint256);
    function lastTimeRewardApplicable(address targetYield) external view returns (uint256) ;
    function rewardPerToken(address targetYield) external view returns (uint256);
    function earned(address targetYield, address account) external view returns(uint256);

    function setRewardDistribution(address[] calldata _rewardDistributions, bool _flag) external;
    function notifyTargetRewardAmount(address targetYield, uint256 reward) external;
    function updateAllRewards(address targetAccount) external;
    function updateReward(address targetYield, address targetAccount) external;
    function getAllRewards() external;
    function getAllRewardsFor(address user) external;
    function getReward(address targetYield) external;
    function getRewardFor(address user, address targetYield) external;
    function addReward(address targetYield, uint256 duration, bool isSelfCompoundingYield) external;
    function removeReward(address targetYield) external;
}
