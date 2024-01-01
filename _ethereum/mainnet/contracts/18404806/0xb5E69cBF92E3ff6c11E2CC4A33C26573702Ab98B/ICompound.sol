// SPDX-License-Identifier: MIT
pragma solidity 0.8.18;

import "./ICToken.sol";

/**
 * @title Compound V2/V3 proxy
 * @author Pino development team
 * @notice Calls Compound V2/V3 functions
 */
interface ICompound {
    /**
     * @notice Emitted when a token is deposited to the Compound V2 protocol
     * @param _caller Address of the caller of the transaction
     * @param _recipient The recipient that received the cTokens
     * @param _cToken Address of the cToken
     * @param _amount Amount of the underlying token
     */
    event Deposit(address _caller, address _recipient, address _cToken, uint256 _amount);

    /**
     * @notice Emitted when a token is deposited/repaid to the Compound V3 protocol
     * @param _caller Address of the caller of the transaction
     * @param _recipient The recipient that received the deposited amount
     * @param _token Address of the underlying token
     * @param _amount Amount of the underlying token
     */
    event DepositV3(address _caller, address _recipient, address _token, uint256 _amount);

    /**
     * @notice Emitted when a token is repaid to the Compound V2 protocol
     * @param _caller Address of the caller of the transaction
     * @param _recipient The recipient that received the repaid amount
     * @param _cToken Address of the cToken
     * @param _amount Amount of the underlying token
     */
    event Repay(address _caller, address _recipient, address _cToken, uint256 _amount);

    /**
     * @notice Emitted when a token is withdrawn from the Compound V2 protocol
     * @param _caller Address of the caller of the transaction
     * @param _recipient The recipient that received the withdrawn amount
     * @param _cToken Address of the cToken
     * @param _amount Amount of the underlying token
     */
    event Withdraw(address _caller, address _recipient, address _cToken, uint256 _amount);

    /**
     * @notice Emitted when a token is withdrawn/borrowed from the Compound V3 protocol
     * @param _caller Address of the caller of the transaction
     * @param _recipient The recipient that received the withdrawn/borrowed amount
     * @param _token Address of the underlying token
     * @param _amount Amount of the underlying token
     */
    event WithdrawV3(address _caller, address _recipient, address _token, uint256 _amount);

    /**
     * @notice Thrown when the Compound V2 cToken returns a non-zero value
     * @param _caller Address of the caller of the transaction
     * @param _errorCode The non-zero error code
     */
    error CompoundCallFailed(address _caller, uint256 _errorCode);

    /**
     * @notice Deposits ERC20 to the Compound protocol and transfers cTokens to the recipient
     * @param _amount Amount to deposit
     * @param _cToken Address of the cToken to receive
     * @param _recipient The destination address that will receive cTokens
     */
    function depositV2(uint256 _amount, ICToken _cToken, address _recipient) external payable;

    /**
     * @notice Deposits ETH to the Compound protocol and transfers cEther to the recipient
     * @param _recipient The destination address that will receive cEther
     * @param _proxyFeeInWei Fee of the proxy contract
     */
    function depositETHV2(address _recipient, uint256 _proxyFeeInWei) external payable;

    /**
     * @notice Deposits WETH, converts it to ETH and mints CEther for the recipient
     * @param _amount The amount of WETH to deposit
     * @param _recipient The destination address that will receive CEther
     */
    function depositWETHV2(uint256 _amount, address _recipient) external payable;

    /**
     * @notice Deposits cTokens back to the Compound protocol and
     * receives underlying ERC20 tokens and transfers it to the recipient
     * @param _amount Amount to withdraw
     * @param _cToken Address of the cToken
     * @param _recipient The destination that will receive the underlying token
     */
    function withdrawV2(uint256 _amount, ICToken _cToken, address _recipient) external payable;

    /**
     * @notice Deposits CEther back the the Compound protocol and receives ETH and transfers it to the recipient
     * @param _amount Amount to withdraw
     * @param _recipient The destination address that will receive ETH
     */
    function withdrawETHV2(uint256 _amount, address _recipient) external payable;

    /**
     * @notice Deposits CEther back the the Compound protocol and receives ETH and transfers WETH to the recipient
     * @param _amount Amount to withdraw
     * @param _recipient The destination address that will receive WETH
     */
    function withdrawWETHV2(uint256 _amount, address _recipient) external payable;

    /**
     * @notice Repays a borrowed token on behalf of the recipient
     * @param _cToken Address of the cToken
     * @param _amount Amount to repay
     * @param _recipient The address of the recipient
     */
    function repayV2(ICToken _cToken, uint256 _amount, address _recipient) external payable;

    /**
     * @notice Repays ETH on behalf of the recipient
     * @param _recipient The address of the recipient
     * @param _proxyFeeInWei Fee of the proxy contract
     */
    function repayETHV2(address _recipient, uint256 _proxyFeeInWei) external payable;

    /**
     * @notice Repays ETH on behalf of the recipient but receives WETH from the caller
     * @param _amount The amount of WETH to repay
     * @param _recipient The address of the recipient
     */
    function repayWETHV2(uint256 _amount, address _recipient) external payable;

    /**
     * @notice Deposits ERC20 tokens to the Compound protocol on behalf of the recipient
     * @param _token The underlying ERC20 token
     * @param _amount Amount to deposit
     * @param _recipient The address of the recipient
     */
    function depositV3(address _token, uint256 _amount, address _recipient) external payable;

    /**
     * @notice Withdraws an ERC20 token and transfers it to the recipient
     * @param _token The underlying ERC20 token to withdraw
     * @param _amount Amount to withdraw
     * @param _recipient The address of the recipient
     */
    function withdrawV3(address _token, uint256 _amount, address _recipient) external payable;
}
