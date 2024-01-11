// SPDX-License-Identifier: GPL-3.0

/// @title The Shiny Club NFT descriptor

/*********************************
 * ･ﾟ･ﾟ✧.・･ﾟshiny.club・✫・゜･ﾟ✧ *
 *********************************/

pragma solidity ^0.8.9;

import "./Ownable.sol";
import "./Strings.sol";
import "./IShinyDescriptor.sol";
import "./IShinySeeder.sol";
import "./NFTDescriptor.sol";
import "./MultiPartRLEToSVG.sol";

contract ShinyDescriptor is IShinyDescriptor, Ownable {
    using Strings for uint256;

    // prettier-ignore
    // https://creativecommons.org/publicdomain/zero/1.0/legalcode.txt
    bytes32 constant COPYRIGHT_CC0_1_0_UNIVERSAL_LICENSE = 0xa2010f343487d3f7618affe54f789f5487602331c0a8d03f49e9a7c547cf0499;

    // Whether or not new Shiny parts can be added
    bool public override arePartsLocked;

    // Shiny Color Palettes (Index => Hex Colors)
    mapping(uint8 => string[]) public override palettes;

    // Shiny Backgrounds (Hex Colors)
    string[] public override backgrounds;

    // Shiny Bodies (Custom RLE)
    bytes[] public override bodies;

    // Shiny Accessories (Custom RLE)
    bytes[] public override accessories;

    // Shiny Heads (Custom RLE)
    bytes[] public override heads;

    // Shiny Eyes (Custom RLE)
    bytes[] public override eyes;

    // Shiny Noses (Custom RLE)
    bytes[] public override noses;

    // Shiny Mouths (Custom RLE)
    bytes[] public override mouths;

    // Shiny Shiny Accessories (Custom RLE)
    bytes[] public override shinyAccessories;

    /**
     * @notice Require that the parts have not been locked.
     */
    modifier whenPartsNotLocked() {
        require(!arePartsLocked, 'Parts are locked');
        _;
    }

    /**
     * @notice Get the number of available Shiny `backgrounds`.
     */
    function backgroundCount() external view override returns (uint256) {
        return backgrounds.length;
    }

    /**
     * @notice Get the number of available Shiny `bodies`.
     */
    function bodyCount() external view override returns (uint256) {
        return bodies.length;
    }

    /**
     * @notice Get the number of available Shiny `accessories`.
     */
    function accessoryCount() external view override returns (uint256) {
        return accessories.length;
    }

    /**
     * @notice Get the number of available Shiny `heads`.
     */
    function headCount() external view override returns (uint256) {
        return heads.length;
    }

    /**
     * @notice Get the number of available Shiny `eyes`.
     */
    function eyesCount() external view override returns (uint256) {
        return eyes.length;
    }

    /**
     * @notice Get the number of available Shiny `noses`.
     */
    function nosesCount() external view override returns (uint256) {
        return noses.length;
    }

    /**
     * @notice Get the number of available Shiny `mouths`.
     */
    function mouthsCount() external view override returns (uint256) {
        return mouths.length;
    }

    /**
     * @notice Get the number of available Shiny `shinyAccessories`.
     */
    function shinyAccessoriesCount() external view override returns (uint256) {
        return shinyAccessories.length;
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
     * @notice Batch add Shiny backgrounds.
     * @dev This function can only be called by the owner when not locked.
     */
    function addManyBackgrounds(string[] calldata _backgrounds) external override onlyOwner whenPartsNotLocked {
        for (uint256 i = 0; i < _backgrounds.length; i++) {
            _addBackground(_backgrounds[i]);
        }
    }

    /**
     * @notice Batch add Shiny bodies.
     * @dev This function can only be called by the owner when not locked.
     */
    function addManyBodies(bytes[] calldata _bodies) external override onlyOwner whenPartsNotLocked {
        for (uint256 i = 0; i < _bodies.length; i++) {
            _addBody(_bodies[i]);
        }
    }

    /**
     * @notice Batch add Shiny accessories.
     * @dev This function can only be called by the owner when not locked.
     */
    function addManyAccessories(bytes[] calldata _accessories) external override onlyOwner whenPartsNotLocked {
        for (uint256 i = 0; i < _accessories.length; i++) {
            _addAccessory(_accessories[i]);
        }
    }

    /**
     * @notice Batch add Shiny heads.
     * @dev This function can only be called by the owner when not locked.
     */
    function addManyHeads(bytes[] calldata _heads) external override onlyOwner whenPartsNotLocked {
        for (uint256 i = 0; i < _heads.length; i++) {
            _addHead(_heads[i]);
        }
    }

    /**
     * @notice Batch add Shiny eyes.
     * @dev This function can only be called by the owner when not locked.
     */
    function addManyEyes(bytes[] calldata _eyes) external override onlyOwner whenPartsNotLocked {
        for (uint256 i = 0; i < _eyes.length; i++) {
            _addEyes(_eyes[i]);
        }
    }

    /**
     * @notice Batch add Shiny noses.
     * @dev This function can only be called by the owner when not locked.
     */
    function addManyNoses(bytes[] calldata _noses) external override onlyOwner whenPartsNotLocked {
        for (uint256 i = 0; i < _noses.length; i++) {
            _addNoses(_noses[i]);
        }
    }

    /**
     * @notice Batch add Shiny mouths.
     * @dev This function can only be called by the owner when not locked.
     */
    function addManyMouths(bytes[] calldata _mouths) external override onlyOwner whenPartsNotLocked {
        for (uint256 i = 0; i < _mouths.length; i++) {
            _addMouths(_mouths[i]);
        }
    }

    /**
     * @notice Batch add Shiny shinyAccessories.
     * @dev This function can only be called by the owner when not locked.
     */
    function addManyShinyAccessories(bytes[] calldata _shinyAccessories) external override onlyOwner whenPartsNotLocked {
        for (uint256 i = 0; i < _shinyAccessories.length; i++) {
            _addShinyAccessories(_shinyAccessories[i]);
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
     * @notice Add a Shiny background.
     * @dev This function can only be called by the owner when not locked.
     */
    function addBackground(string calldata _background) external override onlyOwner whenPartsNotLocked {
        _addBackground(_background);
    }

    /**
     * @notice Add a Shiny body.
     * @dev This function can only be called by the owner when not locked.
     */
    function addBody(bytes calldata _body) external override onlyOwner whenPartsNotLocked {
        _addBody(_body);
    }

    /**
     * @notice Add a Shiny accessory.
     * @dev This function can only be called by the owner when not locked.
     */
    function addAccessory(bytes calldata _accessory) external override onlyOwner whenPartsNotLocked {
        _addAccessory(_accessory);
    }

    /**
     * @notice Add a Shiny head.
     * @dev This function can only be called by the owner when not locked.
     */
    function addHead(bytes calldata _head) external override onlyOwner whenPartsNotLocked {
        _addHead(_head);
    }

    /**
     * @notice Add Shiny eyes.
     * @dev This function can only be called by the owner when not locked.
     */
    function addEyes(bytes calldata _eyes) external override onlyOwner whenPartsNotLocked {
        _addEyes(_eyes);
    }

    /**
     * @notice Add Shiny noses.
     * @dev This function can only be called by the owner when not locked.
     */
    function addNoses(bytes calldata _noses) external override onlyOwner whenPartsNotLocked {
        _addNoses(_noses);
    }

    /**
     * @notice Add Shiny noses.
     * @dev This function can only be called by the owner when not locked.
     */
    function addMouths(bytes calldata _mouths) external override onlyOwner whenPartsNotLocked {
        _addMouths(_mouths);
    }

    /**
     * @notice Lock all Shiny parts.
     * @dev This cannot be reversed and can only be called by the owner when not locked.
     */
    function lockParts() external override onlyOwner whenPartsNotLocked {
        arePartsLocked = true;

        emit PartsLocked();
    }

    /**
     * @notice Given a token ID and seed, construct a token URI for a Shiny.
     * @dev The returned value may be a base64 encoded data URI or an API URL.
     */
    function tokenURI(uint256 tokenId, IShinySeeder.Seed memory seed, bool isShiny) external view override returns (string memory) {
        return dataURI(tokenId, seed, isShiny);
    }

    /**
     * @notice Given a token ID and seed, construct a base64 encoded data URI for a Shiny.
     */
    function dataURI(uint256 tokenId, IShinySeeder.Seed memory seed, bool isShiny) public view override returns (string memory) {
        string memory shinyId = tokenId.toString();
        string memory name = string(abi.encodePacked('Shiny ', shinyId));
        string memory description = string(abi.encodePacked('Shiny ', shinyId, ' is a member of Shiny Club'));

        return genericDataURI(name, description, seed, isShiny);
    }

    /**
     * @notice Given a name, description, and seed, construct a base64 encoded data URI.
     */
    function genericDataURI(
        string memory name,
        string memory description,
        IShinySeeder.Seed memory seed,
        bool isShiny
    ) public view override returns (string memory) {
        NFTDescriptor.TokenURIParams memory params = NFTDescriptor.TokenURIParams({
            name: name,
            description: description,
            parts: _getPartsForSeed(seed),
            background: backgrounds[seed.background],
            isShiny: isShiny
        });
        return NFTDescriptor.constructTokenURI(params, palettes);
    }

    /**
     * @notice Given a seed, construct a base64 encoded SVG image.
     */
    function generateSVGImage(IShinySeeder.Seed memory seed) external view override returns (string memory) {
        MultiPartRLEToSVG.SVGParams memory params = MultiPartRLEToSVG.SVGParams({
            parts: _getPartsForSeed(seed),
            background: backgrounds[seed.background]
        });
        return NFTDescriptor.generateSVGImage(params, palettes);
    }

    /**
     * @notice Add a single color to a color palette.
     */
    function _addColorToPalette(uint8 _paletteIndex, string calldata _color) internal {
        palettes[_paletteIndex].push(_color);
    }

    /**
     * @notice Add a Shiny background.
     */
    function _addBackground(string calldata _background) internal {
        backgrounds.push(_background);
    }

    /**
     * @notice Add a Shiny body.
     */
    function _addBody(bytes calldata _body) internal {
        bodies.push(_body);
    }

    /**
     * @notice Add a Shiny accessory.
     */
    function _addAccessory(bytes calldata _accessory) internal {
        accessories.push(_accessory);
    }

    /**
     * @notice Add a Shiny head.
     */
    function _addHead(bytes calldata _head) internal {
        heads.push(_head);
    }

    /**
     * @notice Add Shiny eyes.
     */
    function _addEyes(bytes calldata _eyes) internal {
        eyes.push(_eyes);
    }

    /**
     * @notice Add Shiny noses.
     */
    function _addNoses(bytes calldata _noses) internal {
        noses.push(_noses);
    }

    /**
     * @notice Add Shiny mouths.
     */
    function _addMouths(bytes calldata _mouths) internal {
        mouths.push(_mouths);
    }

    /**
     * @notice Add Shiny shinyAccessories.
     */
    function _addShinyAccessories(bytes calldata _shinyAccessories) internal {
        shinyAccessories.push(_shinyAccessories);
    }

    /**
     * @notice Get all Shiny parts for the passed `seed`.
     */
    function _getPartsForSeed(IShinySeeder.Seed memory seed) internal view returns (bytes[] memory) {
        bytes[] memory _parts = new bytes[](7);
        _parts[0] = bodies[seed.body];
        _parts[1] = accessories[seed.accessory];
        _parts[2] = heads[seed.head];
        _parts[3] = eyes[seed.eyes];
        _parts[4] = noses[seed.nose];
        _parts[5] = mouths[seed.mouth];
        _parts[6] = shinyAccessories[seed.shinyAccessory];
        return _parts;
    }
}
