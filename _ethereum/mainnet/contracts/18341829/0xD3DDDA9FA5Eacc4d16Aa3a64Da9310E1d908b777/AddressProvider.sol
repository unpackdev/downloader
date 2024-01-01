// SPDX-License-Identifier: MIT
pragma solidity 0.8.19;

import "./Ownable.sol";

/// @title Cyan AddressProvider contract
/// @author Bulgantamir Gankhuyag - <bulgaa@usecyan.com>
/// @author Naranbayar Uuganbayar - <naba@usecyan.com>
contract AddressProvider is Ownable {
    event AddressSet(bytes32 id, address newAddress);

    mapping(bytes32 => address) public addresses;

    constructor(address owner) {
        transferOwnership(owner);
    }

    // @dev Sets an address for an id replacing the address saved in the addresses map
    // @param id The id
    // @param newAddress The address to set
    function setAddress(bytes32 id, address newAddress) external onlyOwner {
        addresses[id] = newAddress;
        emit AddressSet(id, newAddress);
    }
}
