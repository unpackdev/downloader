// SPDX-License-Identifier: MIT
pragma solidity >=0.7.5;

/// @title A reduced VioletID interface
/// @notice Allows checking for VioletID statuses
/// @dev Make sure to keep this in sync with the interface from @violetprotocol/violetid!
interface IVioletIDReduced {
    function hasStatus(address account, uint8 tokenId) external view returns (bool);
}
