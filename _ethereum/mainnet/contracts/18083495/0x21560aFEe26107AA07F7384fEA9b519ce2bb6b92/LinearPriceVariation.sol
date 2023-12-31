// SPDX-License-Identifier: MIT
pragma solidity ^0.8.18;

import "./PriceStorage.sol";
import "./PriceTemplateBase.sol";

contract LinearPriceVariation is PriceTemplateBase {
    function _getPriceInRound(
        PriceStorage.MintInfo memory mintInfo,
        uint256 round,
        uint256 priceAddend
    )
        internal
        pure
        virtual
        override
        returns (uint256)
    {
        if (round == mintInfo.round) {
            return mintInfo.price + priceAddend;
        }
        uint256 k = round - mintInfo.round - 1;
        uint256 price = mintInfo.price;
        return (price >= priceAddend * k) ? (price - priceAddend * k) : 0;
    }
}
