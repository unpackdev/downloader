// SPDX-License-Identifier: LGPL-3.0-or-later
pragma solidity >=0.6.0 <0.7.0;

import "./EnumerableSetUpgradeable.sol";
import "./CountersUpgradeable.sol";

/// @title A storage contract for didv1
/// @dev include mapping from id to address and address to id
contract DidV1Storage {
    using CountersUpgradeable for CountersUpgradeable.Counter;
    using EnumerableSetUpgradeable for EnumerableSetUpgradeable.AddressSet;
    CountersUpgradeable.Counter internal _tokenIds;

    mapping(bytes32 => bool) internal reserved;
    address internal owner;

    mapping(address => bytes32) public didHashes;
    mapping(bytes32 => address) public addrs;
    mapping(bytes32 => string) public didName;

    mapping(bytes32 => EnumerableSetUpgradeable.AddressSet) internal auths;

}
