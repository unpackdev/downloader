// SPDX-License-Identifier: MIT
pragma solidity ^0.8.7;

/**
 * @dev Adds functionality for admins to controll a contract, similar to Ownable but more verbose
 */

contract OwnerController {
    /// @dev Same as Ownable, the owner is the wallet who minted the contract, usually AA or the artist
    address private _owner;
    /**
     * @dev the underlying owner is not the response of "owner()"
     * but is used to allow taking actions on behalf of the owner at any given time,
     * this is usually Avant Arte's main wallet - and will never change even if ownership is transfered
     */
    address private _underlyingOwner;

    event OwnershipTransferred(
        address indexed previousOwner,
        address indexed newOwner
    );

    constructor(address _underlyingOwnerAddress) {
        _owner = msg.sender;
        _underlyingOwner = _underlyingOwnerAddress;
    }

    /// @dev makes sure the address is the contract owner
    modifier onlyOwner() {
        require(isOwner(), "not owner");
        _;
    }

    /// @dev Returns the address of the current owner.
    function owner() external view virtual returns (address) {
        return _owner;
    }

    /// @dev renounce the ownership for the contract and leave it with no owner
    function renounceOwnership() external virtual onlyOwner {
        _transferOwnership(address(0));
    }

    /// @dev safely transfer ownership to a new owner
    function transferOwnership(address newOwner) external virtual onlyOwner {
        require(newOwner != address(0), "new owner is zero address");
        _transferOwnership(newOwner);
    }

    /// @dev unsafe internal transfer ownership
    function _transferOwnership(address newOwner) internal virtual {
        address oldOwner = _owner;
        _owner = newOwner;
        emit OwnershipTransferred(oldOwner, newOwner);
    }

    /// @dev checks if the sender is an owner
    function isOwner() internal view virtual returns (bool) {
        return _underlyingOwner == msg.sender || _owner == msg.sender;
    }
}
