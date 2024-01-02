// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

/**************************************************************\
 * AdminPrivilegesFacet authored by Bling Artist Lab
 * Version 0.1.0
 * 
 * Adheres to ERC-173
/**************************************************************/

import "./GlobalState.sol";

contract AdminPrivilegesFacet {
    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);
    
    /**
     * @dev Returns address of contract owner. Required by
     *      ERC-173.
     */
    function owner() public view returns (address) {
        return GlobalState.getState().owner;
    }

    /**
     * @dev Transfer ownership status of this smart contract to
     *      another address. Can only be called by the current
     *      owner.
     */
    function transferOwnership(address newOwner) external {
        address previousOwner = owner();
        require(
            msg.sender == previousOwner,
            "AdminPrivilegesFacet: caller must be contract owner"
        );

        GlobalState.getState().owner = newOwner;
        emit OwnershipTransferred(previousOwner, newOwner);
    }

    /**
     * @dev Returns true is the caller is the contract owner or
     *      an admin.
     */
    function isAdmin(address _addr) external view returns (bool) {
        return GlobalState.isAdmin(_addr);
    }

    /**
     * @dev Toggle admin status of a provided address.
     */
    function toggleAdmins(address[] calldata accounts) external {
        GlobalState.requireCallerIsAdmin();
        GlobalState.state storage _state = GlobalState.getState();

        for (uint256 i; i < accounts.length; i++) {
            if (_state.admins[accounts[i]]) {
                delete _state.admins[accounts[i]];
            } else {
                _state.admins[accounts[i]] = true;
            }
        }
    }
}