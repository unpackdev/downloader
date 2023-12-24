// SPDX-License-Identifier: MIT
interface IStaking {
    function updateReward(uint256 _amount) external;

    function init(address _rewardToken, address _stakingToken) external;
}
