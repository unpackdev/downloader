// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.0;

interface IAuctionVault {
    /// @notice verifies the options are allowed to be minted
    /// @param _options to mint
    function verifyOptions(uint256[] calldata _options) external view;
}
