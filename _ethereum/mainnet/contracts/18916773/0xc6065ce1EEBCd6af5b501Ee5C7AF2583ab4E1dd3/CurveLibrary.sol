// SPDX-License-Identifier: GPL-3.0-only
pragma solidity ^0.8.18;

import "./FixedPoint.sol";
import "./LogExpMath.sol";
import "./FeeState.sol";
import "./Constants.sol";
import "./Enums.sol";

/**
 * @author  .
 * @title   .
 * @dev     .
 * @notice  .
 */
library CurveLibrary {
    using FixedPoint for uint256;

    /**
     * @notice  Update fee reward of account
     * @dev
     * @param   account : Account address
     * @param   userBalance : Current account balance
     * @param   feeState : Fee state storage
     * @param   rewardType : Reward for LP or staking
     */
    function updateReward(
        address account,
        uint256 userBalance,
        FeeState[MAX_FEE_TYPE_COUNT] storage feeState,
        RewardType rewardType
    ) public {
        _updateReward(account, userBalance, feeState[FEE_RESERVE], rewardType);
        _updateReward(account, userBalance, feeState[FEE_IBC_FROM_TRADE], rewardType);
        _updateReward(account, userBalance, feeState[FEE_IBC_FROM_LP], rewardType);
    }

    /**
     * @notice  Calculate pending reward
     * @dev
     * @param   recipient : Account address
     * @param   feeState : Fee state storage
     * @param   lpBalance : LP token balance
     * @param   stakingBalance : Staking balance
     * @return  inverseTokenForLp : IBC token reward for account as LP
     * @return  inverseTokenForStaking : IBC token reward for account as Staker
     * @return  reserveForLp : Reserve reward for account as LP
     * @return  reserveForStaking : Reserve reward for account as Staker
     */
    function calcPendingReward(
        address recipient,
        FeeState[MAX_FEE_TYPE_COUNT] storage feeState,
        uint256 lpBalance,
        uint256 stakingBalance
    )
        public
        view
        returns (uint256 inverseTokenForLp, uint256 inverseTokenForStaking, uint256 reserveForLp, uint256 reserveForStaking)
    {
        inverseTokenForLp = _calcPendingReward(recipient, feeState[FEE_IBC_FROM_TRADE], lpBalance, RewardType.LP)
            + _calcPendingReward(recipient, feeState[FEE_IBC_FROM_LP], lpBalance, RewardType.LP);
        inverseTokenForStaking = _calcPendingReward(recipient, feeState[FEE_IBC_FROM_TRADE], stakingBalance, RewardType.STAKING)
            + _calcPendingReward(recipient, feeState[FEE_IBC_FROM_LP], stakingBalance, RewardType.STAKING);
        reserveForLp = _calcPendingReward(recipient, feeState[FEE_RESERVE], lpBalance, RewardType.LP);
        reserveForStaking = _calcPendingReward(recipient, feeState[FEE_RESERVE], stakingBalance, RewardType.STAKING);
    }

    /**
     * @notice  Check whether value change
     * @dev     Based on change percent
     * @param   value : Current value
     * @param   newValue : New value
     * @param   allowedChangePercent : Allowed change percent
     * @return  bool : Is value changed
     */
    function valueChanged(uint256 value, uint256 newValue, uint256 allowedChangePercent) public pure returns (bool) {
        uint256 diff = newValue > value ? newValue - value : value - newValue;

        return (diff.divDown(value) > allowedChangePercent);
    }

    /**
     * @notice  Initialize reward EMA calculation
     * @dev
     * @param   feeState : Fee state storage
     */
    function initializeRewardEMA(FeeState[MAX_FEE_TYPE_COUNT] storage feeState) public {
        feeState[FEE_IBC_FROM_TRADE].emaRewardUpdateBlockTimestamp = block.timestamp;
        feeState[FEE_RESERVE].emaRewardUpdateBlockTimestamp = block.timestamp;
        feeState[FEE_IBC_FROM_LP].emaRewardUpdateBlockTimestamp = block.timestamp;
    }

    /**
     * @notice  Update reward EMA
     * @dev     Only get updated for next fee event
     * @param   feeState : Fee state storage
     */
    function updateRewardEMA(FeeState storage feeState) public {
        if (block.timestamp != feeState.emaRewardUpdateBlockTimestamp) {
            uint256 alpha = _calcParameterAlpha(feeState);
            uint256 lpRewardEMA = _calcEMA(feeState, RewardType.LP, alpha);
            uint256 stakingRewardEMA = _calcEMA(feeState, RewardType.STAKING, alpha);

            feeState.previousReward[REWARD_LP] = feeState.totalReward[REWARD_LP];
            feeState.previousReward[REWARD_STAKE] = feeState.totalReward[REWARD_STAKE];
            feeState.emaReward[REWARD_LP] = lpRewardEMA;
            feeState.emaReward[REWARD_STAKE] = stakingRewardEMA;
            feeState.emaRewardUpdateBlockTimestamp = block.timestamp;
        }
    }

    /**
     * @notice  Calculate reward EMA
     * @dev
     * @param   feeState : Fee state storage
     * @param   rewardType : LP or Staking
     * @return  inverseTokenReward : EMA IBC token reward per second
     * @return  reserveReward : EMA reserve reward per second
     */
    function calcRewardEMA(FeeState[MAX_FEE_TYPE_COUNT] storage feeState, RewardType rewardType)
        public
        view
        returns (uint256 inverseTokenReward, uint256 reserveReward)
    {
        uint256 alpha = _calcParameterAlpha(feeState[FEE_IBC_FROM_TRADE]);
        inverseTokenReward = _calcEMA(feeState[FEE_IBC_FROM_TRADE], rewardType, alpha);

        alpha = _calcParameterAlpha(feeState[FEE_RESERVE]);
        reserveReward = _calcEMA(feeState[FEE_RESERVE], rewardType, alpha);

        alpha = _calcParameterAlpha(feeState[FEE_IBC_FROM_LP]);
        inverseTokenReward += _calcEMA(feeState[FEE_IBC_FROM_LP], rewardType, alpha);
    }

    /**
     * @notice  Update reward state
     * @dev
     * @param   account : Account address
     * @param   userBalance : Account balance of LP/Staking
     * @param   state : Fee state storage
     * @param   rewardType : LP or Staking
     */
    function _updateReward(address account, uint256 userBalance, FeeState storage state, RewardType rewardType) private {
        if (userBalance > 0) {
            uint256 reward = (state.globalFeeIndexes[uint256(rewardType)] - state.feeIndexStates[uint256(rewardType)][account])
                .mulDown(userBalance);
            state.pendingRewards[uint256(rewardType)][account] += reward;
            state.feeIndexStates[uint256(rewardType)][account] = state.globalFeeIndexes[uint256(rewardType)];
        } else {
            state.feeIndexStates[uint256(rewardType)][account] = state.globalFeeIndexes[uint256(rewardType)];
        }
    }

    /**
     * @notice  Calculate pending reward
     * @dev
     * @param   account : Account address
     * @param   state : Fee state storage
     * @param   userBalance : LP/Staking balance
     * @param   rewardType : LP or Staking
     * @return  uint256 : Pending reward
     */
    function _calcPendingReward(address account, FeeState storage state, uint256 userBalance, RewardType rewardType)
        private
        view
        returns (uint256)
    {
        uint256 reward = state.pendingRewards[uint256(rewardType)][account];
        if (userBalance > 0) {
            reward += (state.globalFeeIndexes[uint256(rewardType)] - state.feeIndexStates[uint256(rewardType)][account]).mulDown(
                userBalance
            );
        }
        return reward;
    }

    /**
     * @notice  Calculate alpha parameter for EMA calculation
     * @dev
     * @param   feeState : Fee state storage
     * @return  alpha : Parameter alpha
     */
    function _calcParameterAlpha(FeeState storage feeState) private view returns (uint256 alpha) {
        int256 exponent = int256(((block.timestamp - feeState.emaRewardUpdateBlockTimestamp) * UINT_ONE).divDown(SECONDS_PER_DAY));
        alpha = -exponent <= LogExpMath.MIN_NATURAL_EXPONENT ? UINT_ONE : UINT_ONE - uint256(LogExpMath.exp(-exponent));
    }

    /**
     * @notice  Calculate reward EMA
     * @dev
     * @param   feeState : Fee state storage
     * @param   rewardType : LP or Staking
     * @param   alpha : Parameter alpha
     * @return  rewardEMA : Reward EMA
     */
    function _calcEMA(FeeState storage feeState, RewardType rewardType, uint256 alpha) private view returns (uint256 rewardEMA) {
        if (block.timestamp > feeState.emaRewardUpdateBlockTimestamp) {
            uint256 pastTimeperiod = block.timestamp - feeState.emaRewardUpdateBlockTimestamp;
            uint256 previousEMA = feeState.emaReward[uint256(rewardType)];
            uint256 rewardSinceLastUpdatePerSecond = (
                feeState.totalReward[uint256(rewardType)] - feeState.previousReward[uint256(rewardType)]
            ).divDown(pastTimeperiod * UINT_ONE);

            if (rewardSinceLastUpdatePerSecond >= previousEMA) {
                rewardEMA = previousEMA + (alpha.mulDown(rewardSinceLastUpdatePerSecond - previousEMA));
            } else {
                rewardEMA = previousEMA - (alpha.mulDown(previousEMA - rewardSinceLastUpdatePerSecond));
            }
        } else {
            rewardEMA = feeState.emaReward[uint256(rewardType)];
        }
    }

    function scaleTo(uint256 value, uint8 targetDecimals) public pure returns (uint256) {
        if (targetDecimals == DEFAULT_DECIMALS) return value;

        return targetDecimals < DEFAULT_DECIMALS
            ? value / (10 ** (DEFAULT_DECIMALS - targetDecimals))
            : value * (10 ** (targetDecimals - DEFAULT_DECIMALS));
    }

    function scaleFrom(uint256 value, uint8 fromDecimals) public pure returns (uint256) {
        if (fromDecimals == DEFAULT_DECIMALS) return value;

        return fromDecimals < DEFAULT_DECIMALS
            ? value * (10 ** (DEFAULT_DECIMALS - fromDecimals))
            : value / (10 ** (fromDecimals - DEFAULT_DECIMALS));
    }

    function valueInRange(uint256 value, uint256[2] memory range) public pure returns (bool) {
        return value >= range[0] && (range[1] == 0 || value <= range[1]);
    }
}
