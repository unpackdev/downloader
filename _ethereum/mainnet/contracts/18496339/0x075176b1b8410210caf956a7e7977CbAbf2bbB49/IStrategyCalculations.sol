// SPDX-License-Identifier: MIT

pragma solidity 0.8.10;

/// @notice Interface for the Strategy Calculations contract
/// @dev This interface provides functions for performing various calculations related to the strategy.
interface IStrategyCalculations {
    /// @return The address of the Admin Structure contract
    function adminStructure() external view returns (address);

    /// @return The address of the Strategy contract
    function strategy() external view returns (address);

    /// @return The address of the Quoter contract
    function quoter() external view returns (address);

    /// @dev Constant for representing 100 (100%)
    /// @return The value of 100
    function ONE_HUNDRED() external pure returns (uint256);

    /// @notice Calculates the minimum amount of tokens to receive from Curve for a specific token and maximum amount
    /// @param _token The address of the token to withdraw
    /// @param _maxAmount The maximum amount of tokens to withdraw
    /// @param _slippage The allowed slippage percentage
    /// @return The minimum amount of tokens to receive from Curve
    function calculateCurveMinWithdrawal(
        address _token,
        uint256 _maxAmount,
        uint256 _slippage
    ) external view returns (uint256);

    /// @notice Calculates the amount of LP tokens to get on curve deposit
    /// @param _token The token to estimate the deposit
    /// @param _amount The amount of tokens to deposit
    /// @param _slippage The allowed slippage percentage
    /// @return The amount of LP tokens to get
    function calculateCurveDeposit(
        address _token,
        uint256 _amount,
        uint256 _slippage
    ) external view returns (uint256);

    /// @notice Estimates the amount of tokens to swap from one token to another
    /// @param _from The address of the token to swap from
    /// @param _to The address of the token to swap to
    /// @param _amount The amount of tokens to swap
    /// @param _slippage The allowed slippage percentage
    /// @return estimate The estimated amount of tokens to receive after the swap
    function estimateSwap(
        address _from,
        address _to,
        uint256 _amount,
        uint256 _slippage
    ) external returns (uint256 estimate);

    /// @notice Estimates the deposit details for a specific token and amount
    /// @param _token The address of the token to deposit
    /// @param _amount The amount of tokens to deposit
    /// @param _slippage The allowed slippage percentage
    /// @return amountWant The minimum amount of tokens to get on the curve deposit
    function estimateDeposit(
        address _token,
        uint256 _amount,
        uint256 _slippage
    ) external view returns (uint256 amountWant);

    /// @notice Estimates the withdrawal details for a specific user, token, maximum amount, and slippage
    /// @param _user The address of the user
    /// @param _token The address of the token to withdraw
    /// @param _maxAmount The maximum amount of tokens to withdraw
    /// @param _slippage The allowed slippage percentage
    /// @return minCurveOutput The minimum amount of tokens to get from the curve withdrawal
    /// @return withdrawable The minimum amount of tokens to get after the withdrawal
    function estimateWithdrawal(
        address _user,
        address _token,
        uint256 _maxAmount,
        uint256 _slippage
    ) external view returns (uint256 minCurveOutput, uint256 withdrawable);

    /// @notice Retrieves information about the pending rewards to harvest from the convex pool
    /// @return rewardAmounts rewards the amount representing the pending rewards
    /// @return rewardTokens addresses of the reward tokens
    /// @return enoughRewards list indicating if the reward token is enough to harvest
    /// @return atLeastOne indicates if there is at least one reward to harvest
    function getPendingToHarvestView()
        external
        view
        returns (
            uint256[] memory rewardAmounts,
            address[] memory rewardTokens,
            bool[] memory enoughRewards,
            bool atLeastOne
        );

    /// @notice Retrieves information about the pending rewards to harvest from the convex pool
    /// @return rewardAmounts rewards the amount representing the pending rewards
    /// @return rewardTokens addresses of the reward tokens
    /// @return enoughRewards list indicating if the reward token is enough to harvest
    /// @return atLeastOne indicates if there is at least one reward to harvest
    function getPendingToHarvest()
        external
        returns (
            uint256[] memory rewardAmounts,
            address[] memory rewardTokens,
            bool[] memory enoughRewards,
            bool atLeastOne
        );

    /// @notice Estimates the rewards details for a specific user, token, amount, and slippage
    /// @param _user The address of the user
    /// @param _token The address of the token to calculate rewards for
    /// @param _amount The amount of tokens
    /// @param _slippage The allowed slippage percentage
    /// @return minCurveOutput The minimum amount of tokens to get from the curve withdrawal
    /// @return claimable The minimum amount of tokens to get after the claim of rewards
    function estimateRewards(
        address _user,
        address _token,
        uint256 _amount,
        uint256 _slippage
    ) external view returns (uint256 minCurveOutput, uint256 claimable);

    /// @notice Estimates the total claimable rewards for all users using a specific token and slippage
    /// @param _token The address of the token to calculate rewards for
    /// @param _amount The amount of tokens
    /// @param _slippage The allowed slippage percentage
    /// @return claimable The total claimable amount of tokens
    function estimateAllUsersRewards(
        address _token,
        uint256 _amount,
        uint256 _slippage
    ) external view returns (uint256 claimable);

    /// @dev Returns the amount of tokens deposited by a specific user in the indicated token
    /// @param _user The address of the user.
    /// @param _token The address of the token.
    /// @return The amount of tokens deposited by the user.
    function userDeposit(address _user, address _token) external view returns (uint256);

    /// @dev Returns the total amount of tokens deposited in the strategy in the indicated token
    /// @param _token The address of the token.
    /// @return The total amount of tokens deposited.
    function totalDeposits(address _token) external view returns (uint256);

    /// @notice Retrieves the minimum amount of tokens to swap from a specific fromToken to toToken
    /// @param _fromToken The address of the token to swap from
    /// @param _toToken The address of the token to swap to
    /// @return The minimum amount of tokens to swap
    function getAutomaticSwapMin(address _fromToken, address _toToken) external returns (uint256);

    /// @notice Retrieves the minimum amount of LP tokens to obtained from a curve deposit
    /// @param _depositAmount The amount to deposit
    /// @return The minimum amount of LP tokens to obtained from the deposit on curve
    function getAutomaticCurveMinLp(uint256 _depositAmount) external returns (uint256);

    /// @notice Retrieves the balance of a specific token held by the Strategy
    /// @param _token The address of the token
    /// @return The token balance
    function _getTokenBalance(address _token) external view returns (uint256);

    /// @notice Retrieves the minimum value between a specific amount and a slippage percentage
    /// @param _amount The amount
    /// @param _slippage The allowed slippage percentage
    /// @return The minimum value
    function _getMinimum(uint256 _amount, uint256 _slippage) external pure returns (uint256);

    /// @notice Estimates the want balance after a harvest
    /// @param _slippage The allowed slippage percentage
    /// @return Returns the new want amount
    function estimateWantAfterHarvest(uint256 _slippage) external returns (uint256);
}

interface IStrategyCalculationsTwocrypto is IStrategyCalculations {
    /// @notice Formats the array input for curve
    /// @param _depositToken The address of the deposit token
    /// @param _amount The amount to deposit
    /// @return amounts An array of token amounts to use in curve
    function getCurveAmounts(
        address _depositToken,
        uint256 _amount
    ) external view returns (uint256[2] memory amounts);
}

interface IStrategyCalculationsTricryptoL1 is IStrategyCalculations {
    /// @notice Formats the array input for curve
    /// @param _depositToken The address of the deposit token
    /// @param _amount The amount to deposit
    /// @return amounts An array of token amounts to use in curve
    function getCurveAmounts(
        address _depositToken,
        uint256 _amount
    ) external view returns (uint256[3] memory amounts);
}
