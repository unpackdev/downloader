// SPDX-License-Identifier: MIT
pragma solidity ^0.8.18;

import "./D4AConstants.sol";
import "./PriceStorage.sol";
import "./PriceTemplateBase.sol";

contract ExponentialPriceVariation is PriceTemplateBase {
    function _getPriceInRound(
        PriceStorage.MintInfo memory mintInfo,
        uint256 round,
        uint256 priceMultiplierInBps
    )
        internal
        pure
        virtual
        override
        returns (uint256)
    {
        if (round == mintInfo.round) {
            return mintInfo.price * priceMultiplierInBps / BASIS_POINT;
        }
        uint256 k = round - mintInfo.round - 1;
        uint256 price = mintInfo.price;
        for (uint256 i; i < k;) {
            price = price * BASIS_POINT / priceMultiplierInBps;
            if (price == 0) return 0;
            unchecked {
                ++i;
            }
        }
        return price;
    }
}
