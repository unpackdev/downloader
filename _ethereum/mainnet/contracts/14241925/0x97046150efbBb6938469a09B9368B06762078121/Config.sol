// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.6;

import "./AccessControlEnumerableUpgradeable.sol";
import "./CountersUpgradeable.sol";

contract Config is AccessControlEnumerableUpgradeable {

    address weth;

    address vault;

    uint public salePrice;

    uint public publicSaleNum;

    bytes32 public merkleRoot;

    uint public maxPublicSaleNum;

    CountersUpgradeable.Counter internal _index;

    mapping(address => bool) public claimedMap;

    mapping(uint8 => string[]) public palettes;

    string[] public backgrounds;

    bytes[] public accessories;

    bytes[] public bodies;

    bytes[] public glasses;

    bytes[] public heads;
}
