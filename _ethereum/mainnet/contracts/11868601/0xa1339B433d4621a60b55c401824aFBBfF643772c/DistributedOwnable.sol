// SPDX-License-Identifier: Apache 2.0
pragma solidity ^0.7.0;

import "./ECDSA.sol";
import "./Array.sol";


contract DistributedOwnable {
    using ECDSA for bytes32;
    using Array for address[];

    mapping (address => bool) private _owners;
    address[] private _ownersList;

    event OwnershipGranted(address indexed newOwner);
    event OwnershipRemoved(address indexed removedOwner);

    /**
     * @notice Check if account has ownership
     * @param checkAddr Address to be checked
     * @return Boolean status of the address
     */
    function isOwner(address checkAddr) public view returns (bool) {
        return _owners[checkAddr];
    }

    /**
     * @notice Get the list of owners
     * @return List of addresses
     */
    function getOwners() public view returns(address[] memory) {
        return _ownersList;
    }

    /**
     * @dev Handy wrapper for Solidity recover function. Returns signature author address.
     * @param payload - payload which was signed
     * @param signature - payload signature
    */
    function recoverSignature(
        bytes memory payload,
        bytes memory signature
    ) public pure returns(address) {
        return keccak256(payload).toBytesPrefixed().recover(signature);
    }

    /**
     * @dev Internal ownership granting.
     * @param newOwner - Account to grant ownership
    */
    function grantOwnership(address newOwner) internal {
        require(!_owners[newOwner], 'Already owner');

        _owners[newOwner] = true;
        _ownersList.push(newOwner);

        emit OwnershipGranted(newOwner);
    }

    /**
     * @dev Internal ownership removing.
     * @param ownerToRemove - Account to remove ownership
    */
    function removeOwnership(address ownerToRemove) internal {
        require(_owners[ownerToRemove], 'Not an owner');

        _owners[ownerToRemove] = false;
        _ownersList.removeByValue(ownerToRemove);

        emit OwnershipRemoved(ownerToRemove);
    }
}
