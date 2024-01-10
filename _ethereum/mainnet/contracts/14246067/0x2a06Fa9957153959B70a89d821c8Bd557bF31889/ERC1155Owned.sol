//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.0;

import "./UInt256Set.sol";

import "./IERC1155Owned.sol";

// TODO write tests

/// @title ERC1155Owned
/// @notice a list of held tokens for a given token
contract ERC1155Owned is IERC1155Owned {

    // the uint set used to store the held tokens
    using UInt256Set for UInt256Set.Set;

    // lists of held tokens by user
    mapping(address => UInt256Set.Set) internal _owned;

    /// @notice Get all owned tokens
    /// @param account the owner
    /// @return ownedList all tokens for owner
    function owned(address account)
    external
    virtual
    view
    override
    returns (uint256[] memory ownedList) {
        ownedList = _owned[account].keyList;
    }

    /// @notice returns whether the address is in the list
    /// @param account address
    /// @param toCheck id of the token
    /// @return isOwned whether the address is in the list
    function isOwnerOf(address account, uint256 toCheck)
    external
    virtual
    view
    override
    returns (bool isOwned) {
        isOwned = _owned[account].exists(toCheck);
    }

    /// @notice add a token to an accound's owned list
    /// @param account address
    /// @param token id of the token
    function _addOwned(address account, uint256 token)
    internal {
        _owned[account].insert(token);
    }

}
