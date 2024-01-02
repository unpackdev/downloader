// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.10;

/**
 * @notice Util library to pack, unpack, and access packed prices data
 * @author highlight.xyz
 */
library PackedPrices {
    /**
     * @notice Return unpacked prices
     * @dev Assume length validations are met
     */
    function unpack(
        bytes memory packedPrices,
        uint8 bytesPerPrice,
        uint32 numPrices
    ) internal view returns (uint200[] memory prices) {
        prices = new uint200[](numPrices);

        for (uint32 i = 0; i < numPrices; i++) {
            prices[i] = priceAt(packedPrices, bytesPerPrice, i);
        }
    }

    /**
     * @notice Return price at an index
     * @dev Assume length validations are met
     */
    function priceAt(bytes memory packedPrices, uint8 bytesPerPrice, uint32 index) internal view returns (uint200) {
        uint256 readIndex = index * bytesPerPrice;
        uint256 price;

        assembly {
            // Load 32 bytes starting from the correct position in packedPrices
            price := mload(add(packedPrices, add(32, readIndex)))
        }

        return uint200(price >> (256 - (bytesPerPrice * 8)));
    }
}
