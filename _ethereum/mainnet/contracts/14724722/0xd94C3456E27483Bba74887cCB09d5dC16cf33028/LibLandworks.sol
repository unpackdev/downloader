// SPDX-License-Identifier: MIT
pragma solidity 0.8.0;

library LibLandworks {
    enum AssetStatus {
        Listed,
        Delisted
    }

    struct Asset {
        uint256 metaverseId;
        address metaverseRegistry;
        uint256 metaverseAssetId;
        address paymentToken;
        uint256 minPeriod;
        uint256 maxPeriod;
        uint256 maxFutureTime;
        uint256 pricePerSecond;
        uint256 totalRents;
        AssetStatus status;
    }

    struct Rent {
        address renter;
        uint256 start;
        uint256 end;
    }
}
