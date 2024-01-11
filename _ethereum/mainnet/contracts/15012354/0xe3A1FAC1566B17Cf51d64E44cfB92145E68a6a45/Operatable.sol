// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.0 (access/Operatable.sol)

pragma solidity ^0.8.0;

import "./Ownable.sol";

/**
 * @dev Contract module which provides a basic access control mechanism, where
 * there is an account (an operator) that can be granted exclusive access to
 * specific functions.
 *
 * By default, the operator account will be the one that deploys the contract. This
 * can later be changed with {transferOperationRight}.
 *
 * This module is used through inheritance. It will make available the modifier
 * `onlyOperator`, which can be applied to your functions to restrict their use to
 * the operator.
 */
abstract contract Operatable is Ownable {
    address private _operator;

    event OperationRightTransferred(address indexed previousOperator, address indexed newOperator);

    /**
     * @dev Initializes the contract setting the deployer as the initial operator.
     */
    constructor() Ownable () {
        _transferOperationRight(_msgSender());
    }

    /**
     * @dev Returns the address of the current operator.
     */
    function operator() public view virtual returns (address) {
        return _operator;
    }

    /**
     * @dev Throws if called by any account other than the operator.
     */
    modifier onlyOperator() {
        require(operator() == _msgSender(), "Operatable: caller is not the operator");
        _;
    }

    /**
     * @dev Leaves the contract without operator. It will not be possible to call
     * `onlyOwner` functions anymore. Can only be called by the current owner.
     *
     * NOTE: Renouncing operation Rights will leave the contract without an operator,
     * thereby removing any functionality that is only available to the operator.
     */
    function renounceOperationRight() public virtual onlyOwner {
        _transferOperationRight(address(0));
    }

    /**
     * @dev Transfers operation right of the contract to a new account (`newOperator`).
     * Can only be called by the current owner.
     */
    function transferOperationRight(address newOperator) public virtual onlyOwner {
        require(newOperator != address(0), "Operatable: new owner is the zero address");
        _transferOperationRight(newOperator);
    }

    /**
     * @dev Transfers operation right of the contract to a new account (`newOperator`).
     * Internal function without access restriction.
     */
    function _transferOperationRight(address newOperator) internal virtual {
        address oldOperator = _operator;
        _operator = newOperator;
        emit OperationRightTransferred(oldOperator, newOperator);
    }
}
