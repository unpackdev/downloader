// SPDX-License-Identifier: BUSL-1.1
pragma solidity 0.8.15;

interface IAPMorganTypes {
    event TokenLayersDetermined(
        uint256 tokenId,
        uint256 chainId,
        uint8 randomLayer0,
        uint8 randomLayer1,
        uint8 layer2,
        uint8 layer3,
        uint8 layer4,
        uint8 layer5,
        uint8 layer6
    );

    /// @dev packed into 1 storage slot
    struct LayerData {
        uint8 randomLayer0;
        uint8 randomLayer1;
        uint8 layer2;
        uint8 layer3;
        uint8 layer4;
        uint8 layer5;
        uint8 layer6;
        uint200 originatingChainId;
    }

    /// @dev - packed into 1 storage slots
    struct PremintedTokenData {
        uint8 layer2;
        uint8 layer3;
        uint8 layer4;
        uint8 layer5;
        uint8 layer6;
        uint96 tokenId; // 2^96=7.9228163e+28
        address owner; // size of 20bytes or uint160
    }

    struct LayerCounts {
        uint8 numImagesLayer2;
        uint8 numImagesLayer3;
        uint8 numImagesLayer4;
        uint8 numImagesLayer5;
        uint8 numImagesLayer6;
    }
}
