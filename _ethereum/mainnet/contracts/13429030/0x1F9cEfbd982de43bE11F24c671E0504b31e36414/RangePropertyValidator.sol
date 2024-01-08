// SPDX-License-Identifier: MIT

pragma solidity 0.8.4;

import "./IPropertyValidator.sol";

contract RangePropertyValidator is IPropertyValidator {
    function checkBrokerAsset(uint256 tokenId, bytes calldata propertyData)
        external
        pure
        override
    {
        (uint256 tokenIdLowerBound, uint256 tokenIdUpperBound) = abi.decode(
            propertyData,
            (uint256, uint256)
        );
        require(
            tokenIdLowerBound <= tokenId && tokenId <= tokenIdUpperBound,
            "Token id out of range"
        );
    }
}
