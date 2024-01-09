// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (access/Ownable.sol)

pragma solidity ^0.8.0;

import "./Context.sol";

/**
 * @dev Contract module which provides a basic way to disable a smart contract 
 * forever. Unlike to a pausable functionality, a disabled smart contract can't 
 * be enable back. 
 *
 * By default, the owner account will be the one that deploys the contract. This
 * can later be changed with {transferOwnership}.
 *
 * This module is used through inheritance. It will make available the modifier
 * `isNotDisabled`, which can be applied to your functions to disable their.
 * 
 * It provides a virtual function `disable` which should be used to make a clean
 * up of the whole system previous disabling the smart contract
 *
 */
abstract contract Disabable is Context {
    bool private disabled = false;

    event Disabled();

    /**
     * @dev Initializes the contract setting the deployer as the initial owner.
     */
    constructor() {
    }

    /**
     * @dev Throws if disable is true
     */
    modifier isNotDisabled() {
        require(disabled == false, "Disabable: This contract is disabled");
        _;
    }

    /**
     * @dev Return the value of disabled
     */
     function isDisable() public view returns(bool){
         return disabled;
     }


    /**
     * @dev Disable the whole contract, functions that implements
     * `isNotDisabled()` modifier will revert .
     * 
     * Note: there is no way to enable a contract again (turning disabled = true)
     * so this operation is irreversible
     */
    function _disable() internal virtual isNotDisabled{
        disabled = true;
        emit Disabled();
    }
}
