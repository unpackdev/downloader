// SPDX-License-Identifier: MIT
pragma solidity >=0.8.4;
pragma experimental ABIEncoderV2;

import "./ILayerDescriptor.sol";

contract BackLayerDescriptor is ILayerDescriptor {
    constructor() {}

    function svgLayer(address ogCards, uint256 tokenId, string memory font, string memory borderColor, IOGCards.Card memory card)
        external
        override
        view
        returns (string memory)
    {
        string memory backgroundColor = "#2c3e50";
        return string(abi.encodePacked(
            '<rect width="100%" height="100%" fill="',backgroundColor,'" />'
        ));
    }

    function svgMask(uint8 maskType, string memory borderColor, bool isDef, bool isMask)
        public
        override
        pure
        returns (string memory)
    {
        return "";
    }
}