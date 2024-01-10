// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "./IERC173.sol";

/**
 * @title ERC173 Contract
 *
 * @dev Implementation of the ERC173 standard
 */
contract ERC173 is IERC173 {
    /**
     * @dev ERC173 definitions
     */

    address private _owner;

    /**
     * @dev Prevents function called by non-owner from executing
     */

    modifier ownership() {
        require(owner() == msg.sender, "ERC173: caller is not the owner");

        _;
    }

    /**
     * @dev Sets the deployer as the initial owner
     */

    constructor(address owner_) {
        _transferOwnership(owner_);
    }

    /**
     * @dev ERC173 functions
     */

    function owner() public view virtual override returns (address) {

        return _owner;
    }

    function transferOwnership(address _newOwner) public virtual override ownership {
        _transferOwnership(_newOwner);
    }

    /**
     * @dev ERC173 internal function
     */
    
    function _transferOwnership(address _newOwner) internal virtual {
        address previousOwner = _owner;
        _owner = _newOwner;
    
        emit OwnershipTransferred(previousOwner, _newOwner);
    }
}
