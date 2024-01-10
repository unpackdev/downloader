//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.0;

import "./AddressSet.sol";

import "./IERC1155Owners.sol";

// TODO write tests

/// @title ERC1155Owners
/// @notice a list of token holders for a given token
contract ERC1155Owners is IERC1155Owners {

    // the uint set used to store the held tokens
    using AddressSet for AddressSet.Set;

    // lists of held tokens by user
    mapping(uint256 => AddressSet.Set) internal _owners;

    /// @notice Get  all token holderd for a token id
    /// @param id the token id
    /// @return ownersList all token holders for id
    function ownersOf(uint256 id)
    external
    virtual
    view
    override
    returns (address[] memory ownersList) {
        ownersList = _owners[id].keyList;
    }

    /// @notice returns whether the address is in the list
    /// @return isOwner whether the address is in the list
    function isOwnedBy(uint256 id, address toCheck)
    external
    virtual
    view
    override
    returns (bool isOwner) {
        return _owners[id].exists(toCheck);
    }

    /// @notice add a token to an accound's owned list
    /// @param id address
    /// @param owner id of the token
    function _addOwner(uint256 id, address owner)
    internal {
        _owners[id].insert(owner);
    }

}
