// SPDX-License-Identifier: MIT

pragma solidity ^0.8.4;

/// @author jpegmint.xyz

import "./Context.sol";

abstract contract MultiOwnable is Context {

    /// VARIABLES ///
    address[] private _owners;
    mapping(address => uint256) private _ownersIndex;

    /// EVENTS ///
    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);
    
    /**
     * @dev Initializes the contract setting the deployer as the initial owner.
     */
    constructor() {
        _pushOwner(_msgSender());
    }

    /**
     * @dev Only allows approved owners to call the specified function
     */
    modifier onlyOwner() {
        require(isOwner(_msgSender()), "Ownable: caller is not the owner");
        _;
    }

    /**
     * @dev Returns the address of the first owner.
     */
    function owner() public view virtual returns (address) {
        return _owners.length > 0 ? _owners[0] : address(0);
    }

    /**
     * @dev Checks if address is an approved owner.
     */
    function isOwner(address ownerAddress) public view returns (bool) {
        uint256 checkIndex = _ownersIndex[ownerAddress];
        return _owners.length > 0 && _owners[checkIndex] == ownerAddress;
    }

    /**
     * @dev Returns current list of owners.
     */
    function getOwners() external view returns (address[] memory admins) {
        return _owners;
    }

    /**
     * @dev Adds owners to list of owners.
     */
    function approveOwner(address newOwner) public onlyOwner {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        _pushOwner(newOwner);
    }

    function _pushOwner(address newOwner) internal {
        require(!isOwner(newOwner), 'MultiOwnable: Already an owner');
        _ownersIndex[newOwner] = _owners.length;
        _owners.push(newOwner);
    }

    /**
     * @dev Removes owner from list of owners.
     */
    function revokeOwner(address ownerAddress) public onlyOwner {
        _removeOwner(ownerAddress);
    }

    function _removeOwner(address ownerAddress) internal {
        require(isOwner(ownerAddress), 'MultiOwnable: Not an owner');

        uint256 removeIndex = _ownersIndex[ownerAddress];
        address lastOwner = _owners[_owners.length - 1];

        _owners[removeIndex] = lastOwner;
        _ownersIndex[lastOwner] = removeIndex;

        delete _ownersIndex[ownerAddress];
        _owners.pop();
    }

    /**
     * @dev Leaves the contract without owner. It will not be possible to call
     * `onlyOwner` functions anymore. Can only be called by the current owner.
     */
    function renounceOwnership() public virtual onlyOwner {

        address oldOwner = owner();

        for (uint256 i = 0; i < _owners.length; i++) {
            _removeOwner(_owners[i]);
        }

        emit OwnershipTransferred(oldOwner, address(0));
    }

    /**
     * @dev Transfers primary ownership of the contract to specified address.
     * Can only be called by the current owner.
     */
    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(newOwner != address(0), "Ownable: new owner is the zero address");

        address oldOwner = _owners[0];
        uint256 checkIndex = _ownersIndex[newOwner];
        bool isExistingOwner = _owners[checkIndex] == newOwner;

        // Insert at front. If not an owner, push old to end. Otherwise swap.
        _owners[0] = newOwner;
        _ownersIndex[newOwner] = 0;

        if (!isExistingOwner) {
            _pushOwner(oldOwner);
        } else {
            _owners[checkIndex] = oldOwner;
            _ownersIndex[oldOwner] = checkIndex;
        }

        emit OwnershipTransferred(oldOwner, newOwner);
    }
}
