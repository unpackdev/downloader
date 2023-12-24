// SPDX-License-Identifier: Apache-2.0
pragma solidity 0.8.17;

import "./ArbSys.sol";
import "./AddressAliasHelper.sol";

/**
 * @title Interface needed to call function activeOutbox of the Bridge
 */
interface IBridge {
    function activeOutbox() external view returns (address);
}

/**
 * @title Interface needed to call functions createRetryableTicket and bridge of the Inbox
 */
interface IInbox {
    function createRetryableTicket(
        address to,
        uint256 arbTxCallValue,
        uint256 maxSubmissionCost,
        address submissionRefundAddress,
        address valueRefundAddress,
        uint256 gasLimit,
        uint256 maxFeePerGas,
        bytes calldata data
    ) external payable returns (uint256);

    function bridge() external view returns (IBridge);
}

/**
 * @title Interface needed to call function l2ToL1Sender of the Outbox
 */
interface IOutbox {
    function l2ToL1Sender() external view returns (address);
}