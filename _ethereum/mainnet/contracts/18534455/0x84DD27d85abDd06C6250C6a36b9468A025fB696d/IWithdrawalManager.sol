// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

/**
 * @title IWithdrawalManager
 * @notice WithdrawalManager is used for mass transfer of ERC20 tokens and ETH to different addresses
 */
interface IWithdrawalManager {
    /**
     * @notice Structure representing token send information
     * @param tokenAddr The address of the token to be sent
     * @param recipientsArr The array of recipient addresses to receive the tokens
     * @param valuesArr The array of token values to be sent to each recipient
     */
    struct TokenSendInfo {
        address tokenAddr;
        address[] recipientsArr;
        uint256[] valuesArr;
    }

    error WithdrawalManagerArraysLengthMismatch();
    error WithdrawalManagerZeroRecipientAddress();
    error WithdrawalManagerNotEnoungETHForTransfer(uint256 amountToTransfer);
    error WithdrawalManagerFailedToTransferETH();

    /**
     * @notice Perform a mass send of ERC 20 tokens and ETH to multiple recipients
     * @dev To transfer ETH, it is necessary to pass a null address as the address of the token.
     * Also, the transaction value must exactly match the amount of native currency to be sent
     * @param tokenSendInfoArr_ The array of TokenSendInfo structs representing the token send information for each token
     */
    function massTokensSend(TokenSendInfo[] calldata tokenSendInfoArr_) external payable;
}
