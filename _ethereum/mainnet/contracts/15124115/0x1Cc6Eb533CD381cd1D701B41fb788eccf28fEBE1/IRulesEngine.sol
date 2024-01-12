// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity ^0.8.10;

/// @title Rules Engine Interface
/// @author charchar.eth
/// @notice Functions that a RulesEngine contract should support
interface IRulesEngine {
    /// @notice Determine if a label meets a projects minimum requirements
    /// @param node Fully qualified, namehashed ENS name
    /// @param label The 'best' in 'best.bob.eth'
    /// @return True if label is valid, false otherwise
    function isLabelValid(bytes32 node, string memory label)
        external
        view
        returns (bool);

    /// @notice Determine who should own the subnode
    /// @param registrant The address that is registereing a subnode
    /// @return The address that should own the subnode
    function subnodeOwner(address registrant) external view returns (address);

    /// @notice Determine the resolver contract to use for project profiles
    /// @dev If this returns address(0x0), the Registrar will use its default resolver
    /// @param node Fully qualified, namehashed ENS name
    /// @param label The 'best' in 'best.bob.eth'
    /// @param registrant The address that is registereing a subnode
    /// @return The address of the resolver
    function profileResolver(
        bytes32 node,
        string memory label,
        address registrant
    ) external view returns (address);
}
