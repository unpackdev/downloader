// SPDX-License-Identifier: MIT
pragma solidity =0.7.6;


/**
 * @dev Contract module which provides a basic access control mechanism, where
 * there is an account (an owner) that can be granted exclusive access to
 * specific functions.
 *
 * This is a modified implementation of OpenZeppelin's Ownable.sol.
 * The modifications allow the contract to be inherited by a proxy's logic contract.
 * Any owner-only functions on the base implementation will be unusable.
 *
 * By default, the owner account will be a null address which can be set by invoking
 * a function with the `initializer` modifier. The owner can later be changed with
 * {transferOwnership}.
 *
 * This module is used through inheritance. It will make available the modifier
 * `onlyOwner`, which can be applied to your functions to restrict their use to
 * the owner. It also makes available the `initializer` modifier, which will set
 * the owner to `msg.sender` the first time the function is invoked, and will
 * revert if the owner has already been set.
 *
 * Note: This contract should only be inherited by proxy implementation contracts
 * where the implementation will only ever be used as the logic address for proxies.
 * The constructor permanently locks the owner of the implementation contract, but the
 * owner of the proxies can be configured by the first caller.
 */
contract OwnableProxyImplementation {
  address private _owner;

  event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

  constructor() {
    _owner = address(1);
    emit OwnershipTransferred(address(0), address(1));
  }

  /**
   * @dev Returns the address of the current owner.
   */
  function owner() public view returns (address) {
    return _owner;
  }

  /**
   * @dev Throws if called by any account other than the owner.
   */
  modifier onlyOwner {
    require(_owner == msg.sender, "!owner");
    _;
  }

  /**
   * @dev Initializes the contract setting `initialOwner` as the initial owner.
   * Reverts if owner has already been set.
   */
  modifier initializer(address initialOwner) {
    require(_owner == address(0), "already initialized");
    _owner = initialOwner;
    emit OwnershipTransferred(address(0), initialOwner);
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
    // Modified from OZ contract - sets owner to address(1) to prevent
    // the initializer from being invoked after ownership is revoked.
    emit OwnershipTransferred(_owner, address(1));
    _owner = address(1);
  }

  /**
   * @dev Transfers ownership of the contract to a new account (`newOwner`).
   * Can only be called by the current owner.
   */
  function transferOwnership(address newOwner) public virtual onlyOwner {
    require(newOwner != address(0), "Ownable: new owner is the zero address");
    emit OwnershipTransferred(_owner, newOwner);
    _owner = newOwner;
  }
}
