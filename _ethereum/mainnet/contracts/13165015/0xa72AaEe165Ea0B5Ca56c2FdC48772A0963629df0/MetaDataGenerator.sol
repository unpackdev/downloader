//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.6;

import "./StringLib.sol";
import "./ColorLib.sol";
import "./SceneLib.sol";
import "./Base64.sol";

import "./IMetaDataGenerator.sol";

// Burny boys https://etherscan.io/address/0x18a808dd312736fc75eb967fc61990af726f04e4#code

/**
 * @title MetaDataGenerator
 * @dev Helper contract used to generate metadata and images for the PiggySafe ERC-721 NFTs.
 *      Holds the scenes that are used to generate the SVG fully on-chain encoded using colormap of up to 16 colors.
 */
contract MetaDataGenerator is IMetaDataGenerator {
    string internal constant svgStart =
        '<svg xmlns="http://www.w3.org/2000/svg" xmlns:xlink="http://www.w3.org/1999/xlink" version="1.1" viewBox="0 0 24 24">\n';
    string internal constant svgEnd = '</svg>';

    // The base colors (e.g., 0x00000000) encoded into 2 uint256. Color inserted to value and shifted to tightly pack them.
    uint256[] public baseColorPalette;

    // The colors used for randomize color values (for hats etc). 4 sets each containing 4 colors and then encoded into into 2 uint256
    uint256[] public randomizeColorPalettes;

    // Each layer ("trait") has many different scenes as possiblity, 2d array to store all the scenes. `scenes[0][1]` provides scene 1 for layer 0 etc.
    bytes[][] public scenes;

    string[] public attributeNames;
    string[][] public attributeValues;
    string public constant NOTHING = 'Nothing';

    // The actor who may initiate the values of the contract
    address public owner;

    // flag to freeze the contract details. When ossified, the contract cannot be update ever again.
    bool public override ossified;

    modifier onlyOwner() {
        require(owner == msg.sender, 'Not owner');
        _;
    }

    modifier notOssified() {
        require(!ossified, 'Contract ossified');
        _;
    }

    constructor() {
        owner = msg.sender;
    }

    function init(
        string[] memory _attributeNames,
        string[] memory _attributeValues,
        uint256[] memory _basePalette,
        uint256[] memory _randomizePalette,
        bytes[] memory _scenes,
        uint256[] memory _indexes
    ) public notOssified onlyOwner {
        addLayers(_attributeNames);
        setBaseColorPalette(_basePalette);
        setRandomizeColorPalette(_randomizePalette);
        addScenes(_scenes, _attributeValues, _indexes);
        ossified = true;
        owner = address(0);
    }

    function setBaseColorPalette(uint256[] memory _basePalette) internal {
        baseColorPalette = _basePalette;
    }

    function setRandomizeColorPalette(uint256[] memory _randomizePalette) internal {
        randomizeColorPalettes = _randomizePalette;
    }

    function addLayers(string[] memory _attributeNames) internal {
        for (uint8 i = 0; i < _attributeNames.length; i++) {
            scenes.push();
            attributeValues.push();
            attributeNames.push(_attributeNames[i]);
        }
    }

    function addScenes(
        bytes[] memory _scenes,
        string[] memory _attributeValues,
        uint256[] memory _indexes
    ) internal {
        require(_scenes.length == _indexes.length, 'Invalid size');
        require(_attributeValues.length == _indexes.length, 'Invalid size');
        for (uint8 i = 0; i < _indexes.length; i++) {
            scenes[_indexes[i]].push(_scenes[i]);
            attributeValues[_indexes[i]].push(_attributeValues[i]);
        }
    }

    /**
     * @dev Helper function that creates a `colorPalette` based on the basis colors + 4 colors chosen from the `randomizeColorPalettes` using the
     *      `activeGene` byte 0-4 as indexes. Allows us to have different colored hats based on the gene.
     * @param activeGene The active gene of the piggy to construct a palette for
     * @return colorPalette The color palette for the active gene.
     */
    function constructPalette(uint256 activeGene)
        internal
        view
        returns (uint256[] memory colorPalette)
    {
        colorPalette = new uint256[](2);
        colorPalette[0] = baseColorPalette[0];
        colorPalette[1] = baseColorPalette[1];

        // insert at indexes 12, 13, 14, 15 from the randomizer
        for (uint8 i = 0; i < 4; i++) {
            // first move 4*i indexes to get to the right subset of the colors
            // then ((activeGene >> (4 * i)) & 0x0f) % f is to get the index in the logical color to insert at 12 + i
            uint256 activeIndex = 4 * i + (((activeGene >> (4 * i)) & 0x0f) % 4);
            uint256 color = ColorLib.getColor(randomizeColorPalettes, activeIndex);
            colorPalette[1] += color * (256**((4 + i) * 4)); // each color use 4 bytes so we add it at value bytes* (4+i*4), e.g., starting at byte 16 and moving 4 bytes at a time until 32
        }
    }

    /**
     * @dev Return a flattened composite and color mapping for specific `activeGene`.
     *      The composite is constructed from using the scenes specified by `activeGene`,
     *      `colorPalette` is useful for mapping the values in the composite to hex color values.
     *      Note: Very gas entensive as it loops through the active scenes and add to the composite.
     * @return composite return a flattened 24*24 matrix (576 array) and colorPalette
     */
    function getEncodedData(uint256 activeGene) public view override returns (EncodedData memory) {
        uint8[576] memory composite;
        string[] memory attributes = new string[](scenes.length);
        uint256[] memory colorPalette = constructPalette(activeGene);

        activeGene >>= 16; // Get past the colors. // We could probably just do it inside 1 byte
        // Only run while when there is possible layers to add

        for (uint256 layerIndex = 0; layerIndex < scenes.length; layerIndex++) {
            bool isActive = layerIndex == 0 || (activeGene & 0x0f) > 0;
            uint256 sceneIndex = (activeGene & 0x0f) % scenes[layerIndex].length;
            attributes[layerIndex] = isActive ? attributeValues[layerIndex][sceneIndex] : NOTHING;

            if (isActive) {
                uint256[9] memory words = SceneLib.decodeToWords(scenes[layerIndex][sceneIndex]);
                uint256 compositeIndex = 0;
                for (uint8 i = 0; i < 9; i++) {
                    if (words[i] == 0) {
                        compositeIndex += 64;
                        continue;
                    }
                    uint8[64] memory vals = SceneLib.decodeWord(words[i]);
                    for (uint8 j = 0; j < 64; j++) {
                        if (vals[j] > 0) {
                            composite[compositeIndex + j] = vals[j];
                        }
                    }
                    compositeIndex += 64;
                }
            }
            activeGene >>= 4;
        }

        return EncodedData(composite, colorPalette, attributes);
    }

    function ethBalanceLine(uint256 balance) internal pure returns (string memory) {
        return
            string(
                abi.encodePacked(
                    '<text x="1" y="23" fill="green" font-family="sans-serif" font-size="1.25">',
                    StringLib.toBalanceString(balance, 3),
                    'ETH</text>\n'
                )
            );
    }

    /**
     * @dev Creates a SVG image with the specified params. Very gas intensive because of heavy use of string manipulation for SVG file
     * have optimisations for adding lines as single strings, otherwise adding pixels one by one. Without optimisation, full image will > gasLimit.
     * @param activeGene The active gene of the piggy
     * @param balance The amount of eth that the piggy contains
     * @return svg Contents of a svg image.
     */
    function getSVG(uint256 activeGene, uint256 balance)
        public
        view
        override
        returns (string memory)
    {
        EncodedData memory data = getEncodedData(activeGene);
        return createSVG(data.composite, data.colorPalette, balance);
    }

    function createSVG(
        uint8[576] memory composite,
        uint256[] memory colorPalette,
        uint256 balance
    ) internal pure returns (string memory svg) {
        svg = string(abi.encodePacked(svgStart));

        string[] memory colors = new string[](16);
        for (uint8 i = 1; i < colors.length; i++) {
            colors[i] = StringLib.toHexColor(ColorLib.getColor(colorPalette, i));
        }
        string[] memory location = new string[](24);
        for (uint8 i = 0; i < 24; i++) {
            location[i] = StringLib.toString(i);
        }

        for (uint32 y = 0; y < 24; y++) {
            uint32 xStart = 0;
            uint32 xEnd = 0;
            uint256 lastVal = 0;
            for (uint32 x = 0; x < 24; x++) {
                uint256 val = composite[y * 24 + x];
                // Add to the current line
                if (val == lastVal) {
                    xEnd = x;
                } else {
                    // Add current line if value is NOT invisible, then reset line
                    if (lastVal > 0) {
                        svg = string(
                            abi.encodePacked(
                                svg,
                                '<rect x ="',
                                location[xStart],
                                '" y="',
                                location[y],
                                '" width="',
                                location[xEnd - xStart + 1],
                                '" height="1" shape-rendering="crispEdges" fill="#',
                                colors[lastVal],
                                '"/>\n'
                            )
                        );
                    }
                    xStart = x;
                    xEnd = x;
                    lastVal = val;
                }
            }
            // If value is NOT invisible add it
            if (lastVal > 0) {
                svg = string(
                    abi.encodePacked(
                        svg,
                        '<rect x ="',
                        location[xStart],
                        '" y="',
                        location[y],
                        '" width="',
                        location[xEnd - xStart + 1],
                        '" height="1" shape-rendering="crispEdges" fill="#',
                        colors[lastVal],
                        '"/>\n'
                    )
                );
            }
        }
        svg = string(abi.encodePacked(svg, ethBalanceLine(balance), svgEnd));
    }

    /**
     * @dev Generate a string with the attributes
     * @param attributes The Attributes (layer, scene)[] to add
     * @param balance The amount of tokens stored in the Piggy
     * @param activeGene the active gene
     * @return attributeString
     */
    function toAttributeString(
        string[] memory attributes,
        uint256 balance,
        uint256 activeGene
    ) internal view returns (string memory attributeString) {
        attributeString = string(
            abi.encodePacked(
                '"attributes": [{"trait_type": "balance", "value": ',
                StringLib.toBalanceString(balance, 3),
                '}, {"trait_type": "colorgene", "value": "',
                StringLib.toHex(activeGene & 0xffff),
                '"}'
            )
        );

        for (uint8 i = 0; i < attributes.length; i++) {
            attributeString = string(
                abi.encodePacked(
                    attributeString,
                    ', {"trait_type" : "',
                    attributeNames[i],
                    '", "value": "',
                    attributes[i],
                    '"}'
                )
            );
        }

        attributeString = string(abi.encodePacked(attributeString, ']'));
    }

    function tokenURI(MetaDataParams memory params) public view override returns (string memory) {
        string memory name = string(
            abi.encodePacked('CryptoPiggy #', StringLib.toString(params.tokenId))
        );
        string memory tokenOwner = StringLib.toHex(uint160(params.owner), 20);
        string memory description = 'The mighty holder of coin';
        EncodedData memory data = getEncodedData(params.activeGene);
        string memory image = Base64.encode(
            bytes(createSVG(data.composite, data.colorPalette, params.balance))
        );

        return
            string(
                abi.encodePacked(
                    'data:application/json;base64,',
                    Base64.encode(
                        bytes(
                            abi.encodePacked(
                                '{"name":"',
                                name,
                                '", "description":"',
                                description,
                                '",',
                                toAttributeString(
                                    data.attributes,
                                    params.balance,
                                    params.activeGene
                                ),
                                ',"owner":"',
                                tokenOwner,
                                '", "image": "data:image/svg+xml;base64,',
                                image,
                                '"}'
                            )
                        )
                    )
                )
            );
    }
}
