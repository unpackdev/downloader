// SPDX-License-Identifier: MIT
pragma solidity ^0.8.18;

library PriceStorage {
    struct MintInfo {
        uint256 round;
        uint256 price;
    }

    struct Layout {
        mapping(bytes32 canvasId => MintInfo mintInfo) canvasLastMintInfos;
        mapping(bytes32 daoId => MintInfo) daoMaxPrices;
        mapping(bytes32 daoId => uint256 floorPrice) daoFloorPrices;
    }

    bytes32 internal constant STORAGE_SLOT = keccak256("D4Av2.contracts.storage.PriceStorage");

    function layout() internal pure returns (Layout storage l) {
        bytes32 slot = STORAGE_SLOT;
        assembly {
            l.slot := slot
        }
    }
}
