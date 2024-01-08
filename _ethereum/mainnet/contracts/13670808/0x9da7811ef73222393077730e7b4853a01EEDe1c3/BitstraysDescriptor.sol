// SPDX-License-Identifier: GPL-3.0

/// @title The Bitstrays NFT descriptor

/***********************************************************
@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
@@@@@@@@@@@@@@@@@@........................@@@@@@@@@@@@@@@@@@
@@@@@@@@@@@@@%.................................@@@@@@@@@@@@@
.......................@@@@@@@..............................
./@@@@@@@@@...................@@@....*@@@@.......*@@@@@@@@@.
./@@@@@@@.......@@@@@.........@@@.........@@@@@.......@@@@@.
@%..@@.......................................@@.......@@@..@
@%**.........,**.........................................**@
@@@@##.....##(**#######   .........  ,#######  .......###@@@
@@@@@@...@@@@#  @@   @@   .........  ,@@  @@@  .......@@@@@@
@@@@@@.....@@#  @@@@@@@   .........  ,@@@@@@@  .......@@@@@@
@@@@@@.....@@@@@       @@%............       .........@@@@@@
@@@@@@@@@..../@@@@@@@@@.............................@@@@@@@@
@@@@@@@@@............                   ............@@@@@@@@
@@@@@@@@@@@..........  @@@@@@@@@@@@@@%  .........*@@@@@@@@@@
@@@@@@@@@@@@@%....   @@//////////////#@@  .....@@@@@@@@@@@@@
@@@@@@@@@@@@@@@@  @@@///////////////////@@   @@@@@@@@@@@@@@@
@@@@@@@@@@@@@@@@  ************************   @@@@@@@@@@@@@@@
@@@@@@@@@@@@@@@@                             @@@@@@@@@@@@@@@
@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
************************************************************/

pragma solidity ^0.8.6;

import "./Ownable.sol";
import "./Strings.sol";
import "./IBitstraysDescriptor.sol";
import "./IBitstraysSeeder.sol";
import "./NFTDescriptor.sol";
import "./MultiPartRLEToSVG.sol";
import "./StringUtil.sol";

contract BitstraysDescriptor is IBitstraysDescriptor, Ownable {
    using Strings for uint256;

    // prettier-ignore
    // https://creativecommons.org/publicdomain/zero/1.0/legalcode.txt
    bytes32 constant COPYRIGHT_CC0_1_0_UNIVERSAL_LICENSE = 0xa2010f343487d3f7618affe54f789f5487602331c0a8d03f49e9a7c547cf0499;

    // Whether or not new Bitstray parts can be added
    bool public override arePartsLocked;

    // Whether or not `tokenURI` should be returned as a data URI (Default: true)
    bool public override isDataURIEnabled = true;

    // Whether or not attributes should be returned in tokenURI response (Default: true)
    bool public override areAttributesEnabled = true;

    // Base URI
    string public override baseURI;

    // Bitstray Color Palettes (Index => Hex Colors)
    mapping(uint8 => string[]) public override palettes;

    // Bitstray Backgrounds (Hex Colors)
    string[] public override backgrounds;

    // Bitstray Arms (Custom RLE)
    bytes[] public override arms;

    // Bitstray Shirts (Custom RLE)
    bytes[] public override shirts;

    // Bitstray Motives (Custom RLE)
    bytes[] public override motives;

    // Bitstray Heads (Custom RLE)
    bytes[] public override heads;

    // Bitstray Eyes (Custom RLE)
    bytes[] public override eyes;

    // Bitstray Mouths (Custom RLE)
    bytes[] public override mouths;

    // Bitstary Metadata (Array of String)
    mapping(uint8 => string[]) public override metadata;

    // Bitstary Trait Names (Array of String)
    string[] public override traitNames;

    /**
     * @notice Require that the parts have not been locked.
     */
    modifier whenPartsNotLocked() {
        require(!arePartsLocked, 'Parts are locked');
        _;
    }

    /**
     * @notice Get the number of available Bitstray `backgrounds`.
     */
    function backgroundCount() external view override returns (uint256) {
        return backgrounds.length;
    }

    /**
     * @notice Get the number of available Bitstray `arms`.
     */
    function armsCount() external view override returns (uint256) {
        return arms.length;
    }

    /**
     * @notice Get the number of available Bitstray `shirts`.
     */
    function shirtsCount() external view override returns (uint256) {
        return shirts.length;
    }

    /**
     * @notice Get the number of available Bitstray `motives`.
     */
    function motivesCount() external view override returns (uint256) {
        return motives.length;
    }

    /**
     * @notice Get the number of available Bitstray `heads`.
     */
    function headCount() external view override returns (uint256) {
        return heads.length;
    }

    /**
     * @notice Get the number of available Bitstray `eyes`.
     */
    function eyesCount() external view override returns (uint256) {
        return eyes.length;
    }

    /**
     * @notice Get the number of available Bitstray `mouths`.
     */
    function mouthsCount() external view override returns (uint256) {
        return mouths.length;
    }

    /**
     * @notice Add metadata for all parts.
     * @dev This function can only be called by the owner.
     * should container encoding details for traits [#traits, trait1, #elements, trait2, #elements, data ...]
     */
    function addManyMetadata(string[] calldata _metadata) external override onlyOwner {
        require(_metadata.length >= 1, '_metadata length < 1');
        uint256 _traits = StringUtil.parseInt(_metadata[0]);
        uint256 offset = _traits + 1; //define first real data element
        // traits are provided in #traits, traitname
        uint8 index = 0;
        for (uint8 i = 1; i < _traits; i+=2 ) {
            _addTraitName(_metadata[i]); // read trait name
            uint256 elements = StringUtil.parseInt(_metadata[i+1]);
            for (uint256 j = offset; j < (offset + elements); j++) {
                _addMetadata(index, _metadata[j]);
            }
            offset = offset + elements;
            index++;
        }
    }

    /**
     * @notice Add colors to a color palette.
     * @dev This function can only be called by the owner.
     */
    function addManyColorsToPalette(uint8 paletteIndex, string[] calldata newColors) external override onlyOwner {
        require(palettes[paletteIndex].length + newColors.length <= 256, 'Palettes can only hold 256 colors');
        for (uint256 i = 0; i < newColors.length; i++) {
            _addColorToPalette(paletteIndex, newColors[i]);
        }
    }

    /**
     * @notice Batch add Bitstray backgrounds.
     * @dev This function can only be called by the owner when not locked.
     */
    function addManyBackgrounds(string[] calldata _backgrounds) external override onlyOwner whenPartsNotLocked {
        for (uint256 i = 0; i < _backgrounds.length; i++) {
            _addBackground(_backgrounds[i]);
        }
    }

    /**
     * @notice Batch add Bitstray arms.
     * @dev This function can only be called by the owner when not locked.
     */
    function addManyArms(bytes[] calldata _arms) external override onlyOwner whenPartsNotLocked {
        for (uint256 i = 0; i < _arms.length; i++) {
            _addArms(_arms[i]);
        }
    }

    /**
     * @notice Batch add Bitstray shirts.
     * @dev This function can only be called by the owner when not locked.
     */
    function addManyShirts(bytes[] calldata _shirts) external override onlyOwner whenPartsNotLocked {
        for (uint256 i = 0; i < _shirts.length; i++) {
            _addShirt(_shirts[i]);
        }
    }

    /**
     * @notice Batch add Bitstray motives.
     * @dev This function can only be called by the owner when not locked.
     */
    function addManyMotives(bytes[] calldata _motives) external override onlyOwner whenPartsNotLocked {
        for (uint256 i = 0; i < _motives.length; i++) {
            _addMotive(_motives[i]);
        }
    }

    /**
     * @notice Batch add Bitstray heads.
     * @dev This function can only be called by the owner when not locked.
     */
    function addManyHeads(bytes[] calldata _heads) external override onlyOwner whenPartsNotLocked {
        for (uint256 i = 0; i < _heads.length; i++) {
            _addHead(_heads[i]);
        }
    }

    /**
     * @notice Batch add Bitstray eyes.
     * @dev This function can only be called by the owner when not locked.
     */
    function addManyEyes(bytes[] calldata _eyes) external override onlyOwner whenPartsNotLocked {
        for (uint256 i = 0; i < _eyes.length; i++) {
            _addEyes(_eyes[i]);
        }
    }

    /**
     * @notice Batch add Bitstray eyes.
     * @dev This function can only be called by the owner when not locked.
     */
    function addManyMouths(bytes[] calldata _mouths) external override onlyOwner whenPartsNotLocked {
        for (uint256 i = 0; i < _mouths.length; i++) {
            _addMouth(_mouths[i]);
        }
    }

    /**
     * @notice Add a single color to a color palette.
     * @dev This function can only be called by the owner.
     */
    function addColorToPalette(uint8 _paletteIndex, string calldata _color) external override onlyOwner {
        require(palettes[_paletteIndex].length <= 255, 'Palettes can only hold 256 colors');
        _addColorToPalette(_paletteIndex, _color);
    }

    /**
     * @notice Add a Bitstray background.
     * @dev This function can only be called by the owner when not locked.
     */
    function addBackground(string calldata _background) external override onlyOwner whenPartsNotLocked {
        _addBackground(_background);
    }

    /**
     * @notice Add a Bitstray arms.
     * @dev This function can only be called by the owner when not locked.
     */
    function addArms(bytes calldata _arms) external override onlyOwner whenPartsNotLocked {
        _addArms(_arms);
    }

    /**
     * @notice Add a Bitstray shirt.
     * @dev This function can only be called by the owner when not locked.
     */
    function addShirt(bytes calldata _shirt) external override onlyOwner whenPartsNotLocked {
        _addShirt(_shirt);
    }

    /**
     * @notice Add a Bitstray motive.
     * @dev This function can only be called by the owner when not locked.
     */
    function addMotive(bytes calldata _motive) external override onlyOwner whenPartsNotLocked {
        _addMotive(_motive);
    }

    /**
     * @notice Add a Bitstray head.
     * @dev This function can only be called by the owner when not locked.
     */
    function addHead(bytes calldata _head) external override onlyOwner whenPartsNotLocked {
        _addHead(_head);
    }

    /**
     * @notice Add Bitstray eyes.
     * @dev This function can only be called by the owner when not locked.
     */
    function addEyes(bytes calldata _eyes) external override onlyOwner whenPartsNotLocked {
        _addEyes(_eyes);
    }

    /**
     * @notice Add Bitstray mouth.
     * @dev This function can only be called by the owner when not locked.
     */
    function addMouth(bytes calldata _mouth) external override onlyOwner whenPartsNotLocked {
        _addMouth(_mouth);
    }

    /**
     * @notice Lock all Bitstray parts.
     * @dev This cannot be reversed and can only be called by the owner when not locked.
     */
    function lockParts() external override onlyOwner whenPartsNotLocked {
        arePartsLocked = true;

        emit PartsLocked();
    }


    /**
     * @notice Toggle a boolean value which determines if `tokenURI` returns a data URI
     * or an HTTP URL.
     * @dev This can only be called by the owner.
     */
    function toggleAttributesEnabled() external override onlyOwner {
        bool enabled = !areAttributesEnabled;

        areAttributesEnabled = enabled;
        emit AttributesToggled(enabled);
    }

    /**
     * @notice Toggle a boolean value which determines if `tokenURI` returns a data URI
     * or an HTTP URL.
     * @dev This can only be called by the owner.
     */
    function toggleDataURIEnabled() external override onlyOwner {
        bool enabled = !isDataURIEnabled;

        isDataURIEnabled = enabled;
        emit DataURIToggled(enabled);
    }

    /**
     * @notice Set the base URI for all token IDs. It is automatically
     * added as a prefix to the value returned in {tokenURI}, or to the
     * token ID if {tokenURI} is empty.
     * @dev This can only be called by the owner.
     */
    function setBaseURI(string calldata _baseURI) external override onlyOwner {
        baseURI = _baseURI;

        emit BaseURIUpdated(_baseURI);
    }

    /**
     * @notice Given a token ID and seed, construct a token URI for an official Bitstrays DAO bitstray.
     * @dev The returned value may be a base64 encoded data URI or an API URL.
     */
    function tokenURI(uint256 tokenId, IBitstraysSeeder.Seed memory seed) external view override returns (string memory) {
        if (isDataURIEnabled) {
            return dataURI(tokenId, seed);
        }
        return string(abi.encodePacked(baseURI, tokenId.toString()));
    }

    /**
     * @notice Given a token ID and seed, construct a base64 encoded data URI for an official Bitstrays DAO bitstray.
     */
    function dataURI(uint256 tokenId, IBitstraysSeeder.Seed memory seed) public view override returns (string memory) {
        string memory bitstrayId = tokenId.toString();
        string memory name = string(abi.encodePacked('Bitstray #', bitstrayId));
        string memory description = string(abi.encodePacked('Bitstray #', bitstrayId, ' is a member of the Bitstrays DAO and on-chain citizen'));
        return genericDataURI(name, description,  seed);
    }

    /**
     * @notice Given a name, description, and seed, construct a base64 encoded data URI.
     */
    function genericDataURI(
        string memory name,
        string memory description,
        IBitstraysSeeder.Seed memory seed
    ) public view override returns (string memory) {
        NFTDescriptor.TokenURIParams memory params = NFTDescriptor.TokenURIParams({
            name: name,
            description: description,
            attributes : _getAttributesForSeed(seed),
            parts: _getPartsForSeed(seed),
            background: backgrounds[seed.background]
        });
        return NFTDescriptor.constructTokenURI(params, palettes);
    }

    /**
     * @notice Given a seed, construct a base64 encoded SVG image.
     */
    function generateSVGImage(IBitstraysSeeder.Seed memory seed) external view override returns (string memory) {
        MultiPartRLEToSVG.SVGParams memory params = MultiPartRLEToSVG.SVGParams({
            parts: _getPartsForSeed(seed),
            background: backgrounds[seed.background]
        });
        return NFTDescriptor.generateSVGImage(params, palettes);
    }

    /**
     * @notice Add a single attribute to metadata.
     */
    function _addTraitName(string calldata _traitName) internal {
        traitNames.push(_traitName);
    }

    /**
     * @notice Add a single attribute to metadata.
     */
    function _addMetadata(uint8 _index, string calldata _metadata) internal {
        metadata[_index].push(_metadata);
    }

    /**
     * @notice Add a single color to a color palette.
     */
    function _addColorToPalette(uint8 _paletteIndex, string calldata _color) internal {
        palettes[_paletteIndex].push(_color);
    }

    /**
     * @notice Add a Bitstray background.
     */
    function _addBackground(string calldata _background) internal {
        backgrounds.push(_background);
    }

    /**
     * @notice Add a Bitstray arm.
     */
    function _addArms(bytes calldata _arms) internal {
        arms.push(_arms);
    }

    /**
     * @notice Add a Bitstray shirt.
     */
    function _addShirt(bytes calldata _shirt) internal {
        shirts.push(_shirt);
    }

    /**
     * @notice Add a Bitstray motive.
     */
    function _addMotive(bytes calldata _motive) internal {
        motives.push(_motive);
    }

    /**
     * @notice Add a Bitstray head.
     */
    function _addHead(bytes calldata _head) internal {
        heads.push(_head);
    }

    /**
     * @notice Add Bitstray eyes.
     */
    function _addEyes(bytes calldata _eyes) internal {
        eyes.push(_eyes);
    }
    
    /**
     * @notice Add Bitstray mouths.
     */
    function _addMouth(bytes calldata _mouth) internal {
        mouths.push(_mouth);
    }



    /**
     * @notice Get all Bitstray attributes for the passed `seed`.
     */
    function _getAttributesForSeed(IBitstraysSeeder.Seed memory seed) internal view returns (string[] memory) {
        if (areAttributesEnabled) {
            string[] memory _attributes = new string[](14);
            _attributes[0] = traitNames[0];
            _attributes[1] = metadata[0][seed.head];
            _attributes[2] = traitNames[1];
            _attributes[3] = metadata[1][seed.head];
            _attributes[4] = traitNames[2];
            _attributes[5] = metadata[2][seed.arms];
            _attributes[6] = traitNames[3];
            _attributes[7] = metadata[3][seed.shirt];
            _attributes[8] = traitNames[4];
            _attributes[9] = metadata[4][seed.motive];
            _attributes[10] = traitNames[5];
            _attributes[11] = metadata[5][seed.eyes];
            _attributes[12] = traitNames[6];
            _attributes[13] = metadata[6][seed.mouth];
            return _attributes;
        }
        string[] memory _empty = new string[](0);
        return _empty;
    }

    /**
     * @notice Get all Bitstray parts for the passed `seed`.
     */
    function _getPartsForSeed(IBitstraysSeeder.Seed memory seed) internal view returns (bytes[] memory) {
        bytes[] memory _parts = new bytes[](6);
        _parts[0] = arms[seed.arms];
        _parts[1] = shirts[seed.shirt];
        _parts[2] = motives[seed.motive];
        _parts[3] = heads[seed.head];
        _parts[4] = eyes[seed.eyes];
        _parts[5] = mouths[seed.mouth];
        return _parts;
    }
}