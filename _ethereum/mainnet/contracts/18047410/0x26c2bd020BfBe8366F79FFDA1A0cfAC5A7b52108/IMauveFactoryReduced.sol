// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity >=0.5.0;

/// @title The interface for Mauve Factory (reduced version)
/// @notice Mauve Factory facilitates creation of Mauve pools and control over the protocol fees
interface IMauveFactoryReduced {
    /// @notice Returns the current address registered as a role on the factory
    /// @dev Can be called by anyone
    /// @param roleKey The selected role to be retrieved from the factory
    /// @return The address of the respective roleKey
    function roles(bytes32 roleKey) external view returns (address);

    /// @notice Returns the currently approved VioletID tokens to interact with Mauve
    /// @dev This defines the set of VioletID tokens that are used by Mauve to authorize
    /// certain interactions. More specifically, an account must own at least one of these tokens to
    /// become the owner of a LP NFT via transfer or withdraw funds in case
    /// the emergency mode is activated.
    /// @return The list of VioletID tokens that are accepted
    function getMauveTokenIdsAllowedToInteract() external view returns (uint256[] memory);
}
