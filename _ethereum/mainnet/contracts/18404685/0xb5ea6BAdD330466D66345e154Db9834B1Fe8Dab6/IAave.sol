// SPDX-License-Identifier: MIT
pragma solidity 0.8.18;

import "./ILendingPoolV2.sol";
import "./ILendingPoolV3.sol";
import "./IWethGateway.sol";

/**
 * @title Aave proxy contract interface
 * @author Pino development team
 * @notice Deposits and Withdraws tokens to the lending pool
 */
interface IAave {
    /**
     * @notice Emitted when a token is deposited to the lending pool
     * @param _caller Address of the caller of the transaction
     * @param _recipient The recipient that received the aTokens
     * @param _token The underlying ERC20 token
     * @param _amount The amount of the ERC20 token
     */
    event Deposit(address _caller, address _recipient, address _token, uint256 _amount);

    /**
     * @notice Emitted when a token is withdrawn from the lending pool
     * @param _caller Address of the caller of the transaction
     * @param _recipient The recipient that received the tokens
     * @param _token The underlying ERC20 token
     * @param _amount The amount of the ERC20 token
     */
    event Withdraw(address _caller, address _recipient, address _token, uint256 _amount);

    /**
     * @notice Emitted when a token is repaid to the lending pool
     * @param _caller Address of the caller of the transaction
     * @param _recipient The recipient that received the repayment
     * @param _token The underlying ERC20 token
     * @param _amount The amount of the ERC20 token
     */
    event Repay(address _caller, address _recipient, address _token, uint256 _amount);

    /**
     * @notice Emitted when a token is borrowed from the lending pool
     * @param _callerAndDebtor Address of the caller of the transaction that will receive the debt
     * @param _token The underlying ERC20 token
     * @param _amount The amount of the ERC20 token
     * @param _rateMode The interest rate mode at which the user wants to borrow
     */
    event Borrow(address _callerAndDebtor, address _token, uint256 _amount, uint256 _rateMode);

    /**
     * @notice Deposits a token to the lending pool V2 and transfers aTokens to recipient
     * @param _token The underlying token to deposit
     * @param _amount Amount to deposit
     * @param _recipient Recipient of the deposit that will receive aTokens
     */
    function depositV2(address _token, uint256 _amount, address _recipient) external payable;

    /**
     * @notice Deposits a token to the lending pool V3 and transfers aTokens to recipient
     * @param _token The underlying token to deposit
     * @param _amount Amount to deposit
     * @param _recipient Recipient of the deposit that will receive aTokens
     */
    function depositV3(address _token, uint256 _amount, address _recipient) external payable;

    /**
     * @notice Receives aToken and transfers ERC20 token to recipient using lending pool V2
     * @param _token The underlying token to withdraw
     * @param _amount Amount to withdraw
     * @param _recipient Recipient to receive ERC20 tokens
     * @return withdrawn The amount withdrawn from the lending pool
     */
    function withdrawV2(address _token, uint256 _amount, address _recipient)
        external
        payable
        returns (uint256 withdrawn);

    /**
     * @notice Receives aToken and transfers ERC20 token to recipient using lending pool V3
     * @param _token The underlying token to withdraw
     * @param _amount Amount to withdraw
     * @param _recipient Recipient to receive ERC20 tokens
     * @return withdrawn The amount withdrawn from the lending pool
     */
    function withdrawV3(address _token, uint256 _amount, address _recipient)
        external
        payable
        returns (uint256 withdrawn);

    /**
     * @notice Receives A_WETH and transfers ETH token to recipient using lending pool V2
     * @param _amount Amount to withdraw
     * @param _recipient Recipient to receive ETH
     */
    function withdrawETHV2(uint256 _amount, address _recipient) external payable;

    /**
     * @notice Receives A_WETH and transfers ETH token to recipient using lending pool V3
     * @param _amount Amount to withdraw
     * @param _recipient Recipient to receive ETH
     */
    function withdrawETHV3(uint256 _amount, address _recipient) external payable;

    /**
     * @notice Repays a borrowed token using lending pool V2
     * @param _token The underlying token to repay
     * @param _amount Amount to repay
     * @param _rateMode Rate mode, 1 for stable and 2 for variable
     * @param _recipient Recipient to repay for
     * @return repaid The final amount repaid
     */
    function repayV2(address _token, uint256 _amount, uint256 _rateMode, address _recipient)
        external
        payable
        returns (uint256 repaid);

    /**
     * @notice Repays a borrowed token using lending pool V3
     * @param _token The underlying token to repay
     * @param _amount Amount to repay
     * @param _rateMode Rate mode, 1 for stable and 2 for variable
     * @param _recipient Recipient to repay for
     * @return repaid The final amount repaid
     */
    function repayV3(address _token, uint256 _amount, uint256 _rateMode, address _recipient)
        external
        payable
        returns (uint256 repaid);

    /**
     * @notice Borrows an specific amount of tokens on behalf of the caller from lendingPoolV2
     * @param _token The underlying token to borrow
     * @param _amount Amount to borrow
     * @param _rateMode The interest rate mode at which the user wants to borrow
     * @dev This action transfers the borrowed tokens to the proxy contract
     */
    function borrowV2(address _token, uint256 _amount, uint256 _rateMode) external payable;

    /**
     * @notice Borrows an specific amount of tokens on behalf of the caller from lendingPoolV3
     * @param _token The underlying token to borrow
     * @param _amount Amount to borrow
     * @param _rateMode The interest rate mode at which the user wants to borrow
     * @dev This action transfers the borrowed tokens to the proxy contract
     */
    function borrowV3(address _token, uint256 _amount, uint256 _rateMode) external payable;
}
