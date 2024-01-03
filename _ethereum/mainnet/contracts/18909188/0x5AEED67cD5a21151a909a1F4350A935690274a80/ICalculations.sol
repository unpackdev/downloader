// SPDX-License-Identifier: MIT

pragma solidity 0.8.21;

import "./IAdminStructure.sol";
import "./IStrategyHelper.sol";

/**
 * @title Dollet ICalculations
 * @author Dollet Team
 * @notice Interface for Calculations contract.
 */
interface ICalculations {
    /**
     * @param wantDeposit Portion of the total want tokens that belongs to the deposit of the user.
     * @param wantRewards Portion of the total want tokens that belongs to the rewards of the user.
     * @param wantDepositAfterFee Portion of the total want tokens after fee that belongs to the deposit of the user.
     * @param wantRewardsAfterFee Portion of the total want tokens after fee that belongs to the rewards of the user.
     * @param depositInToken Deposit amount valued in token.
     * @param rewardsInToken Rewards amount valued in token.
     */
    struct WithdrawalEstimation {
        uint256 wantDeposit;
        uint256 wantRewards;
        uint256 wantDepositAfterFee;
        uint256 wantRewardsAfterFee;
        uint256 depositInToken;
        uint256 rewardsInToken;
    }

    /**
     * @notice Logs information when a Strategy contract is set.
     * @param _strategy Strategy contract address.
     */
    event StrategySet(address _strategy);

    /**
     * @notice Logs information when a StrategyHelper contract is set.
     * @param _strategyHelper StrategyHelper contract address.
     */
    event StrategyHelperSet(address _strategyHelper);

    /**
     * @notice Allows the super admin to set the strategy values (Strategy and StrategyHelper contracts' addresses).
     * @param _strategy Address of the Strategy contract.
     */
    function setStrategyValues(address _strategy) external;

    /**
     * @notice Returns the value of 100% with 2 decimals.
     * @return The value of 100% with 2 decimals.
     */
    function ONE_HUNDRED_PERCENTS() external view returns (uint16);

    /**
     * @notice Returns AdminStructure contract address.
     * @return AdminStructure contract address.
     */
    function adminStructure() external view returns (IAdminStructure);

    /**
     * @notice Returns StrategyHelper contract address.
     * @return StrategyHelper contract address.
     */
    function strategyHelper() external view returns (IStrategyHelper);

    /**
     * @notice Returns the Strategy contract address.
     * @return Strategy contract address.
     */
    function strategy() external view returns (address);

    /**
     * @notice Returns the amount of the user deposit in terms of the token specified.
     * @param _user The address of the user to get the deposit value for.
     * @param _token The address of the token to use.
     * @return The estimated user deposit in the specified token.
     */
    function userDeposit(address _user, address _token) external view returns (uint256);

    /**
     * @notice Returns the amount of the total deposits in terms of the token specified.
     * @param _token The address of the token to use.
     * @return The amount of total deposit in the specified token.
     */
    function totalDeposits(address _token) external view returns (uint256);

    /**
     * @notice Returns the balance of the want token of the strategy after making a compound.
     * @param _slippageTolerance Slippage to use for the calculation.
     * @param _rewardData Encoded bytes with information about the reward tokens.
     * @return The want token balance after a compound.
     */
    function estimateWantAfterCompound(
        uint16 _slippageTolerance,
        bytes calldata _rewardData
    )
        external
        view
        returns (uint256);

    /**
     * @notice Returns the expected amount of want tokens to be obtained from a deposit.
     * @param _token The token to be used for deposit.
     * @param _amount The amount of tokens to be deposited.
     * @param _slippageTolerance The slippage tolerance for the deposit.
     * @param _data Extra information used to estimate.
     * @return The minimum want tokens expected to be obtained from the deposit.
     */
    function estimateDeposit(
        address _token,
        uint256 _amount,
        uint256 _slippageTolerance,
        bytes calldata _data
    )
        external
        view
        returns (uint256);

    /**
     * @notice Estimates the price of an amount of want tokens in the specified token.
     * @param _token The address of the token.
     * @param _amount The amount of want tokens.
     * @param _slippageTolerance The allowed slippage percentage.
     * @return _amountInToken The minimum amount of tokens to get from the want amount.
     */
    function estimateWantToToken(
        address _token,
        uint256 _amount,
        uint16 _slippageTolerance
    )
        external
        view
        returns (uint256 _amountInToken);

    /**
     * @notice Calculates the withdrawable amount of a user.
     * @param _user The address of the user to get the withdrawable amount. (Use strategy address to calculate for all
     *              users).
     * @param _wantToWithdraw The amount of want to withdraw.
     * @param _maxUserWant The maximum amount of want that the user can withdraw.
     * @param _token Address of the to use for the calculation.
     * @param _slippageTolerance Slippage to use for the calculation.
     * @return WithdrawalEstimation struct including the data about the withdrawal:
     *         wantDepositUsed Portion of the total want tokens that belongs to the deposit of the user.
     *         wantRewardsUsed Portion of the total want tokens that belongs to the rewards of the user.
     *         wantDepositAfterFee Portion of the total want tokens after fee that belongs to the deposit of the user.
     *         wantRewardsAfterFee Portion of the total want tokens after fee that belongs to the rewards of the user.
     *         depositInToken Deposit amount valued in token.
     *         rewardsInToken Rewards amount valued in token.
     */
    function getWithdrawableAmount(
        address _user,
        uint256 _wantToWithdraw,
        uint256 _maxUserWant,
        address _token,
        uint16 _slippageTolerance
    )
        external
        view
        returns (WithdrawalEstimation memory);

    /**
     * @notice Calculates the withdrawable distribution of a user.
     * @param _user A user to read the proportional distribution. (Use strategy address to calculate for all users).
     * @param _wantToWithdraw Amount from the total want tokens of the user wants to withdraw.
     * @param _maxUserWant The maximum user want to withdraw.
     * @return _wantDepositUsed Portion the total want tokens that belongs to the deposit of the user.
     * @return _wantRewardsUsed Portion the total want tokens that belongs to the rewards of the user.
     */
    function calculateWithdrawalDistribution(
        address _user,
        uint256 _wantToWithdraw,
        uint256 _maxUserWant
    )
        external
        view
        returns (uint256 _wantDepositUsed, uint256 _wantRewardsUsed);

    /**
     * @notice Calculates the used amounts from a given token amount on a withdrawal.
     * @param _user User to read the information from. (Use strategy address to calculate for all users).
     * @param _wantToWithdraw Amount from the total want tokens of the user wants to withdraw.
     * @param _maxUserWant The maximum user want to withdraw.
     * @param _withdrawalTokenOut The expected amount of tokens for the want tokens withdrawn.
     * @return _depositUsed Distibution of the token out amount that belongs to the deposit.
     * @return _rewardsUsed Distibution of the token out amount that belongs to the rewards.
     * @return _wantDepositUsed Portion the total want tokens that belongs to the deposit of the user.
     * @return _wantRewardsUsed Portion the total want tokens that belongs to the rewards of the user.
     */
    function calculateUsedAmounts(
        address _user,
        uint256 _wantToWithdraw,
        uint256 _maxUserWant,
        uint256 _withdrawalTokenOut
    )
        external
        view
        returns (uint256 _depositUsed, uint256 _rewardsUsed, uint256 _wantDepositUsed, uint256 _wantRewardsUsed);

    /**
     * @notice Calculates the minimum output amount applying a slippage tolerance percentage to the amount.
     * @param _amount The amount of tokens to use.
     * @param _slippageTolerance The slippage percentage to apply.
     * @return _result The minimum output amount.
     */
    function getMinimumOutputAmount(
        uint256 _amount,
        uint256 _slippageTolerance
    )
        external
        pure
        returns (uint256 _result);
}
