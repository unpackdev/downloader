//SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./EnumerableSet.sol";

/// @title ERC721WithMinters
/// @author Simon Fremaux (@dievardump)
abstract contract ERC721WithMinters {
    using EnumerableSet for EnumerableSet.AddressSet;

    /// @notice emitted when a new Minter is added
    /// @param minter the minter address
    event MinterAdded(address indexed minter);

    /// @notice emitted when a Minter is removed
    /// @param minter the minter address
    event MinterRemoved(address indexed minter);

    /// @dev This is used internally to allow an address to access the minting function or not
    EnumerableSet.AddressSet private minters;

    /// @notice Helper to know is an address is minter
    /// @param minter the address to check
    function isMinter(address minter) public view returns (bool) {
        return minters.contains(minter);
    }

    /// @notice Helper to list all minters
    /// @return list of minters
    function listMinters() external view returns (address[] memory list) {
        uint256 count = minters.length();
        list = new address[](count);
        for (uint256 i; i < count; i++) {
            list[i] = minters.at(i);
        }
    }

    /// @notice Helper for the owner to add new minter
    /// @param newMinter new signer
    function _addMinter(address newMinter) internal {
        minters.add(newMinter);
        emit MinterAdded(newMinter);
    }

    /// @notice Helper for the owner to remove a minter
    /// @param removedMinter minter to remove
    function _removeMinter(address removedMinter) internal {
        minters.remove(removedMinter);
        emit MinterRemoved(removedMinter);
    }
}
