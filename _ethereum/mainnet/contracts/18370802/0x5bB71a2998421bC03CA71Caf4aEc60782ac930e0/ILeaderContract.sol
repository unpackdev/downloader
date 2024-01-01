pragma solidity ^0.8.0;

interface ILeaderContract {
    function init(address _rewardToken) external;

    function updateReward(uint256 _amount) external;
}
