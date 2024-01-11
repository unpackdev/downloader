// SPDX-License-Identifier: MIT

pragma solidity ^0.8.12;

import "./SSTORE2.sol";
import "./ReentrancyGuard.sol";
import "./Ownable.sol";

import "./RendererCommons.sol";
import "./RectRenderer.sol";
import "./Array.sol";
import "./Integers.sol";
import "./ICoBotsRendererV2.sol";
import "./ICoBotsRenderer.sol";

/*  @title CoBots Renderer V2
    @author Clement Walter
    @dev Update color palette, remove colors and use metta instead of status
*/
contract CoBotsRendererV2 is Ownable, ReentrancyGuard, ICoBotsRendererV2 {
    using Array for string[];
    using Array for bytes[];
    using Integers for uint256;

    address palettePointer;
    address collectionPointer;
    ICoBotsRenderer coBotsRenderer;

    event ColorPaletteChanged(address prevPointer, address newPointer);
    event CollectionChanged(address prevPointer, address newPointer);

    function storePalette(bytes memory palette) public {
        address prevPointer = palettePointer;
        palettePointer = SSTORE2.write(palette);
        emit ColorPaletteChanged(prevPointer, palettePointer);
    }

    function storeCollection(bytes memory traits) public {
        address prevPointer = collectionPointer;
        collectionPointer = SSTORE2.write(traits);
        emit CollectionChanged(prevPointer, collectionPointer);
    }

    constructor(address _coBotsRenderer) {
        coBotsRenderer = ICoBotsRenderer(_coBotsRenderer);
    }

    function getCoBotItems(uint256 tokenId, uint8 seed)
        public
        view
        returns (uint256[] memory)
    {
        (
            uint256 eyesIndex,
            uint256 mouthIndex,
            uint256 antennaIndex,
            uint256 feetIndex
        ) = coBotsRenderer.getRandomItems(tokenId, seed);

        uint256[] memory items = new uint256[](10);
        items[0] = 0; // always Black for the Extravagainza
        items[1] = tokenId / 1000;
        items[2] = (tokenId / 100) % 10;
        items[3] = (tokenId / 10) % 10;
        items[4] = tokenId % 10;
        items[5] = eyesIndex;
        items[6] = mouthIndex;
        items[7] = antennaIndex;
        items[8] = feetIndex;
        items[9] = seed % 2; // Metta "Offline" disabled for the Extravagainza
        return items;
    }

    function imageURI(uint256[] memory items)
        public
        view
        returns (string memory)
    {
        return
            string.concat(
                RendererCommons.DATA_URI,
                coBotsRenderer.SVG_TAG_START(),
                RectRenderer.decodeBytesMemoryToRects(
                    RectRenderer.imageBytes(collectionPointer, items),
                    RendererCommons.getPalette(palettePointer)
                ),
                coBotsRenderer.SVG_TAG_END()
            );
    }

    function tokenData(uint256 tokenId, uint8 seed)
        public
        view
        returns (TokenData memory)
    {
        uint256[] memory items = getCoBotItems(tokenId, seed);

        // Inlined instead of using the encoded names from the RectRenderer because not all the characteristics are
        // used in the Extravagainza, so saving gas with this.
        string[12] memory antenna = [
            "Classic",
            "Serious",
            "Jumpy",
            "Buzzed",
            "Buggy",
            "Punk",
            "Angelic",
            "Impish",
            "Humbled",
            "Western",
            "Royal",
            "Hacky"
        ];
        string[12] memory eyes = [
            "Classic",
            "Cyclops",
            "Awoken",
            "Flirty",
            "Zen",
            "Sadhappy",
            "Unaligned",
            "Smitten",
            "Optimistic",
            "Hacky",
            "Super",
            "Nounish"
        ];
        string[11] memory feet = [
            "Classic",
            "Heavy Duty",
            "Firey",
            "Little Firey",
            "Roller",
            "Little Roller",
            "Energetic",
            "Little Energetic",
            "Hobbled",
            "Ghostly",
            "Pushy"
        ];
        string[2] memory metta = ["Off", "On"];
        string[11] memory mouth = [
            "Classic",
            "Worried",
            "Knightly",
            "Shy",
            "Happy",
            "Bigsad",
            "Smug",
            "Wowed",
            "Thirsty",
            "Villainous",
            "Shady"
        ];

        Attribute[] memory attributes = new Attribute[](5);
        attributes[0] = Attribute("Antenna", antenna[items[7]]);
        attributes[1] = Attribute("Eyes", eyes[items[5]]);
        attributes[2] = Attribute("Feet", feet[items[8]]);
        attributes[3] = Attribute("Metta", metta[items[9]]);
        attributes[4] = Attribute("Mouth", mouth[items[6]]);
        return
            TokenData(
                imageURI(items),
                "Co-Bots are cooperation robots | CC0 & 100% On-Chain | co-bots.com.",
                string.concat("Co-Bot #", tokenId.toString()),
                attributes
            );
    }

    function tokenURI(uint256 tokenId, uint8 seed)
        public
        view
        returns (string memory)
    {
        TokenData memory _tokenData = tokenData(tokenId, seed);
        string[] memory attributes = new string[](_tokenData.attributes.length);
        for (uint256 i = 0; i < _tokenData.attributes.length; i++) {
            attributes[i] = string.concat(
                '{"trait_type": "',
                _tokenData.attributes[i].trait_type,
                '", "value": "',
                _tokenData.attributes[i].value,
                '"}'
            );
        }
        return
            string.concat(
                "data:application/json,",
                '{"image": "',
                _tokenData.image,
                '"',
                ',"description": "',
                _tokenData.description,
                '"',
                ',"name": "',
                _tokenData.name,
                '"',
                ',"attributes": ',
                "[",
                attributes.join(","),
                "]",
                "}"
            );
    }
}
