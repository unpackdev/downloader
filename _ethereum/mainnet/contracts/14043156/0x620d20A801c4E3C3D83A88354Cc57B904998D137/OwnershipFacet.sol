// SPDX-License-Identifier: MIT
pragma solidity 0.8.10;

/******************************************************************************\
* Author: Nick Mudge <nick@perfectabstractions.com> (https://twitter.com/mudgen)
* EIP-2535 Diamond Standard: https://eips.ethereum.org/EIPS/eip-2535
/******************************************************************************/

import "./LibOwnership.sol";
import "./IERC173.sol";

contract OwnershipFacet is IERC173 {
    /// @notice Set the address of the new owner of the contract
    /// @dev Set _newOwner to address(0) to renounce any ownership.
    /// @param _newOwner The address of the new owner of the contract
    function transferOwnership(address _newOwner) external override {
        LibOwnership.enforceIsContractOwner();
        LibOwnership.setContractOwner(_newOwner);
    }

    /// @notice Get the address of the owner
    /// @return owner_ The address of the owner.
    function owner() external view override returns (address owner_) {
        owner_ = LibOwnership.contractOwner();
    }
}
