// SPDX-License-Identifier: MIT
// Arttaca Contracts (last updated v1.0.0) (collections/erc1155/ArttacaERC1155Beacon.sol)

pragma solidity ^0.8.4;

import "./UpgradeableBeacon.sol";

/**
 * @title ArttacaERC1155Beacon
 * @dev This contract is a the Beacon to proxy Arttaca ERC1155 collections.
 */
contract ArttacaERC1155Beacon is UpgradeableBeacon {
    constructor(address _initBlueprint) UpgradeableBeacon(_initBlueprint) {
        transferOwnership(tx.origin);
    }
}