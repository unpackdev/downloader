// SPDX-License-Identifier: MIT
pragma solidity ^0.8.11;

/**
 * @title OwnableDeferral
 * @author @NiftyMike | @NFTCulture
 * @dev Implements checks for contract admin operations. Will be Backed by
 * OZ Ownable.
 *
 * This contract is helpful when a contract tree gets complicated,
 * and multiple contracts need to leverage Ownable.
 *
 * Sample Implementation:
 *
 * modifier isOwner() override(...) {
 *     _isOwner();
 *     _;
 * }
 *
 * function _isOwner() internal view override(...) {
 *     _checkOwner();
 * }
 */
abstract contract OwnableDeferral {
    modifier isOwner() virtual;

    function _isOwner() internal view virtual;
}
