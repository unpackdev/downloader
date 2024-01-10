// SPDX-License-Identifier: MIT

pragma solidity ^0.8.12;

import "./SSTORE2.sol";
import "./ReentrancyGuard.sol";
import "./Ownable.sol";
import "./Strings.sol";
import "./BytesLib.sol";

import "./Integers.sol";
import "./ICoBotsRenderer.sol";

/*  @title CoBots Renderer
    @author Clement Walter
    @dev Encode each traits as a "sum" of `rect`, each rect being stored using 4 bytes
*/
contract CoBotsRenderer is Ownable, ReentrancyGuard, ICoBotsRenderer {
    using Integers for uint8;
    using Strings for uint256;

    // We have a total of 4 * 6 = 24 bits = 3 bytes for coordinates + 1 byte for the color
    // Hence each rect is 4 bytes
    uint8 public constant BITS_PER_COORDINATES = 6;
    uint8 public constant BITS_PER_FILL_INDEX = 8;

    string public constant RECT_TAG_START = "%3crect%20x=%27";
    string public constant Y_TAG = "%27%20y=%27";
    string public constant WIDTH_TAG = "%27%20width=%27";
    string public constant HEIGHT_TAG = "%27%20height=%27";
    string public constant FILL_TAG = "%27%20fill=%27%23";
    string public constant RECT_TAG_END = "%27/%3e";
    string public constant SVG_TAG_START =
        "%3csvg%20xmlns=%27http://www.w3.org/2000/svg%27%20viewBox=%270%200%2045%2045%27%20width=%27450px%27%20height=%27450px%27%3e";
    string public constant SVG_TAG_END =
        "%3cstyle%3erect{shape-rendering:crispEdges}%3c/style%3e%3c/svg%3e";

    address public fillPalette;
    address public traitPalette;
    address public traitPaletteIndexes; // where each trait begins in the traits' palette
    bytes public layerIndexes; // the index of the first item of each layer, uint8/bytes1 for each layer

    ////////////////////////////////////////////////////////////////////////////////
    ////////////////////////////  Rendering mechanics  /////////////////////////////
    ////////////////////////////////////////////////////////////////////////////////
    /// @dev Colors are concatenated and stored in a single 'bytes' with SSTORE2 to save gas.
    function setFillPalette(bytes calldata _fillPalette) external onlyOwner {
        fillPalette = SSTORE2.write(_fillPalette);
    }

    /// @dev All the rects are concatenated together to save gas.
    ///      The traitPaletteIndexes is used to retrieve the rect from the traitPalette.
    function setTraitPalette(bytes calldata _traitPalette) external onlyOwner {
        traitPalette = SSTORE2.write(_traitPalette);
    }

    /// @dev Since each SSTORE2 slots can contain up to 24kb, indexes need to be uint16, ie. two bytes per index.
    function setTraitPaletteIndexes(bytes calldata _traitPaletteIndexes)
        external
        onlyOwner
    {
        traitPaletteIndexes = SSTORE2.write(_traitPaletteIndexes);
    }

    /// @dev Traits are stored as a plain list while the rendering works with layer and items within each layer.
    ///      Since each layer has a variable number of items, we store the index of the first trait of each layer.
    function setLayerIndexes(bytes calldata _layerIndexes) external onlyOwner {
        layerIndexes = _layerIndexes;
    }

    /// @dev 3 bytes per color because svg does not handle alpha.
    function getFill(uint256 _index) public view returns (string memory) {
        bytes memory palette = SSTORE2.read(fillPalette);
        return
            string.concat(
                uint8(palette[3 * _index]).toString(16, 2),
                uint8(palette[3 * _index + 1]).toString(16, 2),
                uint8(palette[3 * _index + 2]).toString(16, 2)
            );
    }

    /// @dev This function lets map from layerIndex and itemIndex to traitIndex.
    function getTraitIndex(uint256 _layerIndex, uint256 _itemIndex)
        public
        view
        returns (uint256)
    {
        uint8 traitIndex = uint8(layerIndexes[_layerIndex]);
        uint8 nextTraitIndex = uint8(layerIndexes[_layerIndex + 1]);
        if (traitIndex + _itemIndex > nextTraitIndex - 1) {
            return type(uint8).max;
        }

        return _itemIndex + traitIndex;
    }

    /// @dev Retrieve the bytes for the given trait from the traitPalette storage.
    function getTraitBytes(uint256 _index) public view returns (bytes memory) {
        bytes memory _indexes = SSTORE2.read(traitPaletteIndexes);
        uint32 start = uint32(BytesLib.toUint16(_indexes, _index * 2));
        uint32 next = uint32(BytesLib.toUint16(_indexes, _index * 2 + 2));
        bytes memory _traitPalette = SSTORE2.read(traitPalette);
        return BytesLib.slice(_traitPalette, start, next - start);
    }

    function decodeRect(bytes memory rectBytes)
        public
        view
        returns (string memory)
    {
        return decodeRect(rectBytes, 0, 0);
    }

    function decodeRect(
        bytes memory rectBytes,
        uint8 offsetX,
        uint8 offsetY
    ) public view returns (string memory) {
        require(rectBytes.length == 4, "Rect bytes must be 4 bytes long");
        string memory fill = getFill(uint8(rectBytes[3]));
        return
            string.concat(
                RECT_TAG_START,
                (uint8(rectBytes[0] >> 2) + offsetX).toString(),
                Y_TAG,
                (uint8(((rectBytes[0] << 4) | (rectBytes[1] >> 4)) & 0x3f) +
                    offsetY).toString(),
                WIDTH_TAG,
                uint8(((rectBytes[1] << 2) & 0x3f) | (rectBytes[2] >> 6))
                    .toString(),
                HEIGHT_TAG,
                uint8(rectBytes[2] & 0x3f).toString(),
                FILL_TAG,
                fill,
                RECT_TAG_END
            );
    }

    function decode8Rects(bytes32 rectsBytes)
        public
        view
        returns (string memory)
    {
        return
            string.concat(
                decodeRect(
                    bytes.concat(
                        rectsBytes[0],
                        rectsBytes[1],
                        rectsBytes[2],
                        rectsBytes[3]
                    )
                ),
                decodeRect(
                    bytes.concat(
                        rectsBytes[4],
                        rectsBytes[5],
                        rectsBytes[6],
                        rectsBytes[7]
                    )
                ),
                decodeRect(
                    bytes.concat(
                        rectsBytes[8],
                        rectsBytes[9],
                        rectsBytes[10],
                        rectsBytes[11]
                    )
                ),
                decodeRect(
                    bytes.concat(
                        rectsBytes[12],
                        rectsBytes[13],
                        rectsBytes[14],
                        rectsBytes[15]
                    )
                ),
                decodeRect(
                    bytes.concat(
                        rectsBytes[16],
                        rectsBytes[17],
                        rectsBytes[18],
                        rectsBytes[19]
                    )
                ),
                decodeRect(
                    bytes.concat(
                        rectsBytes[20],
                        rectsBytes[21],
                        rectsBytes[22],
                        rectsBytes[23]
                    )
                ),
                decodeRect(
                    bytes.concat(
                        rectsBytes[24],
                        rectsBytes[25],
                        rectsBytes[26],
                        rectsBytes[27]
                    )
                ),
                decodeRect(
                    bytes.concat(
                        rectsBytes[28],
                        rectsBytes[29],
                        rectsBytes[30],
                        rectsBytes[31]
                    )
                )
            );
    }

    function decode32Rects(bytes memory rectsBytes)
        public
        view
        returns (string memory)
    {
        return
            string.concat(
                decode8Rects(BytesLib.toBytes32(rectsBytes, 0)),
                decode8Rects(BytesLib.toBytes32(rectsBytes, 32)),
                decode8Rects(BytesLib.toBytes32(rectsBytes, 64)),
                decode8Rects(BytesLib.toBytes32(rectsBytes, 96))
            );
    }

    /// @dev Decode the rect and returns it as a plain string to be used in the svg rect attribute.
    ///      One rect is 4 bytes so 8 rects is a bytes32.
    ///      With 20 bytes32, we have up to 160 rects per trait / co-bots actually if we concat the bytes first.
    ///      This magic number comes from a small data analysis of the traits. We use the fact that an empty
    ///      bytes32 will lead to an empty rect (width and height 0).
    function getTrait(bytes memory traitEncodedBytes)
        public
        view
        returns (string memory)
    {
        // buffer is 20 * 32 bytes = up to 160 rects
        bytes memory buffer = bytes.concat(
            traitEncodedBytes,
            new bytes(640 - traitEncodedBytes.length)
        );
        return
            string.concat(
                SVG_TAG_START,
                decode32Rects(BytesLib.slice(buffer, 0, 128)),
                decode32Rects(BytesLib.slice(buffer, 128, 128)),
                decode32Rects(BytesLib.slice(buffer, 256, 128)),
                decode32Rects(BytesLib.slice(buffer, 384, 128)),
                decode32Rects(BytesLib.slice(buffer, 512, 128)),
                SVG_TAG_END
            );
    }

    function getImageURI(bytes memory traitEncodedBytes)
        public
        view
        returns (string memory)
    {
        return
            string.concat("data:image/svg+xml,", getTrait(traitEncodedBytes));
    }

    ////////////////////////////////////////////////////////////////////////////////
    /////////////////////////////////  Co-bots  ////////////////////////////////////
    ////////////////////////////////////////////////////////////////////////////////

    function getRandomItems(uint256 tokenId, uint8 seed)
        public
        pure
        returns (
            uint256 eyesIndex,
            uint256 mouthIndex,
            uint256 antennaIndex,
            uint256 feetIndex
        )
    {
        uint256 randomBotMemory = uint256(
            keccak256(abi.encodePacked(tokenId, seed))
        );

        // Eyes
        uint256 randomEyes = randomBotMemory % 10_000;
        randomBotMemory >>= 14;
        eyesIndex = randomEyes < 25
            ? 11
            : (randomEyes < 75 ? 10 : randomEyes % 10);

        // Mouth
        uint256 randomMouth = randomBotMemory % 10_000;
        randomBotMemory >>= 14;
        mouthIndex = randomMouth < 50 ? 10 : randomMouth % 10;

        // Antenna
        uint256 randomAntenna = randomBotMemory % 10_000;
        randomBotMemory >>= 14;
        antennaIndex = randomAntenna < 50
            ? 10
            : (randomAntenna < 75 ? 11 : randomAntenna % 10);

        // Feet
        uint256 randomFeet = randomBotMemory % 10_000;
        randomBotMemory >>= 14;
        feetIndex = randomFeet < 50 ? 10 : randomFeet % 10;
    }

    function getToadItems()
        public
        pure
        returns (
            uint256 eyesIndex,
            uint256 mouthIndex,
            uint256 antennaIndex,
            uint256 feetIndex
        )
    {
        return (0, 0, 12, 6);
    }

    function getNounishItems()
        public
        pure
        returns (
            uint256 eyesIndex,
            uint256 mouthIndex,
            uint256 antennaIndex,
            uint256 feetIndex
        )
    {
        return (0, 0, 13, 0);
    }

    function getWizardItems()
        public
        pure
        returns (
            uint256 eyesIndex,
            uint256 mouthIndex,
            uint256 antennaIndex,
            uint256 feetIndex
        )
    {
        return (0, 0, 14, 9);
    }

    function getCoBotItems(
        uint256 tokenId,
        uint8 seed,
        bool status,
        bool color
    ) public pure returns (uint256[10] memory) {
        uint256 eyesIndex;
        uint256 mouthIndex;
        uint256 antennaIndex;
        uint256 feetIndex;
        if (tokenId == 0) {
            (eyesIndex, mouthIndex, antennaIndex, feetIndex) = getToadItems();
        } else if (tokenId == 1) {
            (
                eyesIndex,
                mouthIndex,
                antennaIndex,
                feetIndex
            ) = getNounishItems();
        } else if (tokenId == 2) {
            (eyesIndex, mouthIndex, antennaIndex, feetIndex) = getWizardItems();
        } else {
            (eyesIndex, mouthIndex, antennaIndex, feetIndex) = getRandomItems(
                tokenId,
                seed
            );
        }

        uint256[10] memory items;
        // 0. Colour
        items[0] = color ? 0 : 1;
        // 1. Digit 1
        items[1] = tokenId / 1000;
        // 2. Digit 2
        items[2] = (tokenId / 100) % 10;
        // 3. Digit 3
        items[3] = (tokenId / 10) % 10;
        // 4. Digit 4
        items[4] = tokenId % 10;
        // 5. Eyes
        items[5] = eyesIndex;
        // 6. Mouth
        items[6] = mouthIndex;
        // 7. Antenna
        items[7] = antennaIndex;
        // 8. Status
        items[8] = status ? 1 : 0;
        // 9. Feet
        items[9] = feetIndex;
        return items;
    }

    function getCoBotBytes(uint256[10] memory items)
        public
        view
        returns (bytes memory)
    {
        return
            bytes.concat(
                getTraitBytes(getTraitIndex(0, items[0])),
                getTraitBytes(getTraitIndex(1, items[1])),
                getTraitBytes(getTraitIndex(2, items[2])),
                getTraitBytes(getTraitIndex(3, items[3])),
                getTraitBytes(getTraitIndex(4, items[4])),
                getTraitBytes(getTraitIndex(5, items[5])),
                getTraitBytes(getTraitIndex(6, items[6])),
                getTraitBytes(getTraitIndex(7, items[7])),
                items[8] == 1
                    ? new bytes(4)
                    : getTraitBytes(getTraitIndex(8, items[8])),
                getTraitBytes(getTraitIndex(9, items[9]))
            );
    }

    function getCoBotImageURI(uint256[10] memory items)
        public
        view
        returns (string memory)
    {
        return getImageURI(getCoBotBytes(items));
    }

    function getCoBotAttributes(
        uint256[10] memory items,
        bool status,
        bool color
    ) public pure returns (string memory) {
        string[12] memory eyes = [
            "Classic", // 0
            "Cyclops", // 1
            "Awoken", // 2
            "Flirty", // 3
            "Zen", // 4
            "Sadhappy", // 5
            "Unaligned", // 6
            "Smitten", // 7
            "Optimistic", // 8
            "Hacky", // 9
            "Super", // 50 times
            "Nounish" // 25 times
        ];
        string[11] memory mouths = [
            "Classic", // 0
            "Worried", // 1
            "Knightly", // 2
            "Shy", // 3
            "Happy", // 4
            "Bigsad", // 5
            "Smug", // 6
            "Wowed", // 7
            "Thirsty", // 8
            "Villainous", // 9
            "Shady" // 50 times
        ];
        string[15] memory antennas = [
            "Classic", // 0
            "Serious", // 1
            "Jumpy", // 2
            "Buzzed", // 3
            "Buggy", // 4
            "Punk", // 5
            "Angelic", // 6
            "Impish", // 7
            "Humbled", // 8
            "Western", // 9
            "Royal", // 50 times
            "Hacky", // 25 times
            "!croak", // 1 time
            "Nounish", // 1 time
            "Wizard" // 1 time
        ];
        string[11] memory feet = [
            "Classic", // 0
            "Heavy Duty", // 1
            "Firey", // 2
            "Little Firey", // 3
            "Roller", // 4
            "Little Roller", // 5
            "Energetic", // 6
            "Little Energetic", // 7
            "Hobbled", // 8
            "Ghostly", // 9
            "Pushy" // 50 times
        ];
        return
            string.concat(
                "[",
                items[7] > 11 ? "" : '{"trait_type": "Eyes", "value": "',
                items[7] > 11 ? "" : eyes[items[5]],
                items[7] > 11 ? "" : '"},',
                items[7] > 11 ? "" : '{"trait_type": "Mouth", "value": "',
                items[7] > 11 ? "" : mouths[items[6]],
                items[7] > 11 ? "" : '"},',
                '{"trait_type": "Antenna", "value": "',
                antennas[items[7]],
                '"},',
                '{"trait_type": "Feet", "value": "',
                feet[items[9]],
                '"},',
                '{"trait_type": "Status", "value": "',
                status ? "Online" : "Offline",
                '"},',
                '{"trait_type": "Color", "value": "',
                color ? "Blue" : "Red",
                '"}',
                "]"
            );
    }

    function tokenURI(
        uint256 tokenId,
        uint8 seed,
        bool status,
        bool color
    ) public view returns (string memory) {
        uint256[10] memory items = getCoBotItems(tokenId, seed, status, color);
        return
            string.concat(
                "data:application/json,",
                '{"image_data": "',
                getCoBotImageURI(items),
                '"',
                ',"description": "Co-Bots are cooperation robots | CC0 & 100% On-Chain | co-bots.com."',
                ',"name": "Co-Bot #',
                tokenId.toString(),
                '"',
                ',"attributes": ',
                getCoBotAttributes(items, status, color),
                "}"
            );
    }
}
