// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "./SSTORE2.sol";
import "./ReentrancyGuard.sol";
import "./Ownable.sol";
import "./Strings.sol";
import "./BytesLib.sol";

import "./Integers.sol";
import "./ChainRunnersConstants.sol";

import "./IChainRunners.sol";
import "./IDreamersRenderer.sol";

/*  @title Dreamers Renderer
    @author Clement Walter
    @dev Leverage the d attributes of svg <path> to encode a palette of base traits. Each runner trait
         is encoded as a combination of these base traits. More precisely, the Dreamers encoding scheme works as follows:
         - each one of the 330 traits is encoded as a list of <path />
         - each path combines a `d` and a `fill`
         - the storage contains the all the possible `d` and all the possible `fill`
         - each trait is then an ordered list of tuples (index of d, index of fill)
         - each dreamer is a list a trait and consequently still an ordered list of (index of d, index of fill)
*/
contract DreamersRenderer is
    IDreamersRenderer,
    Ownable,
    ReentrancyGuard,
    ChainRunnersConstants
{
    using Integers for uint8;
    using Strings for uint256;

    // We have a total of 3 bytes = 24 bits per Path
    uint8 public constant BITS_PER_D_INDEX = 12;
    uint8 public constant BITS_PER_FILL_INDEX = 12;

    // Each D is encoded with a sequence of 2 bits for each letter (M, L, Q, C) and 1 byte per attribute. Since each
    // letter does not have the same number of attributes, this number if stored as constant below as well.
    uint8 public constant BITS_PER_D_ATTRIBUTE = 3;
    bytes8 public constant D_ATTRIBUTE_PALETTE = hex"4d4c51434148565a"; // M L Q C A H V Z
    bytes8 public constant D_ATTRIBUTE_PARAMETERS_COUNT = hex"0202040607010100"; // 2 2 4 6 7 1 1 0
    bytes3 public constant NONE_COLOR = hex"000001";
    bytes public constant PATH_TAG_START = bytes("%3cpath%20d='");
    bytes public constant FILL_TAG = bytes("'%20fill='");
    bytes public constant STROKE_TAG = bytes("'%20stroke='%23000");
    bytes public constant PATH_TAG_END = bytes("'/%3e");
    bytes public constant HASHTAG = bytes("%23");
    bytes public constant SPACE = bytes("%20");
    bytes public constant SVG_TAG_START =
        bytes(
            "%3csvg%20xmlns='http://www.w3.org/2000/svg'%20viewBox='0%200%20255%20255'%20width='500px'%20height='500px'%3e"
        );
    bytes public constant SVG_TAG_END =
        bytes("%3cstyle%3epath{stroke-width:0.71}%3c/style%3e%3c/svg%3e");

    string public _baseURI = "";

    struct Trait {
        uint16 dIndex;
        uint16 fillIndex;
        bool stroke;
    }

    address public fillPalette;
    address[] public dPalette;
    address public dPaletteIndexes;
    address public traitPalette;
    address public traitPaletteIndexes;
    bytes layerIndexes;
    IChainRunners runnersToken;

    ////////////////////////////////////////////////////////////////////////////////
    ////////////////////////////  Rendering mechanics  /////////////////////////////
    ////////////////////////////////////////////////////////////////////////////////
    /// @dev Colors are concatenated and stored in a single 'bytes' with SSTORE2 to save gas.
    function setFillPalette(bytes calldata _fillPalette) external onlyOwner {
        fillPalette = SSTORE2.write(_fillPalette);
    }

    /// @dev Only the d parameter is encoded for each path. All the paths are concatenated together to save gas.
    ///      The dPaletteIndexes is used to retrieve the path from the dPalette.
    function setDPalette(bytes[] calldata _pathPalette) external onlyOwner {
        for (uint8 i = 0; i < _pathPalette.length; i++) {
            dPalette.push(SSTORE2.write(_pathPalette[i]));
        }
    }

    /// @dev Since each SSTORE2 slots can contain up to 24kb, indexes need to be uint16, ie. two bytes per index.
    function setDPaletteIndex(bytes calldata _pathPaletteIndex)
        external
        onlyOwner
    {
        dPaletteIndexes = SSTORE2.write(_pathPaletteIndex);
    }

    /// @dev The traits are stored as a list of tuples (d index, fill index). For our case, 12 bits per index is
    ///      enough as 2^12 = 4096 is greater than total number of d and total number of fill to date.
    ///      This could be changed if needed.
    ///      Hence a trait is a sequence of several 3 bytes long (d index, fill index).
    function setTraitPalette(bytes calldata _traitPalette) external onlyOwner {
        traitPalette = SSTORE2.write(_traitPalette);
    }

    /// @dev Since each SSTORE2 slots can contain up to 24kb, indexes need to be uint16, ie. two bytes per index.
    ///      A trait can then be retrieved with traitPalette[traitPaletteIndexes[i]: traitPaletteIndexes[i+1]]
    function setTraitPaletteIndex(bytes calldata _traitPaletteIndex)
        external
        onlyOwner
    {
        traitPaletteIndexes = SSTORE2.write(_traitPaletteIndex);
    }

    /// @dev The trait indexes allow to map from the Chain Runners 2D indexation (trait index, layer index) to the
    ///      current 1D indexation (trait index).
    function setLayerIndexes(bytes calldata _layerIndexes) external onlyOwner {
        layerIndexes = _layerIndexes;
    }

    /// @dev This function will be the pendant of the ChainRunnersBaseRenderer.getLayer ones.
    function getTraitIndex(uint16 _layerIndex, uint16 _itemIndex)
        public
        view
        returns (uint16)
    {
        uint16 traitIndex = BytesLib.toUint16(layerIndexes, _layerIndex * 2);
        uint16 nextTraitIndex = BytesLib.toUint16(
            layerIndexes,
            (_layerIndex + 1) * 2
        );
        if (traitIndex + _itemIndex > nextTraitIndex - 1) {
            return type(uint16).max;
        }

        return traitIndex + _itemIndex;
    }

    /// @dev 3 bytes per color because svg does not handle alpha.
    function getFill(uint16 _index) public view returns (string memory) {
        // TODO: use assembly instead
        bytes memory palette = SSTORE2.read(fillPalette);
        if (
            palette[(_index * 3)] == NONE_COLOR[0] &&
            palette[(_index * 3) + 1] == NONE_COLOR[1] &&
            palette[(_index * 3) + 2] == NONE_COLOR[2]
        ) {
            return "none";
        }

        return
            string(
                bytes.concat(
                    HASHTAG,
                    bytes(uint8(palette[3 * _index]).toString(16, 2)),
                    bytes(uint8(palette[3 * _index + 1]).toString(16, 2)),
                    bytes(uint8(palette[3 * _index + 2]).toString(16, 2))
                )
            );
    }

    /// @dev Get the start and end indexes of the bytes concerning the given d in the dPalette storage.
    function getDIndex(uint16 _index) public view returns (uint32, uint32) {
        // TODO: use assembly instead
        bytes memory _indexes = SSTORE2.read(dPaletteIndexes);
        uint32 start = uint32(BytesLib.toUint16(_indexes, _index * 2));
        uint32 next = uint32(BytesLib.toUint16(_indexes, _index * 2 + 2));
        // Magic reasonable number to deal with overflow
        if (uint32(_index) > 1000 && start < 20000) {
            start = uint32(type(uint16).max) + 1 + start;
        }
        if (uint32(_index) > 2000 && start < 40000) {
            start = uint32(type(uint16).max) + 1 + start;
        }
        if (uint32(_index) > 1000 && next < 20000) {
            next = uint32(type(uint16).max) + 1 + next;
        }
        if (uint32(_index) > 2000 && next < 40000) {
            next = uint32(type(uint16).max) + 1 + next;
        }
        return (start, next);
    }

    /// @dev Retrieve the bytes for the given d from the dPalette storage. The bytes may be split into several SSTORE2
    ///      slots.
    function getDBytes(uint16 _index) public view returns (bytes memory) {
        // TODO: use assembly instead
        (uint32 dIndex, uint32 dIndexNext) = getDIndex(_index);
        uint256 storageIndex = 0;
        bytes memory _dPalette = SSTORE2.read(dPalette[storageIndex]);
        uint256 cumSumBytes = _dPalette.length;
        uint256 pos = dIndex;
        while (dIndex > cumSumBytes - 1) {
            pos -= _dPalette.length;
            storageIndex++;
            _dPalette = SSTORE2.read(dPalette[storageIndex]);
            cumSumBytes += _dPalette.length;
        }
        bytes memory _d = new bytes(dIndexNext - dIndex);
        for (uint256 i = 0; i < _d.length; i++) {
            if (pos > _dPalette.length - 1) {
                storageIndex++;
                _dPalette = SSTORE2.read(dPalette[storageIndex]);
                pos = 0;
            }
            _d[i] = _dPalette[pos];
            pos++;
        }
        return _d;
    }

    /// @dev Decodes the path and returns it as a plain string to be used in the svg path attribute.
    function getD(bytes memory dEncodedBytes)
        public
        pure
        returns (string memory)
    {
        bytes memory d;
        bytes memory bytesBuffer;
        uint32 bitsShift = 0;
        uint16 byteIndex = 0;
        uint8 bitShiftRemainder = 0;
        uint8 dAttributeIndex;
        uint8 dAttributeParameterCount;
        while (
            bitsShift <= dEncodedBytes.length * 8 - (BITS_PER_D_ATTRIBUTE + 8) // at least BITS_PER_D_ATTRIBUTE bits for the d attribute index and 1 byte for the d attribute parameter count
        ) {
            byteIndex = uint16(bitsShift / 8);
            bitShiftRemainder = uint8(bitsShift % 8);

            dAttributeIndex =
                uint8(
                    (dEncodedBytes[byteIndex] << bitShiftRemainder) |
                        (dEncodedBytes[byteIndex + 1] >>
                            (8 - bitShiftRemainder))
                ) >>
                (8 - BITS_PER_D_ATTRIBUTE);

            dAttributeParameterCount = uint8(
                D_ATTRIBUTE_PARAMETERS_COUNT[dAttributeIndex]
            );

            bitsShift += BITS_PER_D_ATTRIBUTE;
            byteIndex = uint16(bitsShift / 8);
            bitShiftRemainder = uint8(bitsShift % 8);
            bytesBuffer = new bytes(dAttributeParameterCount);
            // TODO: use assembly instead
            for (uint8 i = 0; i < dAttributeParameterCount; i++) {
                bytesBuffer[i] =
                    dEncodedBytes[byteIndex + i] <<
                    bitShiftRemainder;
                if (byteIndex + i + 1 < dEncodedBytes.length) {
                    bytesBuffer[i] |=
                        dEncodedBytes[byteIndex + i + 1] >>
                        (8 - bitShiftRemainder);
                }
            }

            d = bytes.concat(
                d,
                D_ATTRIBUTE_PALETTE[dAttributeIndex],
                bytes(uint8(bytesBuffer[0]).toString())
            );
            for (uint8 i = 1; i < dAttributeParameterCount; i++) {
                d = bytes.concat(
                    d,
                    SPACE,
                    bytes(uint8(bytesBuffer[i]).toString())
                );
            }
            bitsShift += 8 * dAttributeParameterCount;
        }
        return string(d);
    }

    /// @dev Used to concat all the traits of a given dreamers given the array of trait indexes.
    function getTraits(uint16[NUM_LAYERS] memory _index)
        public
        view
        returns (Trait[] memory)
    {
        // First: retrieve all bytes indexes
        bytes memory _traitPaletteIndexes = SSTORE2.read(traitPaletteIndexes);
        bytes memory _traitPalette = SSTORE2.read(traitPalette);

        bytes memory traitsBytes;
        uint16 start;
        uint16 next;
        for (uint16 i = 0; i < NUM_LAYERS; i++) {
            if (_index[i] == type(uint16).max) {
                continue;
            }
            start = BytesLib.toUint16(_traitPaletteIndexes, _index[i] * 2);
            next = BytesLib.toUint16(_traitPaletteIndexes, _index[i] * 2 + 2);
            traitsBytes = bytes.concat(
                traitsBytes,
                BytesLib.slice(_traitPalette, start, next - start)
            );
        }

        // Second: retrieve all traits
        bool stroke;
        Trait[] memory traits = new Trait[](traitsBytes.length / 3);
        for (uint256 i = 0; i < traitsBytes.length; i += 3) {
            (uint16 dIndex, uint16 fillIndex) = Integers.load12x2(
                traitsBytes[i],
                traitsBytes[i + 1],
                traitsBytes[i + 2]
            );
            stroke = fillIndex % 2 > 0;
            fillIndex = fillIndex >> 1;
            traits[i / 3] = Trait(dIndex, fillIndex, stroke);
        }
        return traits;
    }

    /// @notice Useful for returning a single Traits in the Runner's meaning
    function getTrait(uint16 _index) public view returns (Trait[] memory) {
        uint16[NUM_LAYERS] memory _indexes;
        _indexes[0] = _index;
        for (uint256 i = 1; i < NUM_LAYERS; i++) {
            _indexes[i] = type(uint16).max;
        }
        return getTraits(_indexes);
    }

    ////////////////////////////////////////////////////////////////////////////////
    /////////////////////////////////  Dreamers  ///////////////////////////////////
    ////////////////////////////////////////////////////////////////////////////////

    /// @dev Each trait is the bytes representation of the final svg string concatenating several <path> elements.
    function getSvg(Trait[] memory traits) public view returns (string memory) {
        bytes memory svg = SVG_TAG_START;
        for (uint16 i = 0; i < traits.length; i++) {
            svg = bytes.concat(
                svg,
                PATH_TAG_START,
                bytes(getD(getDBytes(traits[i].dIndex))),
                FILL_TAG,
                bytes(getFill(traits[i].fillIndex))
            );
            if (traits[i].stroke) {
                svg = bytes.concat(svg, STROKE_TAG);
            }
            svg = bytes.concat(svg, PATH_TAG_END);
        }
        return string(bytes.concat(svg, SVG_TAG_END));
    }

    constructor(
        address _rendererAddress,
        address _runnersTokenAddress,
        string memory baseURI
    ) ChainRunnersConstants(_rendererAddress) {
        runnersToken = IChainRunners(_runnersTokenAddress);
        _baseURI = baseURI;
    }

    /// @notice The Dreamer's full DNA is an alteration of its corresponding Runner's DNA with it's consumed candy.
    ///      The candy ids are hardcoded while it should be better to retrieve their effects from the CandyShop
    ///      contract.
    /// @dev Somehow copied from the original code but returns an array of trait indexes instead of Layer structs.
    ///      Flags for no layer is also updated from empty `Layer` to index = type(uint16).max.
    function getTokenData(uint256 runnerDna, uint8 candy)
        public
        view
        returns (uint16[NUM_LAYERS] memory traitIndexes)
    {
        uint16[NUM_LAYERS] memory dna = splitNumber(runnerDna);
        uint16[NUM_LAYERS] memory candyEffect = splitNumber(
            uint256(keccak256(abi.encodePacked(candy, dna)))
        );

        // Get the raceIndex before any updates as the WEIGHTS are not the same for each race but we want to
        // keep changes tractable in terms of candy effect
        uint16 raceIndex = chainRunnersBaseRenderer.getRaceIndex(dna[1]);

        if (candy % 4 == 0) {
            // CHAIN_METH
            dna[0] = candyEffect[0];
            dna[6] = candyEffect[6];
            dna[7] = candyEffect[7];
            dna[8] = candyEffect[8];
            dna[10] = candyEffect[10];
            dna[11] = candyEffect[11];
            dna[12] = candyEffect[12];
        } else if (candy % 4 == 1) {
            // SOMNUS_TEARS
            dna[1] = candyEffect[1];
            dna[2] = candyEffect[2];
            dna[3] = candyEffect[3];
            dna[4] = candyEffect[4];
            dna[5] = candyEffect[5];
            dna[9] = candyEffect[9];
        }

        bool hasFaceAcc = dna[7] < (NUM_RUNNERS - WEIGHTS[raceIndex][7][7]);
        bool hasMask = dna[8] < (NUM_RUNNERS - WEIGHTS[raceIndex][8][7]);
        bool hasHeadBelow = dna[9] < (NUM_RUNNERS - WEIGHTS[raceIndex][9][36]);
        bool hasHeadAbove = dna[11] <
            (NUM_RUNNERS - WEIGHTS[raceIndex][11][48]);
        bool useHeadAbove = (dna[0] % 2) > 0;
        for (uint8 i = 0; i < NUM_LAYERS; i++) {
            uint8 layerTraitIndex = chainRunnersBaseRenderer.getLayerIndex(
                dna[i],
                i,
                raceIndex
            );
            if ((i == 0) && (candy % 4 == 2)) {
                // HELIUM_SPICE
                if (candyEffect[0] % 10 == 0) {
                    layerTraitIndex = 44;
                }
            }
            uint16 traitIndex = getTraitIndex(i, layerTraitIndex);

            // These conditions help make sure layer selection meshes well visually.
            // 1. If mask, no face/eye acc/mouth acc
            // 2. If face acc, no mask/mouth acc/face
            // 3. If both head above & head below, randomly choose one
            bool consistencyCheck = (((i == 2 || i == 12) &&
                !hasMask &&
                !hasFaceAcc) ||
                (i == 7 && !hasMask) ||
                (i == 10 && !hasMask) ||
                (i < 2 || (i > 2 && i < 7) || i == 8 || i == 9 || i == 11));
            bool noHeadCheck = ((hasHeadBelow &&
                hasHeadAbove &&
                (i == 9 && useHeadAbove)) || (i == 11 && !useHeadAbove));
            bool isRealTrait = traitIndex < type(uint16).max;
            if (!isRealTrait || !consistencyCheck || noHeadCheck) {
                traitIndex = type(uint16).max;
            }
            traitIndexes[i] = traitIndex;
        }
        return traitIndexes;
    }

    /// @notice On-chain rendering of any runner with a given candy
    ///         For on-chain rendering of a given token, retrieve first its candy with `dreamers(tokenId)`
    ///         and give it here. The output can be directly copied/pasted into the browser bar for displaying the image.
    function imageURI(uint256 tokenId, uint8 candy)
        external
        view
        returns (string memory)
    {
        uint256 runnerDna = runnersToken.getDna(tokenId);
        uint16[NUM_LAYERS] memory traitIndexes = getTokenData(runnerDna, candy);
        Trait[] memory traits = getTraits(traitIndexes);
        return string(abi.encodePacked("data:image/svg+xml,", getSvg(traits)));
    }

    /// @notice Off-chain rendering because of Twitter, MetaMask, etc.
    function tokenURI(uint256 tokenId, uint8)
        external
        view
        override
        returns (string memory)
    {
        return
            string(
                abi.encodePacked(
                    bytes(_baseURI),
                    tokenId.toString(),
                    "/metadata"
                )
            );
    }
}
