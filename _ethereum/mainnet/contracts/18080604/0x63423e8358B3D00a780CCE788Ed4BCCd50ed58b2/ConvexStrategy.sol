// SPDX-License-Identifier: BUSL-1.1
pragma solidity 0.8.17;

import "./IBooster.sol";
import "./IBaseRewardPool.sol";
import "./CurvePoolBase.sol";

abstract contract ConvexStrategy is CurvePoolBase {
    uint256 internal constant BASE_REWARD_COUNT = 2;

    /// @notice Booster contract
    IBooster public immutable booster;
    /// @notice Reward pool contract
    IBaseRewardPool public crvRewards;
    /// @notice Crv reward token.
    address public crvRewardToken;
    /// @notice Cvx reward token.
    address public cvxRewardToken;
    /// @notice Booster pool id
    uint96 public pid;
    /// @notice Are there additional rewards to be collected.
    bool public extraRewards;

    constructor(IBooster booster_) {
        if (address(booster_) == address(0)) revert ConfigurationAddressZero();

        booster = booster_;
    }

    function __ConvexStrategy_init(uint96 pid_, bool extraRewards_) internal onlyInitializing {
        pid = pid_;
        extraRewards = extraRewards_;

        IBooster.PoolInfo memory cvxPool = booster.poolInfo(pid_);
        crvRewards = IBaseRewardPool(cvxPool.crvRewards);
        crvRewardToken = crvRewards.rewardToken();
        cvxRewardToken = booster.minter();
    }

    function setExtraRewards(bool extraRewards_) external onlyRole(ROLE_SPOOL_ADMIN, msg.sender) {
        extraRewards = extraRewards_;
    }

    function _lpTokenBalance() internal view override returns (uint256) {
        return crvRewards.balanceOf(address(this));
    }

    function _handleDeposit() internal override {
        uint256 lpAmount = lpToken.balanceOf(address(this));

        _resetAndApprove(lpToken, address(booster), lpAmount);

        booster.deposit(pid, lpAmount, true);

        if (_isViewExecution()) {
            emit Slippages(true, lpAmount, "");
        }
    }

    function _handleWithdrawal(uint256 lpTokens) internal override {
        crvRewards.withdrawAndUnwrap(lpTokens, false);
    }

    function _getRewards() internal override returns (address[] memory) {
        // get CRV and extra rewards
        crvRewards.getReward(address(this), extraRewards);

        address[] memory rewardTokens;
        if (extraRewards) {
            uint256 extraRewardCount = crvRewards.extraRewardsLength();
            rewardTokens = new address[](BASE_REWARD_COUNT + extraRewardCount);

            for (uint256 i; i < extraRewardCount; ++i) {
                rewardTokens[BASE_REWARD_COUNT + i] = crvRewards.extraRewards(i);
            }
        } else {
            rewardTokens = new address[](BASE_REWARD_COUNT);
        }

        rewardTokens[0] = crvRewardToken;
        rewardTokens[1] = cvxRewardToken;

        return rewardTokens;
    }
}
