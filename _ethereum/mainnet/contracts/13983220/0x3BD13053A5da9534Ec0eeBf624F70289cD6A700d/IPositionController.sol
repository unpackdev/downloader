// SPDX-License-Identifier: MIT
pragma solidity ^0.7.4;
pragma experimental ABIEncoderV2;

interface IPositionController {
    enum StakingState {
        IDLE,
        STAKING,
        WITHDRAWING_REWARDS,
        UNSTAKING
    }

    struct FeeInfo {
        address feeRecipient; // Address to accrue fees to
        uint256 successFeePercentage; // Percent of rewards accruing to manager
    }

    function canStake() external view returns (bool);

    function canCallUnstake() external view returns (bool);

    function canUnstake() external view returns (bool);

    function stake(uint256 _amount) external;

    function callUnstake() external returns (uint256);

    function unstake() external returns (uint256);

    function maxUnstake() external view returns (uint256);

    function withdrawRewards() external;

    function outstandingRewards() external view returns (uint256);

    /// @notice Worth of managed assets, in 'base' currency.
    //// Includes 'staked' amount and outstanding rewards, converted
    function netWorth() external view returns (uint256);

    // @notice APY, if NOT based on historical purchases
    // @return % with precision
    function apy() external view returns (uint256);

    function description() external view returns (string memory);

    function productList() external view returns (address[] memory _products);

    function unstakingInfo() external view returns (uint256 _amount, uint256 _unstakeAvailable);
}
