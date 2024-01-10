// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.11;

import "./AbstractBannerNFTs.sol";
import "./BannerHelpers.sol";
import "./StringUtils.sol";
import "./console.sol";

contract BannerNFTsWriter is AbsBannerNFTs {
    constructor() AbsBannerNFTs() {} // solhint-disable-line

    function payAndMint(
        string memory name,
        string memory description,
        string memory txt,
        bool randomizeColors,
        address deliveryAddress
    ) external payable override returns (uint256) {
        require(msg.value >= getMintingCost(), "NEED_MONIES"); // thanks for the tip, if that's the case
        // validate inputs (only checks for invalid chars)
        bytes memory txtBytes = bytes(txt);
        require(su.isValidString(txtBytes), "INVALID_TEXT");
        require(su.isValidString(bytes(name)), "INVALID_NAME");
        require(su.isValidString(bytes(description)), "INVALID_DESCRIPTION");

        // force text to always be under the default length at mint time to avoid expensive calls
        require(txtBytes.length <= bh.DEFAULT_TEXT_LENGTH, "TEXT_TOO_LONG");
        uint256 tokenId = _currentIndex; // get the id before it gets inc'ed by the mint

        // mint the NFT
        if (deliveryAddress != address(0)) _safeMint(deliveryAddress, 1);
        else _safeMint(msg.sender, 1);

        // create an entry and store the attributes for the new token
        (string memory tc, string memory bgc) = randomizeColors
            ? su.getRandomColors()
            : (bh.DEFAULT_TEXT_COLOR, bh.DEFAULT_BG_COLOR);
        _tokens[tokenId] = BannerToken(
            name,
            description,
            bgc,
            txt,
            tc,
            bh.DEFAULT_TEXT_SIZE
        );
        return tokenId;
    }

    function updateSvgAttributes(
        uint256 tokenId,
        string memory txt,
        string memory txtColor,
        string memory txtSize,
        string memory bgColor
    ) external payable override {
        require(_exists(tokenId), "TOKEN_404"); // check if tokenId is in range to change attributes
        require(ownerOf(tokenId) == msg.sender, "NOT_OWNER"); // only the owner of the token can modify the attributes
        require(msg.value >= bh.UPDATE_COST, "NEED_MONIES"); // charge a few cents for changes
        // validate inputs (only checks for invalid chars)
        // ATTN: does not check the semantics of the values
        bytes memory txtBytes = bytes(txt);
        require(su.isValidString(txtBytes), "INVALID_TEXT");
        require(su.isValidString(bytes(txtColor)), "INVALID_TEXT_COLOR");
        require(su.isValidString(bytes(txtSize)), "INVALID_TEXT_SIZE");
        require(su.isValidString(bytes(bgColor)), "INVALID_BG_COLOR");
        BannerModifiableAttributes memory modAttrs = getModifiableAttrs(
            tokenId
        );
        require(
            modAttrs.canModifyEverything ||
                txtBytes.length <= bh.DEFAULT_TEXT_LENGTH,
            "TEXT_TOO_LONG"
        );
        // ATTN: after the validations, update always succeeds, even if cannot modify attrs
        // text can always be modified
        _tokens[tokenId].text = txt;
        // decode what other attrs of the token can be modified
        if (!modAttrs.canModifyTextColor) return; // means it can only modify text, so short circuit to save gas
        if (modAttrs.canModifyTextColor) _tokens[tokenId].textColor = txtColor;
        if (modAttrs.canModifyTextSize) _tokens[tokenId].textSize = txtSize;
        if (modAttrs.canModifyBgColor) _tokens[tokenId].bgColor = bgColor;
    }
}
