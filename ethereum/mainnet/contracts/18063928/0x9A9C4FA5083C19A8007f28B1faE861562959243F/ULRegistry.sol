// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

import "./DataTypes.sol";

abstract contract ULRegistryStorage {
    mapping(address => mapping(address => DataTypes.PathInfo)) public paths;
    mapping(bytes32 => address) public dexesInfo;

    bytes32[] internal _allDexes;
    address[] internal _intermediateTokens;
}
