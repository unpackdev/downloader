//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.0;

/// @notice implements a Janus (multifaced) registry. GLobal registry items can be set by specifying 0 for the registry face. Those global items are then available to all faces, and individual faces can override the global items for
interface IJanusRegistry {

    /// @notice Get the registro address given the face name. If the face is 0, the global registry is returned.
    /// @param face the face name or 0 for the global registry
    /// @param name uint256 of the token index
    /// @return item the service token record
    function get(string memory face, string memory name)
    external
    view
    returns (address item);

    /// @notice returns whether the service is in the list
    /// @param item uint256 of the token index
    function member(address item)
    external
    view
    returns (string memory face, string memory name);

}
