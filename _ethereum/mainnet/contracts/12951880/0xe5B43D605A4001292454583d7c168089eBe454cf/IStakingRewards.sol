//SPDX-License-Identifier: MIT

pragma solidity ^0.8.3;

import "./SafeERC20.sol";

struct RewardSettings {
    IERC20 rewardToken;
    uint256 totalRewards;
}

struct PendingRewards {
    IERC20 rewardToken;
    uint256 pendingReward;
}

struct EarnedRewards {
    IERC20 rewardToken;
    uint256 earnedReward;
}

interface IStakingRewards {
    event Deposit(address indexed user, uint256 amount);
    event Withdraw(address indexed user, uint256 amount);
    event EmergencyWithdraw(address indexed user, uint256 amount);
    event Recovered(address token, uint256 amount);
    event UnclaimedRecovered(address token, uint256 amount);
    event RewardsExtended(uint256 newEndBlock);

    function deposit(uint256 _amount) external;

    function withdraw(uint256 _amount) external;

    function emergencyWithdraw() external;

    function claimRewards() external;

    function claimReward(uint256 _rid) external;

    function add(IERC20 _rewardToken, uint256 _totalRewards) external;

    function addMulti(RewardSettings[] memory _poolSettings) external;

    function recoverERC20(address _tokenAddress, uint256 _tokenAmount) external;

    function recoverUnclaimedRewards() external;

    function extendRewards(
        uint256 _newEndBlock,
        uint256[] memory _newTotalRewards
    ) external;

    function rewardsLength() external view returns (uint256);

    function balanceOf(address _user) external view returns (uint256);

    function totalSupply() external view returns (uint256);

    function getPendingRewards(uint256 _rid, address _user)
        external
        view
        returns (uint256);

    function getAllPendingRewards(address _user)
        external
        view
        returns (PendingRewards[] memory);

    function getRewardsForDuration()
        external
        view
        returns (RewardSettings[] memory);

    function earned(address _user)
        external
        view
        returns (EarnedRewards[] memory);
}
