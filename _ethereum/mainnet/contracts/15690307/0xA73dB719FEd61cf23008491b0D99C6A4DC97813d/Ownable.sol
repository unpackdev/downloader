// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "./IOwnableInitializer.sol";
import "./Context.sol";

error CallerIsNotTheContractOwner();
error NewOwnerIsTheZeroAddress();
error OwnerAlreadyInitialized();

/**
 * @title Ownable
 * @author Limit Break, Inc. and OpenZeppelin
 * @notice A tailored version of the {Ownable}  permissions component from OpenZeppelin that is compatible with EIP-1167.
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
 *
 * This version adds an `initializeOwner` call for use with EIP-1167, 
 * as the constructor will not be called during an EIP-1167 operation.
 * Because initializeOwner should only be called once and requires that 
 * the owner is not assigned, the `renounceOwnership` function has been removed to avoid
 * a scenario where a contract takeover could occur.
 */
abstract contract Ownable is Context, IOwnableInitializer {
    address private _owner;

    /// @dev Emitted when contract ownership has been transferred.
    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    /**
     * @dev Initializes the contract setting the deployer as the initial owner.
     */
    constructor() {
        _transferOwnership(_msgSender());
    }

    /**
     * @dev Throws if called by any account other than the owner.
     */
    modifier onlyOwner() {
        _checkOwner();
        _;
    }

    /**
     * @dev When EIP-1167 is used to clone a contract that inherits Ownable permissions,
     * this is required to assign the initial contract owner, as the constructor is
     * not called during the cloning process.
     */
    function initializeOwner(address owner_) public override {
      if(_owner != address(0)) {
          revert OwnerAlreadyInitialized();
      }

      _transferOwnership(owner_);
    }

    /**
     * @dev Returns the address of the current owner.
     */
    function owner() public view virtual returns (address) {
        return _owner;
    }

    /**
     * @dev Throws if the sender is not the owner.
     */
    function _checkOwner() internal view virtual {
        if(owner() != _msgSender()) {
            revert CallerIsNotTheContractOwner();
        }
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Can only be called by the current owner.
     */
    function transferOwnership(address newOwner) public virtual override onlyOwner {
        if(newOwner == address(0)) {
            revert NewOwnerIsTheZeroAddress();
        }

        _transferOwnership(newOwner);
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Internal function without access restriction.
     */
    function _transferOwnership(address newOwner) internal virtual {
        address oldOwner = _owner;
        _owner = newOwner;
        emit OwnershipTransferred(oldOwner, newOwner);
    }
}
