// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;

import "./MADTypeDefinitions.sol";

abstract contract IMADStakingManagerDelegate is MADTypeDefinitions {
    function liquidateUnstakingAsset(Metaverse metaverse, uint256 assetId)
        external
        virtual;
}
