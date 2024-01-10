// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;

import "./console.sol";

import "./IOriginNftUpgradeable.sol";

contract OriginNft is IOriginNftUpgradeable {
    function initialize() public initializer {
        __IOriginNftUpgradeable_init_unchained("AthleteOriginNFTs", "OG");
    }
}
