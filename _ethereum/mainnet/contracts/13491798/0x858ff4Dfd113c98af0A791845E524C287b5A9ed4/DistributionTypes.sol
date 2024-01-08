// SPDX-License-Identifier: MIT

pragma solidity 0.7.6;
pragma experimental ABIEncoderV2;

library DistributionTypes {
    struct AssetConfigInput {
        uint104 emissionPerSecond;
        uint256 totalStaked;
        address underlyingAsset;
    }

    struct UserStakeInput {
        address underlyingAsset;
        uint256 stakedByUser;
        uint256 totalStaked;
    }
}
