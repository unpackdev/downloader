// SPDX-License-Identifier: MIT
pragma solidity 0.8.13;

import "./Ownable.sol";

/*
Opensea only allows EOAs to make changes to collections,
which makes it impossible to use multisigs to secure these NFT contracts
since when you want to make changes, you need to transfer ownership to an EOA, who can rug.

This contract establishes a second owner that can change the EOA owner,
this way a multisig can give ownership to an EOA and later claim it back.

Credits: Tubby Cats
*/

/**
 * @dev Contract module which provides a basic access control mechanism, where
 * there is an account (an multisig owner) that can be granted exclusive access to
 * specific functions.
 *
 * By default, the multisig owner account will be the one that deploys the contract. This
 * can later be changed with {transferMulitSigOwnership}.
 *
 * This module is used through inheritance. It will make available the modifier
 * `onlyMultiSigOwner`, which can be applied to your functions to restrict their use to
 * the multisig owner.
 */
abstract contract MultiSigOwnable is Ownable {
    address private _multisigOwner;

    event MultiSigOwnershipTransferred(address indexed previousMultiSigOwner, address indexed newMultiSigOwner);

    /**
     * @dev Initializes the contract setting the deployer as the initial multisig owner.
     */
    constructor() {
        _transferMultiSigOwnership(_msgSender());
    }

    /**
     * @dev Returns the address of the current multisig owner.
     */
    function multisigOwner() public view virtual returns (address) {
        return _multisigOwner;
    }

    /**
     * @dev Throws if called by any account other than the multisig owner.
     */
    modifier onlyMultiSigOwner() {
        // solhint-disable-next-line reason-string
        require(multisigOwner() == _msgSender(), "MultiSigOwnable: caller is not the owner");
        _;
    }

    /**
     * @dev Leaves the contract without multisig owner. It will not be possible to call
     * `onlyMultiSigOwner` functions anymore. Can only be called by the current multisig owner.
     *
     * NOTE: Renouncing ownership will leave the contract without an multisig owner,
     * thereby removing any functionality that is only available to the multisig owner.
     */
    function renounceMultiSigOwnership() public virtual onlyMultiSigOwner {
        _transferMultiSigOwnership(address(0));
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newMultiSigOwner`).
     * Can only be called by the current multisig owner.
     */
    function transferMultiSigOwnership(address newMultiSigOwner) public virtual onlyMultiSigOwner {
        // solhint-disable-next-line reason-string
        require(newMultiSigOwner != address(0), "MultiSigOwnable: new owner is the zero address");
        _transferMultiSigOwnership(newMultiSigOwner);
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newMultiSigOwner`).
     * Internal function without access restriction.
     */
    function _transferMultiSigOwnership(address newMultiSigOwner) internal virtual {
        address oldMultiSigOwner = _multisigOwner;
        _multisigOwner = newMultiSigOwner;
        emit MultiSigOwnershipTransferred(oldMultiSigOwner, newMultiSigOwner);
    }

    function transferLowerOwnership(address newOwner) public onlyMultiSigOwner {
        _transferOwnership(newOwner);
    }
}
