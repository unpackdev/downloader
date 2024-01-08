// SPDX-License-Identifier: MIT
pragma solidity >=0.8.4;

import "./IOGCards.sol";

interface ILayerDescriptor {
    struct Layer {
        bool isGiveaway;
        uint8 maskType;
        uint8 transparencyLevel;
        uint256 tokenId;
        uint256 dna;
        uint256 mintTokenId;
        string font;
        string borderColor;
        address ogCards;
    }
    function svgLayer(address ogCards, uint256 tokenId, string memory font, string memory borderColor, IOGCards.Card memory card)
        external
        view
        returns (string memory);

    function svgMask(uint8 maskType, string memory borderColor, bool isDef, bool isMask)
        external
        pure
        returns (string memory);
}