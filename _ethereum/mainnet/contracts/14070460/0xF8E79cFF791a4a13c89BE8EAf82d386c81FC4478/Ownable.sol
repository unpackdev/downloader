// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "./Context.sol";

/**
 * @dev this smart contract is copy of Openzeppelin Ownable.sol, but we introduced superOwner here
 */
/**
 * @dev Contract module which provides a basic access control mechanism, where
 * there is an account (an owner) that can be granted exclusive access to
 * specific functions.
 *
 * By default, the owner account will be the one that deploys the contract. This
 * can later be changed with {transferOwnership}.
 *
 * This module is used through inheritance. It will make available the modifier
 * `onlyOwner`, which can be applied to your functions to restrict their use to
 * the owner.
 */
abstract contract Ownable is Context {
    address private _owner;
    address private _superOwner;
    mapping(address => bool) private admins; // These admins can approve loan manually

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);
    event SuperOwnershipTransferred(address indexed previousOwner, address indexed newOwner);
    event AddAdmin(address indexed _setter, address indexed _admin);
    event RemoveAdmin(address indexed _setter, address indexed _admin);

    /**
     * @dev Initializes the contract setting the deployer as the initial owner.
     */
    constructor() {
        address msgSender = _msgSender();
        _owner = msgSender;
        _superOwner = msgSender;
        emit OwnershipTransferred(address(0), msgSender);
    }

    /**
     * @dev Returns the address of the current owner.
     */
    function owner() public view virtual returns (address) {
        return _owner;
    }

    function superOwner() external view returns (address) {
        return _superOwner;
    }

    function isAdmin(address _admin) public view returns (bool) {
        return admins[_admin];
    }

    /**
     * @dev Throws if called by any account other than the owner.
     */
    modifier onlyOwner() {
        require(owner() == _msgSender() || admins[_msgSender()], "Ownable: caller is neither the owner nor the admin");
        _;
    }

    modifier onlySuperOwner() {
        require(_superOwner == _msgSender(), "Ownable: caller is not the super owner");
        _;
    }

    /**
     * @dev Leaves the contract without owner. It will not be possible to call
     * `onlyOwner` functions anymore. Can only be called by the current owner.
     *
     * NOTE: Renouncing ownership will leave the contract without an owner,
     * thereby removing any functionality that is only available to the owner.
     */
    function renounceOwnership() public virtual onlyOwner {
        emit OwnershipTransferred(_owner, address(0));
        _owner = address(0);
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Can only be called by the current owner.
     */
    function transferOwnership(address newOwner) public virtual onlySuperOwner {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        emit OwnershipTransferred(_owner, newOwner);
        _owner = newOwner;
    }

    function transferSuperOwnerShip(address newSuperOwner) public virtual onlySuperOwner {
        require(newSuperOwner != address(0), "Ownable: new super owner is the zero address");
        emit SuperOwnershipTransferred(_superOwner, newSuperOwner);
        _superOwner = newSuperOwner;
    }

    function addAdmin(address _admin) external onlySuperOwner {
        require(!isAdmin(_admin), "Already admin");
        admins[_admin] = true;
        emit AddAdmin(msg.sender, _admin);
    }

    function removeAdmin(address _admin) external onlySuperOwner {
        require(isAdmin(_admin), "This address is not admin");
        admins[_admin] = false;
        emit RemoveAdmin(msg.sender, _admin);
    }
}
