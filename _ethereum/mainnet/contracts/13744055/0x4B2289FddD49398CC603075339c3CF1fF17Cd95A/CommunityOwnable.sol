// SPDX-License-Identifier: MIT
// Forked from OpenZeppelin Contracts v4.3.2 (access/Ownable.sol)

pragma solidity ^0.8.0;

import "Context.sol";

/**
 * @dev Contract module which provides a basic access control mechanism, where
 * there is an account (an owner) that can be granted exclusive access to
 * specific functions.
 *
 * By default, the owner account will be the one that deploys the contract. This
 * can later be changed with {transferOwnership}.
 *
 * This module is used through inheritance. It will make available the modifier
 * `onlyCommunityOwner`, which can be applied to your functions to restrict their use to
 * the owner.
 */
abstract contract CommunityOwnable is Context {
    address private _owner;

    event CommunityOwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    /**
     * @dev Initializes the contract setting the deployer as the initial owner.
     */
    constructor(address _communityOwner) {
        _transferCommunityOwnership(_communityOwner);
    }

    /**
     * @dev Returns the address of the current owner.
     */
    function communityOwner() public view virtual returns (address) {
        return _owner;
    }

    /**
     * @dev Throws if called by any account other than the owner.
     */
    modifier onlyCommunityOwner() {
        require(communityOwner() == _msgSender(), "CommunityOwnable: caller is not the community owner");
        _;
    }

    /**
     * @dev Leaves the contract without owner. It will not be possible to call
     * `onlyCommunityOwner` functions anymore. Can only be called by the current owner.
     *
     * NOTE: Renouncing ownership will leave the contract without an owner,
     * thereby removing any functionality that is only available to the owner.
     */
    function renounceCommunityOwnership() public virtual onlyCommunityOwner {
        _transferCommunityOwnership(address(0));
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Can only be called by the current owner.
     */
    function transferCommunityOwnership(address newOwner) public virtual onlyCommunityOwner {
        require(newOwner != address(0), "CommunityOwnable: new owner is the zero address");
        _transferCommunityOwnership(newOwner);
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Internal function without access restriction.
     */
    function _transferCommunityOwnership(address newOwner) internal virtual {
        address oldOwner = _owner;
        _owner = newOwner;
        emit CommunityOwnershipTransferred(oldOwner, newOwner);
    }
}
