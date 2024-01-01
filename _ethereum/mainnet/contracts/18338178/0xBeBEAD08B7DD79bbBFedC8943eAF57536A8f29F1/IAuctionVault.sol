// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.0;

/**
 * @notice Interface for the abstract auction vault contract which handles both cash and physical settlement
 *         used only in the settlement contracts to provide compatibility between the vault interfaces
 */

interface IAuctionVault {
    /// @notice verifies the options are allowed to be minted
    /// @param _options to mint
    function verifyOptions(uint256[] calldata _options) external view;
}
