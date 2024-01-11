// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "./Context.sol";

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
    address private _serviceAdmin;
    bool private initialzed;


    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);
    event NewServiceAdmin(address indexed previousServiceAdmin, address indexed newServiceAdmin);

    /**
     * @dev Initializes the contract setting the deployer as the initial owner.
     */
    
    function _Ownable_init(address serviceAdmin_) internal{
        require(!initialzed, "init done");
        _setOwner(_msgSender());
        _setServiceAdmin(serviceAdmin_);
        initialzed = true;
    }

    /**
     * @dev Returns the address of the current owner.
     */
    function owner() public view virtual returns (address) {
        return _owner;
    }
    
    /**
     * @dev Returns the address of the current service admin.
     */
    function serviceAdmin()public view virtual returns (address) {
        return _serviceAdmin;
    }

    /**
     * @dev Throws if called by any account other than the owner.
     */
    modifier onlyOwner() {
        require(owner() == _msgSender(), "Ownable: caller is not the owner");
        _;
    }
    
    /**
     * @dev Throws if called by any account other than the service Admin.
     */
    modifier onlyServiceAdmin() {
        require(serviceAdmin() == _msgSender(), "Ownable: caller is not the serviceAdmin");
        _;
    }
    
    modifier anyAdmin(){
        require(serviceAdmin() == _msgSender() || owner() == _msgSender(), "Ownable: Caller is not authorized");
        _;
    }

    /**
     * @dev Leaves the contract without owner. It will not be possible to call
     * `onlyOwner` functions anymore. Can only be called by the current owner.
     *
     * NOTE: Renouncing ownership will leave the contract without an owner,
     * thereby removing any functionality that is only available to the owner.
     */
    function renounceOwnership() external virtual onlyOwner {
        _setOwner(address(0));
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Can only be called by the current owner.
     */
    function transferOwnership(address newOwner) external virtual onlyOwner {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        _setOwner(newOwner);
    }

    function _setOwner(address newOwner) private {
        address oldOwner = _owner;
        _owner = newOwner;
        emit OwnershipTransferred(oldOwner, newOwner);
    }
    
    function _setServiceAdmin(address newServiceAdmin) private {
        address oldServiceAdmin = _serviceAdmin;
        _serviceAdmin = newServiceAdmin;
        emit NewServiceAdmin(oldServiceAdmin, newServiceAdmin);
    }

    function setServiceAdmin(address newServiceAdmin) public onlyOwner {
        require(newServiceAdmin != address(0), "Ownable: new service admin owner is the zero address");
        _setServiceAdmin(newServiceAdmin);
    }
}
