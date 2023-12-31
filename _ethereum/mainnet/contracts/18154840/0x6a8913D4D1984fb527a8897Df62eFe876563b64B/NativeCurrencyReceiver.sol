// SPDX-License-Identifier: GPL-3.0
pragma solidity >=0.8.0 <0.9.0;

/**
 * @title NativeCurrencyReceiver
 * @notice Implementation to receive native currency payments.
 */
abstract contract NativeCurrencyReceiver {
    event NativeCurrencyReceived(address indexed sender, uint256 value);

    /**
     * @notice Receive native currency payment and emit an event.
     */
    receive() external payable {
        emit NativeCurrencyReceived(msg.sender, msg.value);
    }
}