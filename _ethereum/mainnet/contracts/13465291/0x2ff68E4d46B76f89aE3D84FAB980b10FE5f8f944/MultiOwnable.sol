// SPDX-License-Identifier: MIT

pragma solidity ^0.8.4;

/// @author jpegmint.xyz

import "./IOwnable.sol";
import "./Context.sol";
import "./ERC165.sol";

abstract contract MultiOwnable is Context, IOwnable, ERC165 {

    /// VARIABLES ///
    address[] private _owners;

    /// MAPPINGS ///
    mapping(address => uint256) private _ownersIndex;
    
    /**
     * @dev Initializes the contract setting the deployer as the initial owner.
     */
    constructor() {
        _pushOwner(_msgSender());
    }

    /**
     * @dev see {IERC165-supportsInterface}
     */
    function supportsInterface(bytes4 interfaceId) public view virtual override returns (bool) {
        return
            interfaceId == type(IOwnable).interfaceId ||
            super.supportsInterface(interfaceId)
        ;
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
    function owner() public view virtual override returns (address) {
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
    function renounceOwnership() public virtual override onlyOwner {

        address oldOwner = owner();

        for (uint256 i = 0; i < _owners.length; i++) {
            delete _ownersIndex[_owners[i]];
        }

        delete _owners;

        emit OwnershipTransferred(oldOwner, address(0));
    }

    /**
     * @dev Transfers primary ownership of the contract to specified address.
     */
    function transferOwnership(address newOwner) public virtual override onlyOwner {
        require(newOwner != address(0), "Ownable: new owner is the zero address");

        uint256 checkIndex = _ownersIndex[newOwner];

        // If not already owner in spot 0...
        if (!isOwner(newOwner) || checkIndex != 0) {

            address oldOwner = _owners[0];
            
            // Insert new owner at front.
            _owners[0] = newOwner;
            _ownersIndex[newOwner] = 0;

            // Push old to end if new owner, otherwise swap with existing owner.
            if (checkIndex == 0) {
                _pushOwner(oldOwner);
            } else {
                _owners[checkIndex] = oldOwner;
                _ownersIndex[oldOwner] = checkIndex;
            }

            emit OwnershipTransferred(oldOwner, newOwner);
        }
    }
}
