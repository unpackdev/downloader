// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;

import "./Initializable.sol";

abstract contract Ownable is Initializable {

    error OwnableUnauthorizedAccount(address account, address owner);
    error OwnableInvalidOwner(address account);

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    address internal _owner;
    /// @custom:oz-upgrades-unsafe-allow constructor
    constructor() {
        _disableInitializers();
    }

    function __Ownable_init(address __owner) internal onlyInitializing {
        _transferOwnership(__owner);
    }

    function owner() public view returns (address) {
        return _owner;
    }

    /**
     * @dev Throws if called by any account other than the owner.
     */
    modifier onlyOwner() {
        _checkOwner();
        _;
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Can only be called by the current owner.
     */
    function transferOwnership(address newOwner) public onlyOwner {
        if (newOwner == address(0)) {
            revert OwnableInvalidOwner(address(0));
        }
        _transferOwnership(newOwner);
    }
    /**
    * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Internal function without access restriction.
     */
    function _transferOwnership(address newOwner) internal {
        address oldOwner = _owner;
        _owner = newOwner;
        emit OwnershipTransferred(oldOwner, newOwner);
    }

    /**
     * @dev Throws if the sender is not the owner.
     */
    function _checkOwner() internal view {
        if (owner() != msg.sender) {
            revert OwnableUnauthorizedAccount(msg.sender, _owner);
        }
    }
}
