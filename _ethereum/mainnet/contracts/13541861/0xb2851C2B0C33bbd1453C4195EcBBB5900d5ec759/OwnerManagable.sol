// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.7.0;

import "./AddressSet.sol";
import "./Claimable.sol";

contract OwnerManagable is Claimable, AddressSet {
    bytes32 internal constant MINTER = keccak256("__MINTERS__");
    bytes32 internal constant RETIREDMINTER = keccak256("__RETIREDMINTERS__");
    bytes32 internal constant UPDATER = keccak256("__UPDATER__");

    event MinterAdded(address indexed minter);
    event MinterRetired(address indexed minter);
    event UpdaterAdded(address indexed updater);
    event UpdaterRemoved(address indexed updater);

    // All address that are currently authorized to mint NFTs on L2.
    function activeMinters() public view returns (address[] memory) {
        return addressesInSet(MINTER);
    }

    // All address that were previously authorized to mint NFTs on L2.
    function retiredMinters() public view returns (address[] memory) {
        return addressesInSet(RETIREDMINTER);
    }

    // All address that are authorized to add new collections.
    function updaters() public view returns (address[] memory) {
        return addressesInSet(UPDATER);
    }

    function numActiveMinters() public view returns (uint256) {
        return numAddressesInSet(MINTER);
    }

    function numRetiredMinters() public view returns (uint256) {
        return numAddressesInSet(RETIREDMINTER);
    }

    function numUpdaters() public view returns (uint256) {
        return numAddressesInSet(UPDATER);
    }

    function isActiveMinter(address addr) public view returns (bool) {
        return isAddressInSet(MINTER, addr);
    }

    function isRetiredMinter(address addr) public view returns (bool) {
        return isAddressInSet(RETIREDMINTER, addr);
    }

    function isUpdater(address addr) public view returns (bool) {
        return isAddressInSet(UPDATER, addr);
    }

    function addActiveMinter(address minter) public virtual onlyOwner {
        addAddressToSet(MINTER, minter, true);
        if (isRetiredMinter(minter)) {
            removeAddressFromSet(RETIREDMINTER, minter);
        }
        emit MinterAdded(minter);
    }

    function addUpdater(address updater) public virtual onlyOwner {
        addAddressToSet(UPDATER, updater, true);
        emit UpdaterAdded(updater);
    }

    function removeUpdater(address updater) public virtual onlyOwner {
        removeAddressFromSet(UPDATER, updater);
        emit UpdaterRemoved(updater);
    }

    function retireMinter(address minter) public virtual onlyOwner {
        removeAddressFromSet(MINTER, minter);
        addAddressToSet(RETIREDMINTER, minter, true);
        emit MinterRetired(minter);
    }
}
