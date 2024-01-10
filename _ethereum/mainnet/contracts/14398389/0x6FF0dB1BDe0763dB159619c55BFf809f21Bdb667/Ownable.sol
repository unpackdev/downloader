// SPDX-License-Identifier: Unlicense
pragma solidity >=0.8.0;

/// @title Ownable
/// @notice Provides a modifier to authenticate contract owner.
/// @dev The default owner is the contract deployer, but this can be modified
/// afterwards using `transferOwnership`. There is no check when transferring
/// ownership so ensure you don't use `address(0)` unintentionally. The modifier
/// to guard functions with is `onlyOwner`.
/// @author 0xMetas
/// @author Based on OpenZeppelin (https://github.com/OpenZeppelin/openzeppelin-contracts/blob/master/contracts/access/Ownable.sol)
abstract contract Ownable {
    /// @notice This emits when the owner changes.
    /// @param previousOwner The address of the previous owner.
    /// @param newOwner The address of the new owner.
    event OwnershipTransferred(
        address indexed previousOwner,
        address indexed newOwner
    );

    /// @dev Error thrown when `onlyOwner` is called by an address other than `owner`.
    error NotOwner();

    /// @notice The address of the owner.
    address public owner;

    /// @dev Sets the value of `owner` to `msg.sender`.
    constructor() {
        owner = msg.sender;
    }

    /// @dev Reverts if `msg.sender` is not `owner`.
    modifier onlyOwner() {
        if (msg.sender != owner) revert NotOwner();
        _;
    }

    /// @notice Sets the `owner` address to a new one.
    /// @dev Use `address(0)` to renounce ownership.
    /// @param newOwner The address of the new owner of the contract.
    function transferOwnership(address newOwner) external onlyOwner {
        emit OwnershipTransferred(owner, newOwner);
        owner = newOwner;
    }
}
