// SPDX-License-Identifier: MIT

pragma solidity >=0.8.4 <0.9.0;

import "./Errors.sol";

/**
 * @dev Contract module which provides a basic access control mechanism, where
 * there are two accounts (an owner and a proxy) that can be granted exclusive
 * access to specific functions. Only the owner can set the proxy.
 *
 * By default, the owner account will be the one that deploys the contract. This
 * can later be changed with {transferOwnership}.
 *
 * This module is used through inheritance. It will make available the modifier
 * `onlyOwner`, which can be applied to your functions to restrict their use to
 * the owner.
 */
abstract contract AuctionOwnable {
    address private _owner;
    address private _auctioneer;
    address private _broker;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

	constructor() {
        _setOwner(msg.sender);
    }

    /**
     * @dev Returns the address of the current owner.
     */
    function owner() public view virtual returns (address) {
        return _owner;
    }

    // /**
    //  * @dev Returns the address of the current auctioneer.
    //  */
    // function auctioneer() public view virtual returns (address) {
    //     return _auctioneer;
    // }

    // /**
    //  * @dev Returns the address of the current broker.
    //  */
    // function broker() public view virtual returns (address) {
    //     return _broker;
    // }

    /**
     * @dev Returns true if the account has the auctioneer role.
     */

    function isAuctioneer(address account) public view virtual returns (bool) {
        return account == _auctioneer;
    }

    /**
     * @dev Returns true if the account has the broker role.
     */

    function isBroker(address account) public view virtual returns (bool) {
        return account == _broker;
    }

    /**
     * @dev Throws if called by any account other than the owner.
     */
    modifier onlyOwner() {
        if (_owner != msg.sender) revert Errors.UserPermissions();
        _;
    }

    /**
     * @dev Throws if called by any account other than the auctioneer.
     */
    modifier onlyAuctioneer() {
        if (
            _auctioneer != msg.sender
            && _owner != msg.sender
        ) revert Errors.UserPermissions();
        _;
    }

    /**
     * @dev Throws if called by any account other than the broker.
     */
    modifier onlyBroker() {
        if (
            _broker != msg.sender
            && _owner != msg.sender
        ) revert Errors.UserPermissions();
        _;
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Can only be called by the current owner.
     */
    function transferOwnership(address newOwner) public virtual onlyOwner {
        if (newOwner == address(0)) revert Errors.AddressTarget(newOwner);
        _setOwner(newOwner);
    }

    /**
     * @dev Sets the auctioneer for the contract to a new account (`newAuctioneer`).
     * Can only be called by the current owner.
     */
    function setAuctioneer(address newAuctioneer) public virtual onlyOwner {
        _auctioneer = newAuctioneer;
    }

    /**
     * @dev Sets the auctioneer for the contract to a new account (`newAuctioneer`).
     * Can only be called by the current owner.
     */
    function setBroker(address newBroker) public virtual onlyOwner {
        _broker = newBroker;
    }

    function _setOwner(address newOwner) internal {
        address oldOwner = _owner;
        _owner = newOwner;
        emit OwnershipTransferred(oldOwner, newOwner);
    }
}
