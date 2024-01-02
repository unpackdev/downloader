// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

// the stalker by int.art
// a permissionless collaboration program running on EVM.

// Original artworks by XCOPY (FRESH HELL).
// Modified artworks are CCO licensed.

// If XCOPY mints a token that's not CC0, int.art has right to
// block that token.

import "./Ownable.sol";
import "./Base64.sol";
import "./LibString.sol";
import "./IScriptyBuilderV2.sol";

import "./TheStalkerCommon.sol";

interface IManifoldCreatorContract {
    function totalSupply(uint256 tokenId) external view returns (uint256);
}

interface IEfficax {
    function tokenData(
        address,
        uint256
    ) external view returns (string calldata, string calldata);

    function tokenURI(
        address creatorContractAddress,
        uint256 tokenId
    ) external view returns (string memory);
}

contract TheStalkerFRESHHELLRenderer is Ownable, ITheStalkerRenderer {
    IScriptyBuilderV2 public immutable scriptyBuilder;
    address public immutable scriptyETHFSAddress;
    IEfficax public immutable efficax;
    IManifoldCreatorContract public immutable freshHell;
    ITheStalkerRenderer public defaultRenderer;

    mapping(uint256 => bool) public blockedTokenIds;
    error BlockedTokenId();

    constructor(
        IScriptyBuilderV2 _scriptyBuilder,
        address _scriptyETHFSAddress,
        IEfficax _efficax,
        IManifoldCreatorContract _freshHell,
        ITheStalkerRenderer _defaultRenderer
    ) Ownable(msg.sender) {
        scriptyBuilder = _scriptyBuilder;
        scriptyETHFSAddress = _scriptyETHFSAddress;
        efficax = _efficax;
        freshHell = _freshHell;
        defaultRenderer = _defaultRenderer;
    }

    // CONTRACT OWNER

    function updateBlockedTokenIds(
        uint256 targetTokenId,
        bool isBlocked
    ) public onlyOwner {
        blockedTokenIds[targetTokenId] = isBlocked;
        emit BlockedTokenIdUpdate(targetTokenId, isBlocked);
    }

    function updateDefaultRenderer(
        ITheStalkerRenderer _defaultRenderer
    ) public onlyOwner {
        defaultRenderer = _defaultRenderer;
        emit DefaultRendererUpdate(_defaultRenderer);
    }

    // PUBLIC

    function canUpdateToken(
        address /*sender*/,
        uint256 /*tokenId*/,
        uint256 targetTokenId
    ) public view override returns (bool) {
        return !blockedTokenIds[targetTokenId];
    }

    function isTokenRenderable(
        uint256 /*tokenId*/,
        uint256 targetTokenId
    ) public view override returns (bool) {
        return canRender(targetTokenId);
    }

    function tokenHTML(
        uint256 tokenId,
        uint256 targetTokenId
    ) public view override returns (string memory) {
        if (!canRender(targetTokenId)) {
            return defaultRenderer.tokenHTML(tokenId, targetTokenId);
        }

        (string memory original, ) = generateModifiedFreshHellSVG(
            targetTokenId
        );
        return
            tokenHTMLWithFreshHellBase64SVG(
                string(Base64.encode(bytes(original)))
            );
    }

    function tokenImage(
        uint256 tokenId,
        uint256 targetTokenId
    ) public view override returns (string memory) {
        if (!canRender(targetTokenId)) {
            return defaultRenderer.tokenImage(tokenId, targetTokenId);
        }

        (, string memory modified) = generateModifiedFreshHellSVG(
            targetTokenId
        );
        return
            string(
                abi.encodePacked(
                    "data:image/svg+xml;base64,",
                    Base64.encode(bytes(modified))
                )
            );
    }

    function tokenURI(
        uint256 tokenId,
        uint256 targetTokenId
    ) public view override returns (string memory) {
        if (!canRender(targetTokenId)) {
            return defaultRenderer.tokenURI(tokenId, targetTokenId);
        }

        (
            string memory original,
            string memory modified
        ) = generateModifiedFreshHellSVG(targetTokenId);

        bytes memory metadata = abi.encodePacked(
            '{"name":"the stalker #',
            LibString.toString(tokenId),
            '", "description":"a permissionless collaboration program running on EVM - int.art x XCOPY - Original artwork by XCOPY (FRESH HELL).","animation_url":"',
            tokenHTMLWithFreshHellBase64SVG(
                string(Base64.encode(bytes(original)))
            ),
            '","image":"',
            abi.encodePacked(
                "data:image/svg+xml;base64,",
                Base64.encode(bytes(modified))
            ),
            '"}'
        );

        return
            string(
                abi.encodePacked(
                    "data:application/json;base64,",
                    Base64.encode(metadata)
                )
            );
    }

    // Modifying a little bit to make it stand out from original
    // FRESH HELL artworks. Hoping he keeps minting SVGs.
    function generateModifiedFreshHellSVG(
        uint256 targetTokenId
    ) public view returns (string memory, string memory) {
        if (blockedTokenIds[targetTokenId]) {
            revert BlockedTokenId();
        }

        (string memory svg, ) = decodedImageFromEfficax(
            address(freshHell),
            targetTokenId
        );

        string memory svgOriginal = string(Base64.decode(svg));
        // hoping <svg ... > is the first tag
        uint256 svgBeginIndex = LibString.indexOf(svgOriginal, ">");

        // if we can't find just return the original image
        if (svgBeginIndex == type(uint256).max) {
            return (svgOriginal, svgOriginal);
        }

        string memory svgModifiedPrefix = LibString.slice(
            svgOriginal,
            0,
            svgBeginIndex + 1
        );

        uint256 length = bytes(svgOriginal).length;
        string memory svgModifiedSuffix = LibString.slice(
            svgOriginal,
            svgBeginIndex + 1,
            length - 6
        );

        string memory svgModified = LibString.concat(
            svgModifiedPrefix,
            '<g id="DUDE"><style type="text/css">@keyframes shakeAnimation {0%,75% {transform: translate(0.3%, 0.3%) scale(1.1, 1.1);}76%,100% {transform: translate(-0.3%, -0.3%) scale(1.1, 1.1);}}#DUDE {animation: shakeAnimation 0.16s infinite;transform-origin: center;}</style>'
        );
        svgModified = LibString.concat(svgModified, svgModifiedSuffix);
        svgModified = LibString.concat(svgModified, "</g></svg>");

        return (svgOriginal, svgModified);
    }

    // Generic Efficax decoder. This returns raw base64 image without
    // data uri part. This is public and generic so you can request
    // any raw image data from Efficax.
    function decodedImageFromEfficax(
        address collectionAddress,
        uint256 tokenId
    ) public view returns (string memory, string memory) {
        unchecked {
            string memory _tokenURI = efficax.tokenURI(
                collectionAddress,
                tokenId
            );

            (string memory metadata, string memory mimeType) = efficax
                .tokenData(collectionAddress, tokenId);

            uint256 sliceBeginIndex = 40 +
                bytes(metadata).length +
                bytes(mimeType).length +
                13;
            uint256 sliceEndIndex = bytes(_tokenURI).length - 2;

            return (
                LibString.slice(_tokenURI, sliceBeginIndex, sliceEndIndex),
                mimeType
            );
        }
    }

    function tokenHTMLWithFreshHellBase64SVG(
        string memory base64SVGWithoutDataURI
    ) public view virtual returns (string memory) {
        HTMLTag[] memory headTags = new HTMLTag[](1);
        headTags[0].name = "fullSizeCanvas.css";
        headTags[0]
            .tagOpen = '<link rel="stylesheet" href="data:text/css;base64,';
        headTags[0].tagClose = '">';
        headTags[0].contractAddress = scriptyETHFSAddress;

        HTMLTag[] memory bodyTags = new HTMLTag[](2);
        bodyTags[0].name = "thestalkerFRESHHELL.js";
        bodyTags[0].contractAddress = scriptyETHFSAddress;
        bodyTags[0].tagType = HTMLTagType.scriptBase64DataURI;

        bodyTags[1].tagContent = abi.encodePacked(
            "const svgData = '",
            base64SVGWithoutDataURI,
            "';",
            "thestalkerFRESHHELL(svgData)"
        );
        bodyTags[1].tagType = HTMLTagType.script;

        HTMLRequest memory htmlRequest;
        htmlRequest.headTags = headTags;
        htmlRequest.bodyTags = bodyTags;

        return scriptyBuilder.getEncodedHTMLString(htmlRequest);
    }

    function canRender(uint256 targetTokenId) public view returns (bool) {
        uint256 totalSupply = freshHell.totalSupply(targetTokenId);
        return totalSupply > 0 && !blockedTokenIds[targetTokenId];
    }

    // EVENTS

    event BlockedTokenIdUpdate(uint256 _tokenId, bool _isBlocked);
    event DefaultRendererUpdate(ITheStalkerRenderer _defaultRenderer);
}
