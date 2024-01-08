// SPDX-License-Identifier: MIT
pragma solidity ^0.8.6;

import "./INiftyRegistry.sol";

abstract contract NiftyEntity {
    address internal immutable niftyRegistryContract;

    constructor(address _niftyRegistryContract) {
        niftyRegistryContract = _niftyRegistryContract;
    }

    /**
     * @dev Determines whether accounts are allowed to invoke state mutating operations on child contracts.
     */
    modifier onlyValidSender() {
        bool isValid = INiftyRegistry(niftyRegistryContract).isValidNiftySender(msg.sender);
        require(isValid, "unauthorized");
        _;
    }
}