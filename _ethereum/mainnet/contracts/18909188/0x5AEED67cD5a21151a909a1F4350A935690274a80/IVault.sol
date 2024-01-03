// SPDX-License-Identifier: MIT

pragma solidity 0.8.21;

import "./ERC20Lib.sol";
import "./IAdminStructure.sol";
import "./IStrategy.sol";
import "./IWETH.sol";
import "./ICalculations.sol";

/**
 * @title Dollet IVault
 * @author Dollet Team
 * @notice Interface with all types, events, external, and public methods for the Vault contract.
 */
interface IVault {
    /**
     * @notice Token types enumeration.
     */
    enum TokenType {
        Deposit,
        Withdrawal
    }

    /**
     * @notice Structure of the values to store the token min deposit limit.
     */
    struct DepositLimit {
        address token;
        uint256 minAmount;
    }

    /**
     * @notice Logs information when token changes its status (allowed/disallowed).
     * @param _tokenType A type of the token.
     * @param _token A token address.
     * @param _status A new status of the token.
     */
    event TokenStatusChanged(TokenType _tokenType, address _token, uint256 _status);

    /**
     * @notice Logs information when the pause status is changed.
     * @param _status The new pause status (true or false).
     */
    event PauseStatusChanged(bool _status);

    /**
     * @notice Logs information about the withdrawal of stuck tokens.
     * @param _caller An address of the admin who executed the withdrawal operation.
     * @param _token An address of a token that was withdrawn.
     * @param _amount An amount of tokens that were withdrawn.
     */
    event WithdrawStuckTokens(address _caller, address _token, uint256 _amount);

    /**
     * @notice Logs when the deposit limit of a token has been set.
     * @param _limitBefore The deposit limit before.
     * @param _limitAfter The deposit limit after.
     */
    event DepositLimitsSet(DepositLimit _limitBefore, DepositLimit _limitAfter);

    /**
     * @notice Deposit to the strategy.
     * @param _user Address of the user providing the deposit tokens.
     * @param _token Address of the token to deposit.
     * @param _amount Amount of tokens to deposit.
     * @param _additionalData Additional encoded data for the deposit.
     */
    function deposit(address _user, address _token, uint256 _amount, bytes calldata _additionalData) external payable;

    /**
     * @notice Deposit to the strategy.
     * @param _user Address of the user providing the deposit tokens.
     * @param _token Address of the token to deposit.
     * @param _amount Amount of tokens to deposit.
     * @param _additionalData Additional encoded data for the deposit.
     * @param _signature Signature to make a deposit with permit.
     */
    function depositWithPermit(
        address _user,
        address _token,
        uint256 _amount,
        bytes calldata _additionalData,
        Signature calldata _signature
    )
        external;

    /**
     * @notice Withdraw from the strategy.
     * @param _recipient Address of the recipient to receive the tokens.
     * @param _token Address of the token to withdraw.
     * @param _amountShares Amount of shares to withdraw from the user.
     * @param _additionalData Additional encoded data for the withdrawal.
     */
    function withdraw(
        address _recipient,
        address _token,
        uint256 _amountShares,
        bytes calldata _additionalData
    )
        external;

    /**
     * @notice Allows the super admin to change the admin structure contract address.
     * @param _adminStructure admin structure contract address.
     */
    function setAdminStructure(address _adminStructure) external;

    /**
     * @notice Edits deposit allowed tokens list.
     * @param _token An address of the token to allow/disallow.
     * @param _status A marker (true/false) that indicates if to allow/disallow a token.
     */
    function editDepositAllowedTokens(address _token, uint256 _status) external;

    /**
     * @notice Edits withdrawal allowed tokens list.
     * @param _token An address of the token to allow/disallow.
     * @param _status A marker (true/false) that indicates if to allow/disallow a token.
     */
    function editWithdrawalAllowedTokens(address _token, uint256 _status) external;

    /**
     * @notice Edits the deposit limits for specific tokens.
     * @param _depositLimits The array of DepositLimit struct to set.
     */
    function editDepositLimit(DepositLimit[] calldata _depositLimits) external;

    /**
     * @notice Pauses and unpauses the contract deposits.
     * @dev Sets the opposite of the current state of the pause.
     */
    function togglePause() external;

    /**
     * @notice Handles the case where tokens get stuck in the contract. Allows the admin to send the tokens to the super
     *         admin.
     * @param _token The address of the stuck token.
     */
    function inCaseTokensGetStuck(address _token) external;

    /**
     * @notice Returns a list of allowed tokens for a specified token type.
     * @param _tokenType A token type for which to return a list of tokens.
     * @return A list of allowed tokens for a specified token type.
     */
    function getListAllowedTokens(TokenType _tokenType) external view returns (address[] memory);

    /**
     * @notice Converts want tokens to vault shares.
     * @param _wantAmount An amount of want tokens to convert to vault shares.
     * @return An amount of vault shares in the specified want tokens amount.
     */
    function wantToShares(uint256 _wantAmount) external view returns (uint256);

    /**
     * @notice Returns the amount of the user deposit in terms of the token specified when possible, or in terms of want
     *         (to be processed off-chain).
     * @param _user The address of the user to get the deposit value for.
     * @param _token The address of the token to use.
     * @return The user deposit in the provided token.
     */
    function userDeposit(address _user, address _token) external view returns (uint256);

    /**
     * @notice Returns the amount of the total deposits in terms of the token specified when possible, or in terms of
     *         want (to be processed off-chain).
     * @param _token The address of the token to use.
     * @return The total deposit in the provided token.
     */
    function totalDeposits(address _token) external view returns (uint256);

    /**
     * @notice Returns the maximum number of want tokens that the user can withdraw.
     * @param _user A user address for whom to calculate the maximum number of want tokens that the user can withdraw.
     * @return The maximum number of want tokens that the user can withdraw.
     */
    function getUserMaxWant(address _user) external view returns (uint256);

    /**
     * @notice Helper function to calculate the required share to withdraw a specific amount of want tokens.
     * @dev The _wantToWithdraw must be taken from the function `estimateWithdrawal()`, the maximum amount is equivalent
     *      to `(_wantDepositAfterFee + _wantRewardsAfterFee)`.
     * @dev The flag `_withdrawAll` helps to avoid leaving remaining funds due to changes in the estimate since the user
     *      called `estimateWithdrawal()`.
     * @param _user The user to calculate the withdraw for.
     * @param _wantToWithdraw The amount of want tokens to withdraw (after compound and fees charging).
     * @param _slippageTolerance Slippage to use for the calculation.
     * @param _addionalData Encoded bytes with information about the reward tokens and slippage tolerance.
     * @param _withdrawAll Indicated whether to make a full withdrawal.
     * @return _sharesToWithdraw The amount of shares to withdraw for the specified amount of want tokens.
     */
    function calculateSharesToWithdraw(
        address _user,
        uint256 _wantToWithdraw,
        uint16 _slippageTolerance,
        bytes calldata _addionalData,
        bool _withdrawAll
    )
        external
        view
        returns (uint256 _sharesToWithdraw);

    /**
     * @notice Returns the deposit limit for a token.
     * @param _token The address of the token.
     * @return _limit The deposit limit for the specified token.
     */
    function getDepositLimit(address _token) external view returns (DepositLimit memory _limit);

    /**
     * @notice Estimates the deposit details for a specific token and amount.
     * @param _token The address to deposit.
     * @param _amount The amount of tokens to deposit.
     * @param _slippageTolerance The allowed slippage percentage.
     * @param _data Extra information used to estimate.
     * @param _addionalData Encoded bytes with information about the reward tokens and slippage tolerance.
     * @return _amountShares The amount of shares to receive from the vault.
     * @return _amountWant The minimum amount of LP tokens to get.
     */
    function estimateDeposit(
        address _token,
        uint256 _amount,
        uint16 _slippageTolerance,
        bytes calldata _data,
        bytes calldata _addionalData
    )
        external
        view
        returns (uint256 _amountShares, uint256 _amountWant);

    /**
     * @notice Converts vault shares to want tokens.
     * @param _sharesAmount An amount of vault shares to convert to want tokens.
     * @return An amount of want tokens in the specified vault shares amount.
     */
    function sharesToWant(uint256 _sharesAmount) external view returns (uint256);

    /**
     * @notice Shows the equivalent amount of shares converted to want tokens, considering compounding.
     * @dev Since this function uses slippage the actual result after a real compound might be slightly different.
     * @dev The result does not consider the system fees.
     * @param _sharesAmount The amount of shares.
     * @param _slippageTolerance The slippage for the compounding.
     * @param _addionalData Encoded bytes with information about the reward tokens and slippage tolerance.
     * @return The amount of want tokens equivalent to the shares considering compounding.
     */
    function sharesToWantAfterCompound(
        uint256 _sharesAmount,
        uint16 _slippageTolerance,
        bytes calldata _addionalData
    )
        external
        view
        returns (uint256);

    /**
     * @notice Shows the maximum want tokens that a user could obtain considering compounding.
     * @dev Since this function uses slippage the actual result after a real compound might be slightly different.
     * @dev The result does not consider the system fees.
     * @param _user The user to be analyzed. Use strategy address to calculate for all users.
     * @param _slippageTolerance The slippage for the compounding.
     * @param _addionalData Encoded bytes with information about the reward tokens and slippage tolerance.
     * @return The maximum amount of want tokens that the user has.
     */
    function getUserMaxWantWithCompound(
        address _user,
        uint16 _slippageTolerance,
        bytes calldata _addionalData
    )
        external
        view
        returns (uint256);

    /**
     * @notice Shows the maximum want tokens from the deposit and rewards that the user has, it estimates the want
     *         tokens that the user can withdraw after compounding and fees. Use strategy address to calculate for all
     *         users.
     * @dev Combine this function with the function `calculateSharesToWithdraw()`.
     * @dev Since this function uses slippage tolerance the actual result after a real compound might be slightly
     *      different.
     * @param _user The user to be analyzed.
     * @param _slippageTolerance The slippage tolerance for the compounding.
     * @param _addionalData Encoded bytes with information about the reward tokens and slippage tolerance.
     * @param _token The token to use for the withdrawal.
     * @return WithdrawalEstimation a struct including the data about the withdrawal:
     * wantDepositUsed Portion of the total want tokens that belongs to the deposit of the user.
     * wantRewardsUsed Portion of the total want tokens that belongs to the rewards of the user.
     * wantDepositAfterFee Portion of the total want tokens after fee that belongs to the deposit of the user.
     * wantRewardsAfterFee Portion of the total want tokens after fee that belongs to the rewards of the user.
     * depositInToken Deposit amount valued in token.
     * rewardsInToken Deposit amount valued in token.
     */
    function estimateWithdrawal(
        address _user,
        uint16 _slippageTolerance,
        bytes calldata _addionalData,
        address _token
    )
        external
        view
        returns (ICalculations.WithdrawalEstimation memory);

    /**
     * @notice Calculates the total balance of the want token that belong to the startegy. It takes into account the
     *         strategy contract balance and any underlying protocol that holds the want tokens.
     * @return The total balance of the want token.
     */
    function balance() external view returns (uint256);

    /**
     * @notice Mapping to track the amount of shares owned by each user.
     * @return An amount of shares dedicated for a user.
     */
    function userShares(address user) external view returns (uint256);

    /**
     * @notice Mapping to check if a token is allowed for deposit (1 - allowed, 2 - not allowed).
     * @return A flag that indicates if the token is allowed for deposits or not.
     */
    function depositAllowedTokens(address token) external view returns (uint256);

    /**
     * @notice Mapping to check if a token is allowed for withdrawal (1 - allowed, 2 - not allowed).
     * @return A flag that indicates if the token is allowed for withdrawals or not.
     */
    function withdrawalAllowedTokens(address token) external view returns (uint256);

    /**
     * @notice Returns a list of tokens allowed for deposit.
     * @return A list of tokens allowed for deposit.
     */
    function listDepositAllowedTokens(uint256 index) external view returns (address);

    /**
     * @notice Returns a list of tokens allowed for withdrawal.
     * @return A list of tokens allowed for withdrawal.
     */
    function listWithdrawalAllowedTokens(uint256 index) external view returns (address);

    /**
     * @notice Returns an address of the AdminStructure contract.
     * @return An address of the AdminStructure contract.
     */
    function adminStructure() external view returns (IAdminStructure);

    /**
     * @notice Returns an address of the Strategy contract.
     * @return An address of the Strategy contract.
     */
    function strategy() external view returns (IStrategy);

    /**
     * @notice Returns an address of the WETH token contract.
     * @return An address of the WETH token contract.
     */
    function weth() external view returns (IWETH);

    /**
     * @notice Returns total number of shares across all users.
     * @return Total number of shares across all users.
     */
    function totalShares() external view returns (uint256);

    /**
     * @notice Returns calculation contract.
     * @return An address of the calculations contract.
     */
    function calculations() external view returns (ICalculations);
}
