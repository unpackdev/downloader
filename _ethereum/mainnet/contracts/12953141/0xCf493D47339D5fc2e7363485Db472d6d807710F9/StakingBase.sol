// SPDX-License-Identifier: MIT
pragma solidity ^0.6.12;

import "./SafeMath.sol";
import "./IERC20.sol";
import "./SafeERC20.sol";

abstract contract StakingBase {
    using SafeMath for uint256;
    using SafeERC20 for IERC20;

    struct StakeData {
        uint256 amount;
        uint256 rewards;
        uint256 withdrawn;
        uint256 startsAt;
    }

    uint256 public minStakeAmount;
    uint256 public revenue;
    IERC20 public stakingToken;

    event MinStakeAmountUpdated(address indexed owner, uint256 value);
    event Staked(address indexed account, uint256 stakeId, uint256 amount);
    event RewardPoolDecreased(address indexed owner, uint256 amount);
    event RewardPoolIncreased(address indexed owner, uint256 amount);
    event Withdrawn(address indexed account, uint256 stakeId, uint256 amount);

    function _calculateWithdrawAmountParts(
        StakeData memory stake_,
        uint256 amount
    ) internal pure returns (uint256 rewardsSubValue, uint256 totalStakedSubValue) {
        if (stake_.withdrawn < stake_.rewards) {
            uint256 difference = stake_.rewards.sub(stake_.withdrawn);
            if (difference >= amount) {
                rewardsSubValue = amount;
            } else {
                rewardsSubValue = difference;
                totalStakedSubValue = amount.sub(difference);
            }
        } else {
            totalStakedSubValue = amount;
        }
    }

    modifier onlyPositiveAmount(uint256 amount) {
        require(amount > 0, "Amount not positive");
        _;
    }
}
