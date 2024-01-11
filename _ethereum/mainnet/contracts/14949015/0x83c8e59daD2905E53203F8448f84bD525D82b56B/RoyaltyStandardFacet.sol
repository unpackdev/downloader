// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "./IERC2981.sol";

import "./AccessControlModifiers.sol";
import "./PausableModifiers.sol";
import "./RoyaltyStandardLib.sol";

contract RoyaltyStandardFacet is
    IERC2981,
    AccessControlModifiers,
    PausableModifiers
{
    function royaltyInfo(uint256 tokenId, uint256 salePrice)
        external
        view
        override
        returns (address, uint256)
    {
        require(tokenId > 0, "tokenId may not exist"); // to please compiler warning
        return RoyaltyStandardLib.royaltyInfo(salePrice);
    }

    function setDefaultRoyalty(uint96 feeNumerator)
        external
        onlyOwner
        whenNotPaused
    {
        RoyaltyStandardLib._setDefaultRoyalty(feeNumerator);
    }

    function deleteDefaultRoyalty() external onlyOwner whenNotPaused {
        RoyaltyStandardLib._deleteDefaultRoyalty();
    }

    function defaultRoyaltyFraction() external view returns (uint256) {
        return
            RoyaltyStandardLib
                .royaltyStandardStorage()
                ._defaultRoyaltyInfo
                .royaltyFraction;
    }
}
