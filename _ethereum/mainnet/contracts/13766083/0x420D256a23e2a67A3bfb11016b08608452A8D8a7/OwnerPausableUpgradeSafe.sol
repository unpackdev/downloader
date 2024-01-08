// SPDX-License-Identifier: agpl-3.0
pragma solidity 0.8.6;

import {Errors} from "Errors.sol";

/**
 * @title OwnerPausableUpgradeSafe
 *
 * @dev Contract to be inherited from that adds simple owner pausable functionality. This does not
 * implement any changes on its own as there is no constructor or initializer. Both _owner and _paused must
 * be initialized in the inheriting contract.
 * @dev Inspired by `@openzeppelin-upgradeable/contracts/security/PausableUpgradeable.sol`
 */
abstract contract OwnerPausableUpgradeSafe {
    address internal _owner;
    bool internal _paused;

    /**
     * @notice Emitted when the contract is paused.
     */
    event Pause();

    /**
     * @notice Emitted when the contract is unpaused.
     */
    event Unpause();

    /**
     * @notice Emitted when the owner is set to a different address.
     */
    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    /**
     * @dev Modifier to only allow functions to be called when not paused.
     */
    modifier whenNotPaused() {
        require(!_paused, Errors.PAUSED);
        _;
    }

    /**
     * @dev Modifier to only allow the admin as the caller.
     */
    modifier onlyOwner() {
        require(msg.sender == _owner, Errors.NOT_OWNER);
        _;
    }

    /**
     * @dev Owner function pauses the contract.
     */
    function pause() external onlyOwner {
        _paused = true;
        emit Pause();
    }

    function paused() external view returns(bool) {
        return _paused;
    }

    /**
     * @dev Owner function unpauses the contract.
     */
    function unpause() external onlyOwner {
        _paused = false;
        emit Unpause();
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Can only be called by the current owner.
     */
    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
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

    /**
     * @dev View function that returns the current owner.
     */
    function owner() public view returns (address) {
        return _owner;
    }

    uint256[3] private __gap;  // contract uses small number of slots (5 in total)
}