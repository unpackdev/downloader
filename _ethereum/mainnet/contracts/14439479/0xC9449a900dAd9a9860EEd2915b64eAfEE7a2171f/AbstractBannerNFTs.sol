// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.11;

import "./Ownable.sol";
import "./ReentrancyGuard.sol";
import "./ERC721A.sol";

import "./BannerHelpers.sol";

abstract contract AbsBannerNFTs is ERC721A, Ownable, ReentrancyGuard {
    struct BannerToken {
        string name;
        string description;
        string bgColor;
        string text;
        string textColor;
        string textSize;
    }

    struct BannerModifiableAttributes {
        bool canModifyTextColor;
        bool canModifyTextSize;
        bool canModifyBgColor;
        bool canModifyEverything;
    }

    mapping(uint256 => BannerToken) internal _tokens;

    // solhint-disable-next-line
    constructor() ERC721A("BannerNFTs", "BAN") {}

    function getMintingCost() public view returns (uint256) {
        return (bh.MINTING_COST_MULTIPLIER * (_currentIndex + 1));
    }

    function getModifiableAttrs(uint256 tokenId)
        public
        pure
        virtual
        returns (BannerModifiableAttributes memory)
    {
        // solhint-disable-previous-line
    }

    function payAndMint(
        string memory name,
        string memory description,
        string memory txt,
        bool randomizeColors,
        address deliveryAddress
    ) external payable virtual returns (uint256);

    function updateSvgAttributes(
        uint256 tokenId,
        string memory txt,
        string memory txtColor,
        string memory txtSize,
        string memory bgColor
    ) external payable virtual;
}
