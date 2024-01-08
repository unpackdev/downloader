//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.6;

// Possible test a version where we are just using abi.encode? Could actually be that it is just as good?

// Filling from the right.

library ColorLib {
    uint256 internal constant COLOR_MASK = 0xFFFFFFFF;

    function createPaletteFromColorList(uint256[] memory _colors)
        internal
        pure
        returns (uint256[] memory)
    {
        uint256 subCount = _colors.length % 8 > 0 ? _colors.length / 8 + 1 : _colors.length / 8;
        uint256[] memory palette = new uint256[](subCount);
        for (uint8 i = 0; i < subCount; i++) {
            uint256 available = _min(_colors.length - i * 8, 8);
            uint256[] memory subList = new uint256[](available);
            for (uint8 j = 0; j < available; j++) {
                subList[j] = _colors[i * 8 + j];
            }
            palette[i] = _createSubPaletteFromColorList(subList);
        }
        return palette;
    }

    function _createSubPaletteFromColorList(uint256[] memory _colors)
        internal
        pure
        returns (uint256)
    {
        require(_colors.length <= 8, 'Too long');
        uint256 subPalette = 0;
        for (uint8 i = 0; i < _colors.length; i++) {
            require(_colors[i] <= COLOR_MASK, 'Not a color');
            subPalette += _colors[i] * 256**(i * 4);
        }
        return subPalette;
    }

    // Probably need some special case for the non-pixel.
    function getColor(uint256[] memory colorPalette, uint256 index)
        internal
        pure
        returns (uint256)
    {
        if (index / 8 > colorPalette.length - 1) {
            return 0;
        }
        uint256 subPalette = colorPalette[index / 8];
        uint256 shift = 256**((index % 8) * 4);
        return (subPalette / shift) & COLOR_MASK;
    }

    function _min(uint256 a, uint256 b) internal pure returns (uint256) {
        return a > b ? b : a;
    }
}
