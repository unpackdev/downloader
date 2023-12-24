//SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./Owned.sol";

/// @author 0xtekgrinder
/// @title Owned2Step contract
/// @notice Simple single owner authorization mixin with 2 step transfer ownership
abstract contract Owned2Step is Owned {
    /*//////////////////////////////////////////////////////////////
                                 EVENTS
    //////////////////////////////////////////////////////////////*/

    event OwnershipTransferStarted(address indexed user, address indexed newOwner);

    /*//////////////////////////////////////////////////////////////
                            OWNERSHIP STORAGE
    //////////////////////////////////////////////////////////////*/

    address public pendingOwner;

    /*//////////////////////////////////////////////////////////////
                               MODIFIERS
    //////////////////////////////////////////////////////////////*/

    modifier onlyPendingOwner() {
        require(pendingOwner == msg.sender, "UNAUTHORIZED");

        _;
    }

    /*//////////////////////////////////////////////////////////////
                               CONSTRUCTOR
    //////////////////////////////////////////////////////////////*/

    constructor(address _owner) Owned(_owner) { }

    /*//////////////////////////////////////////////////////////////
                             OWNERSHIP LOGIC
    //////////////////////////////////////////////////////////////*/

    /**
     * @dev Starts the ownership transfer of the contract to a new account.
     * @dev Can only be called by the current owner.
     */
    function transferOwnership(address newOwner) public virtual override onlyOwner {
        pendingOwner = newOwner;

        emit OwnershipTransferStarted(owner, newOwner);
    }

    /**
     * @dev The new owner accepts the ownership transfer.
     */
    function acceptOwnership() public virtual onlyPendingOwner {
        delete pendingOwner;
        super.transferOwnership(msg.sender);
    }
}
