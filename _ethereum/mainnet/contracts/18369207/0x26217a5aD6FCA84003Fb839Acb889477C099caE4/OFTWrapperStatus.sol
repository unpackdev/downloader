// SPDX-License-Identifier: AGPL-3.0-only

pragma solidity 0.8.19;

/**
 * @title OFTWrapperStatus
 * @notice OFTWrapper events and custom errors
 */
interface OFTWrapperStatus {
    /**
     * @notice Emitted when the OFT sending function is invoked
     */
    event OftSent();

    /**
     * @notice Emitted when the caller is not the token sender
     */
    error SenderError();
}
