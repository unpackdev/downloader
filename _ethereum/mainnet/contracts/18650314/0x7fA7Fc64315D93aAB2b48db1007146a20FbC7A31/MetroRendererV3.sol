// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

//                        888
//                        888
//                        888
// 88888b.d88b.   .d88b.  888888 888d888 .d88b.
// 888 "888 "88b d8P  Y8b 888    888P"  d88""88b
// 888  888  888 88888888 888    888    888  888
// 888  888  888 Y8b.     Y88b.  888    Y88..88P
// 888  888  888  "Y8888   "Y888 888     "Y88P"

// 888                    d8b          888                          888
// 888                    Y8P          888                          888
// 888                                 888                          888
// 88888b.  888  888      888 88888b.  888888       8888b.  888d888 888888
// 888 "88b 888  888      888 888 "88b 888             "88b 888P"   888
// 888  888 888  888      888 888  888 888         .d888888 888     888
// 888 d88P Y88b 888      888 888  888 Y88b.       888  888 888     Y88b.
// 88888P"   "Y88888      888 888  888  "Y888      "Y888888 888      "Y888
//               888
//          Y8b d88P
//           "Y88P"

import "./Ownable.sol";
import "./IMetroRenderer.sol";

import "./IMetro.sol";
import "./IMetroThemeStorageV2.sol";
import "./IMetroMapGeneratorV2.sol";
import "./IScriptyBuilder.sol";

import "./LibString.sol";
import "./Base64.sol";

struct MetroTokenState {
    uint256 mode; // 0: Curate, 1: Evolve, 2: Lock
    uint256 baseSeedSetDate;
    uint256 lockStartDate;
    uint256 progressStartIndex;
    uint256 curateCount;
    bytes32 baseSeed;
}

contract MetroRendererV3 is Ownable, IMetroRenderer {
    struct Trait {
        uint256 valueIndex;
        string typeName;
        string valueName;
    }

    address public metroAddress;
    address public scriptyStorageAddress;
    IScriptyBuilder public scriptyBuilder;
    IMetroThemeStorageV2 public themeStorage;
    IMetroMapGeneratorV2 public mapGenerator;

    uint256 public HTMLBufferAllocation;

    constructor(
        address _metroAddress,
        address _mapGeneratorAddress,
        address _scriptyStorageAddress,
        address _scriptyBuilderAddress,
        address _metroThemeStorageAddress,
        uint256 _HTMLBufferAllocation
    ) {
        metroAddress = _metroAddress;
        mapGenerator = IMetroMapGeneratorV2(_mapGeneratorAddress);
        scriptyStorageAddress = _scriptyStorageAddress;
        scriptyBuilder = IScriptyBuilder(_scriptyBuilderAddress);
        themeStorage = IMetroThemeStorageV2(_metroThemeStorageAddress);
        HTMLBufferAllocation = _HTMLBufferAllocation;
    }

    // MARK: - tokenURI

    function tokenURI(uint256 tokenId) public view returns (string memory) {
        return generateFullMetadataFor(tokenId);
    }

    // MARK: - Map Data

    function getMapData(
        uint256 tokenId
    ) public view returns (MetroMapResult memory) {
        (, , MetroMapResult memory mapResult) = generateAllMapDataFor(
            tokenId,
            0
        );
        return mapResult;
    }

    function getMapSVG(uint256 tokenId) public view returns (string memory) {
        (, , MetroMapResult memory mapResult) = generateAllMapDataFor(
            tokenId,
            1
        );
        return string(mapResult.svg);
    }

    function getTraits(uint256 tokenId) public view returns (Trait[] memory) {
        (
            MetroTokenProperties memory tokenProperties,
            MetroThemeV2 memory theme,
            MetroMapResult memory mapResult
        ) = generateAllMapDataFor(tokenId, 0);

        return getAllTraits(tokenProperties, theme, mapResult);
    }

    function getJSConfigJSON(
        uint256 tokenId
    ) public view returns (string memory) {
        (
            MetroTokenProperties memory tokenProperties,
            MetroThemeV2 memory theme,
            MetroMapResult memory mapResult
        ) = generateAllMapDataFor(tokenId, 1);

        return generateJSConfigJSON(tokenProperties, theme, mapResult.svg);
    }

    function getJSConfigJSONWithCustomTheme(
        uint256 tokenId,
        MetroThemeV2 memory theme
    ) public view returns (string memory) {
        MetroTokenProperties memory tokenProperties = IMetroV2(metroAddress)
            .getTokenProperties(tokenId);

        MetroMapResult memory mapResult = IMetroMapGeneratorV2(mapGenerator)
            .generateMap(tokenProperties, theme, tokenId, 1);

        return generateJSConfigJSON(tokenProperties, theme, mapResult.svg);
    }

    // MARK: - Internal

    function generateAllMapDataFor(
        uint256 tokenId,
        uint256 mode,
        MetroTokenProperties memory tokenProperties
    )
        internal
        view
        returns (
            MetroTokenProperties memory,
            MetroThemeV2 memory,
            MetroMapResult memory
        )
    {
        bool shouldFilterByDate;
        uint256 beforeDate;
        if (tokenProperties.mode == 0) {
            shouldFilterByDate = false;
            beforeDate = 0;
        } else {
            shouldFilterByDate = true;
            beforeDate = tokenProperties.seedSetDate;
        }

        MetroThemeV2 memory theme = themeStorage.getRandomTheme(
            tokenProperties.seed,
            tokenId,
            shouldFilterByDate,
            beforeDate
        );

        MetroMapResult memory mapResult = IMetroMapGeneratorV2(mapGenerator)
            .generateMap(tokenProperties, theme, tokenId, mode);
        return (tokenProperties, theme, mapResult);
    }

    function generateAllMapDataFor(
        uint256 tokenId,
        uint256 mode
    )
        internal
        view
        returns (
            MetroTokenProperties memory,
            MetroThemeV2 memory,
            MetroMapResult memory
        )
    {
        MetroTokenProperties memory tokenProperties = IMetroV2(metroAddress)
            .getTokenProperties(tokenId);
        MetroInternalTokenState memory tokenState = IMetroV2(metroAddress)
            .tokenStates(tokenId);

        tokenProperties.seedSetDate = tokenState.baseSeedSetDate;

        return generateAllMapDataFor(tokenId, mode, tokenProperties);
    }

    function generateFullMetadataFor(
        uint256 tokenId
    ) internal view returns (string memory) {
        (
            MetroTokenProperties memory tokenProperties,
            MetroThemeV2 memory theme,
            MetroMapResult memory mapResult
        ) = generateAllMapDataFor(tokenId, 1);

        bytes memory svg = mapResult.svg;

        Trait[] memory allTraits = getAllTraits(
            tokenProperties,
            theme,
            mapResult
        );

        bytes memory metedataDescription = abi.encodePacked(
            "an on-chain, evolving, interactive metro! Double click, use mouse wheel or pinch to zoom in. When zoomed in, tap and drag to explore the metro map.",
            " Theme by ",
            theme.creator
        );

        bytes memory metadata = abi.encodePacked(
            '{"name":"metro #',
            LibString.toString(tokenId),
            '", "description": "',
            metedataDescription,
            '", "image":',
            '"data:image/svg+xml;utf8,',
            svg,
            '","animation_url":"',
            getAnimationURL(tokenProperties, theme, svg),
            '","attributes": [',
            getJSONAttributes(allTraits),
            "]}"
        );
        return
            string(
                abi.encodePacked(
                    "data:application/json;base64,",
                    Base64.encode(metadata)
                )
            );
    }

    function getAnimationURL(
        MetroTokenProperties memory tokenProperties,
        MetroThemeV2 memory theme,
        bytes memory rawSVG
    ) public view returns (bytes memory) {
        bytes memory controllerScript = abi.encodePacked(
            'let theMetroConfig={seed:"',
            LibString.toHexString(uint256(tokenProperties.seed)),
            '",svgData:"',
            rawSVG,
            '",theme:',
            getThemeJSObject(theme),
            "};_sb.scripts.theMetro=theMetro(theMetroConfig);_sb.scripts.theMetro.start()"
        );

        InlineScriptRequest[] memory requests = new InlineScriptRequest[](4);
        requests[0].name = "scriptyBase";
        requests[0].contractAddress = scriptyStorageAddress;

        requests[1].name = "intart_random";
        requests[1].contractAddress = scriptyStorageAddress;

        requests[2].name = "intart_the_metro_v2";
        requests[2].contractAddress = scriptyStorageAddress;

        requests[3].scriptContent = controllerScript;

        return
            scriptyBuilder.getEncodedHTMLInline(
                requests,
                HTMLBufferAllocation + controllerScript.length
            );
    }

    function generateJSConfigJSON(
        MetroTokenProperties memory tokenProperties,
        MetroThemeV2 memory theme,
        bytes memory rawSVG
    ) public pure returns (string memory) {
        return
            string(
                abi.encodePacked(
                    '{"seed":"',
                    LibString.toHexString(uint256(tokenProperties.seed)),
                    '","svgData":"',
                    rawSVG,
                    '","theme":',
                    getThemeJSObject(theme),
                    "}"
                )
            );
    }

    function getThemeJSObject(
        MetroThemeV2 memory theme
    ) public pure returns (string memory) {
        string memory memoryLineColors;
        for (uint256 i; i < theme.lineColors.length; i++) {
            memoryLineColors = string(
                abi.encodePacked(
                    memoryLineColors,
                    '["',
                    theme.lineColors[i],
                    '","',
                    theme.wagonColors[i],
                    '"]'
                )
            );
            if (i != theme.lineColors.length - 1) {
                memoryLineColors = string(
                    abi.encodePacked(memoryLineColors, ",")
                );
            }
        }
        string memory themeObject = string(
            abi.encodePacked(
                '{"b": "',
                theme.backgroundColor,
                '", "sf": "',
                theme.stopFillColor,
                '", "ss": "',
                theme.stopStrokeColor,
                '", "ls": "',
                theme.lineStrokeColor,
                '","lineColors":[',
                memoryLineColors,
                "]}"
            )
        );
        return themeObject;
    }

    function getAllTraits(
        MetroTokenProperties memory tokenProperties,
        MetroThemeV2 memory theme,
        MetroMapResult memory mapResult
    ) internal pure returns (Trait[] memory) {
        Trait[] memory allTraits = new Trait[](6);

        allTraits[0].typeName = "Theme";
        allTraits[0].valueName = theme.name;

        if (tokenProperties.mode == 1) {
            if (tokenProperties.progress == tokenProperties.maxProgress) {
                allTraits[1].typeName = "Mode";
                allTraits[1].valueName = "Complete";
            } else {
                allTraits[1].typeName = "Mode";
                allTraits[1].valueName = "Evolve";
            }
        } else if (tokenProperties.mode == 2) {
            allTraits[1].typeName = "Mode";
            allTraits[1].valueName = "Lock";
        } else {
            allTraits[1].typeName = "Mode";
            allTraits[1].valueName = "Curate";
        }

        if (tokenProperties.progress == 0) {
            allTraits[2].typeName = "Progress";
            allTraits[2].valueName = "none";
        } else {
            allTraits[2].typeName = "Progress";
            allTraits[2].valueName = LibString.toString(
                tokenProperties.progress
            );
        }

        allTraits[3].typeName = "Line Count";
        allTraits[3].valueName = LibString.toString(mapResult.lineCount);

        allTraits[4].typeName = "Stop Count";
        allTraits[4].valueName = LibString.toString(mapResult.stopCount);

        allTraits[5].typeName = "Curate Count";
        allTraits[5].valueName = LibString.toString(
            tokenProperties.curateCount
        );

        return allTraits;
    }

    function getJSONAttributes(
        Trait[] memory allTraits
    ) internal pure returns (string memory) {
        string memory attributes;
        uint256 i;
        uint256 length = allTraits.length;
        unchecked {
            do {
                attributes = string(
                    abi.encodePacked(
                        attributes,
                        getJSONTraitItem(allTraits[i], i == length - 1)
                    )
                );
            } while (++i < length);
        }
        return attributes;
    }

    function getJSONTraitItem(
        Trait memory trait,
        bool lastItem
    ) internal pure returns (string memory) {
        return
            string(
                abi.encodePacked(
                    '{"trait_type": "',
                    trait.typeName,
                    '", "value": "',
                    trait.valueName,
                    '"}',
                    lastItem ? "" : ","
                )
            );
    }
}
