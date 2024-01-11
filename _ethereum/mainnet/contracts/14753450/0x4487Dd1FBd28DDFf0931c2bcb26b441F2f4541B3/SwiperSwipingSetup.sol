//SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./Initializable.sol";

import "./SwiperSwipingContracts.sol";

abstract contract SwiperSwipingSetup is Initializable, SwiperSwipingContracts {

    function __SwiperSwipingSetup_init() internal initializer {
        SwiperSwipingContracts.__SwiperSwipingContracts_init();
    }

    function setMerkleRootTower1(bytes32 _merkleRoot) external requiresEitherRole(ADMIN_ROLE, OWNER_ROLE) {
        merkleRootTower1 = _merkleRoot;
    }

    function setMerkleRootTower2(bytes32 _merkleRoot) external requiresEitherRole(ADMIN_ROLE, OWNER_ROLE) {
        merkleRootTower2 = _merkleRoot;
    }

    function setMaxBatchSize(uint8 _maxBatchSize) external requiresEitherRole(ADMIN_ROLE, OWNER_ROLE) {
        maxBatchSize = _maxBatchSize;
    }
}