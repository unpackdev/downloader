// SPDX-License-Identifier: GPL-3.0

/// @title The Wizards NFT descriptor

pragma solidity ^0.8.6;

import "./Ownable.sol";
import "./Strings.sol";
import "./IDescriptor.sol";
import "./ISeeder.sol";
import "./NFTDescriptor.sol";
import "./MultiPartRLEToSVG.sol";

contract Descriptor is IDescriptor, Ownable {
    using Strings for uint256;

    // Whether or not new parts can be added
    bool public override arePartsLocked;

    // Whether or not `tokenURI` should be returned as a data URI (Default: true)
    bool public override isDataURIEnabled = true;

    // Base URI
    string public override baseURI;

    // Color Palettes (Index => Hex Colors)
    mapping(uint8 => string[]) public override palettes;

    // Backgrounds (Hex Colors)
    string[] public override backgrounds;

    // Skins (Custom RLE)
    bytes[] public override skins;

    // Clothes (Custom RLE)
    bytes[] public override clothes;

    // Accessories (Custom RLE)
    bytes[] public override accessory;

    // BgItems (orb, staff, etc) (Custom RLE)
    bytes[] public override bgItems;

    // Mouths (Custom RLE)
    bytes[] public override mouths;

    // Eyes (Custom RLE)
    bytes[] public override eyes;

    // Hats (Custom RLE)
    bytes[] public override hats;

    // 1-1 wizards (Custom RLE)
    bytes[] public override oneOfOnes;

    uint256 public lastOneOfOneCount;

    /**
     * @notice Require that the parts have not been locked.
     */
    modifier whenPartsNotLocked() {
        require(!arePartsLocked, "Parts are locked");
        _;
    }

    /**
     * @notice Get the number of available `backgrounds`.
     */
    function backgroundCount() external view override returns (uint256) {
        return backgrounds.length;
    }

    /**
     * @notice One of ones count.
     */
    function oneOfOnesCount() external view override returns (uint256) {
        return oneOfOnes.length;
    }

    /**
     * @notice Get the number of available `skins`.
     */
    function skinsCount() external view override returns (uint256) {
        return skins.length;
    }

    /**
     * @notice Get the number of available `clothes`.
     */
    function clothesCount() external view override returns (uint256) {
        return clothes.length;
    }

    /**
     * @notice Get the number of available `accesories`.
     */
    function accessoryCount() external view override returns (uint256) {
        return accessory.length;
    }

    /**
     * @notice Get the number of available `bg items`.
     */
    function bgItemsCount() external view override returns (uint256) {
        return bgItems.length;
    }

    /**
     * @notice Get the number of available `hats`.
     */
    function hatsCount() external view override returns (uint256) {
        return hats.length;
    }

    /**
     * @notice Get the number of available `mouths`.
     */
    function mouthsCount() external view override returns (uint256) {
        return mouths.length;
    }

    /**
     * @notice Get the number of available `eyes`.
     */
    function eyesCount() external view override returns (uint256) {
        return eyes.length;
    }

    /**
     * @notice Add colors to a color palette.
     * @dev This function can only be called by the owner.
     */
    function addManyColorsToPalette(
        uint8 paletteIndex,
        string[] calldata newColors
    ) external override onlyOwner {
        require(
            palettes[paletteIndex].length + newColors.length <= 256,
            "Palettes can only hold 256 colors"
        );
        for (uint256 i = 0; i < newColors.length; i++) {
            _addColorToPalette(paletteIndex, newColors[i]);
        }
    }

    /**
     * @notice Replaces colors in a color palette.
     * @dev This function can only be called by the owner and should only
     * be used administratively to restore proper palette indexes.
     */
    function replacePalette(uint8 paletteIndex, string[] calldata newColors)
        external
        onlyOwner
    {
        require(newColors.length <= 256, "Palettes can only hold 256 colors");

        delete palettes[paletteIndex];
        for (uint256 i = 0; i < newColors.length; i++) {
            _addColorToPalette(paletteIndex, newColors[i]);
        }
    }

    /**
     * @notice Batch add backgrounds.
     * @dev This function can only be called by the owner when not locked.
     */
    function addManyBackgrounds(string[] calldata _backgrounds)
        external
        override
        onlyOwner
        whenPartsNotLocked
    {
        for (uint256 i = 0; i < _backgrounds.length; i++) {
            _addBackground(_backgrounds[i]);
        }
    }

    /**
     * @notice Batch add skins.
     * @dev This function can only be called by the owner when not locked.
     */
    function addManySkins(bytes[] calldata _skins)
        external
        override
        onlyOwner
        whenPartsNotLocked
    {
        for (uint256 i = 0; i < _skins.length; i++) {
            _addSkin(_skins[i]);
        }
    }

    /**
     * @notice Batch add hats.
     * @dev This function can only be called by the owner when not locked.
     */
    function addManyHats(bytes[] calldata _hats)
        external
        override
        onlyOwner
        whenPartsNotLocked
    {
        for (uint256 i = 0; i < _hats.length; i++) {
            _addHat(_hats[i]);
        }
    }

    /**
     * @notice Batch add eyes.
     * @dev This function can only be called by the owner when not locked.
     */
    function addManyEyes(bytes[] calldata _eyes)
        external
        override
        onlyOwner
        whenPartsNotLocked
    {
        for (uint256 i = 0; i < _eyes.length; i++) {
            _addEyes(_eyes[i]);
        }
    }

    /**
     * @notice Batch add mouths.
     * @dev This function can only be called by the owner when not locked.
     */
    function addManyMouths(bytes[] calldata _mouths)
        external
        override
        onlyOwner
        whenPartsNotLocked
    {
        for (uint256 i = 0; i < _mouths.length; i++) {
            _addMouth(_mouths[i]);
        }
    }

    /**
     * @notice Batch add bg items.
     * @dev This function can only be called by the owner when not locked.
     */
    function addManyBgItems(bytes[] calldata _bgItems)
        external
        override
        onlyOwner
        whenPartsNotLocked
    {
        for (uint256 i = 0; i < _bgItems.length; i++) {
            _addBgItem(_bgItems[i]);
        }
    }

    /**
     * @notice Batch add accessories.
     * @dev This function can only be called by the owner when not locked.
     */
    function addManyAccessories(bytes[] calldata _accessory)
        external
        override
        onlyOwner
        whenPartsNotLocked
    {
        for (uint256 i = 0; i < _accessory.length; i++) {
            _addAccessory(_accessory[i]);
        }
    }

    /**
     * @notice Batch add clothes.
     * @dev This function can only be called by the owner when not locked.
     */
    function addManyClothes(bytes[] calldata _clothes)
        external
        override
        onlyOwner
        whenPartsNotLocked
    {
        for (uint256 i = 0; i < _clothes.length; i++) {
            _addClothes(_clothes[i]);
        }
    }

    /**
     * @notice Batch add one of one Wizards.
     * @dev This function can only be called by the owner when not locked.
     */
    function addManyOneOfOnes(bytes[] calldata _oneOfOnes)
        external
        override
        onlyOwner
        whenPartsNotLocked
    {
        lastOneOfOneCount += _oneOfOnes.length;

        for (uint256 i = 0; i < _oneOfOnes.length; i++) {
            _addOneOfOne(_oneOfOnes[i]);
        }
    }

    /**
     * @notice Add a single color to a color palette.
     * @dev This function can only be called by the owner.
     */
    function addColorToPalette(uint8 _paletteIndex, string calldata _color)
        external
        override
        onlyOwner
    {
        require(
            palettes[_paletteIndex].length <= 255,
            "Palettes can only hold 256 colors"
        );
        _addColorToPalette(_paletteIndex, _color);
    }

    /**
     * @notice Add a one of one wizards.
     * @dev This function can only be called by the owner when not locked.
     */
    function addOneOfOne(bytes calldata _oneOfOne)
        external
        override
        onlyOwner
        whenPartsNotLocked
    {
        lastOneOfOneCount += 1;
        _addOneOfOne(_oneOfOne);
    }

    /**
     * @notice Add a background.
     * @dev This function can only be called by the owner when not locked.
     */
    function addBackground(string calldata _background)
        external
        override
        onlyOwner
        whenPartsNotLocked
    {
        _addBackground(_background);
    }

    /**
     * @notice Add a skin.
     * @dev This function can only be called by the owner when not locked.
     */
    function addSkin(bytes calldata _skin)
        external
        override
        onlyOwner
        whenPartsNotLocked
    {
        _addSkin(_skin);
    }

    /**
     * @notice Add wizard hat.
     * @dev This function can only be called by the owner when not locked.
     */
    function addHat(bytes calldata _hat)
        external
        override
        onlyOwner
        whenPartsNotLocked
    {
        _addHat(_hat);
    }

    /**
     * @notice Add a clothes.
     * @dev This function can only be called by the owner when not locked.
     */
    function addClothes(bytes calldata _clothes)
        external
        override
        onlyOwner
        whenPartsNotLocked
    {
        _addClothes(_clothes);
    }

    /**
     * @notice Add a bg item.
     * @dev This function can only be called by the owner when not locked.
     */
    function addBgItem(bytes calldata _bgItem)
        external
        override
        onlyOwner
        whenPartsNotLocked
    {
        _addBgItem(_bgItem);
    }

    /**
     * @notice Add a accessory.
     * @dev This function can only be called by the owner when not locked.
     */
    function addAccessory(bytes calldata _accessory)
        external
        override
        onlyOwner
        whenPartsNotLocked
    {
        _addAccessory(_accessory);
    }

    /**
     * @notice Add a mouth.
     * @dev This function can only be called by the owner when not locked.
     */
    function addMouth(bytes calldata _mouth)
        external
        override
        onlyOwner
        whenPartsNotLocked
    {
        _addMouth(_mouth);
    }

    /**
     * @notice Add eyes.
     * @dev This function can only be called by the owner when not locked.
     */
    function addEyes(bytes calldata _eyes)
        external
        override
        onlyOwner
        whenPartsNotLocked
    {
        _addEyes(_eyes);
    }

    /**
     * @notice Lock all parts.
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
     * @notice Given a token ID and seed, construct a token URI.
     * @dev The returned value may be a base64 encoded data URI or an API URL.
     */
    function tokenURI(uint256 tokenId, ISeeder.Seed memory seed)
        external
        view
        override
        returns (string memory)
    {
        if (isDataURIEnabled) {
            return dataURI(tokenId, seed);
        }

        return string(abi.encodePacked(baseURI, tokenId.toString()));
    }

    /**
     * @notice Given a token ID and seed, construct a base64 encoded data URI.
     */
    function dataURI(uint256 tokenId, ISeeder.Seed memory seed)
        public
        view
        override
        returns (string memory)
    {
        string memory wizardId = tokenId.toString();
        string memory name = string(abi.encodePacked("Wizard #", wizardId));

        string memory description = "";
        if (seed.oneOfOne) {
            description = string(
                abi.encodePacked(
                    "Wizard #",
                    wizardId,
                    " is a one of one artpiece and a member of the WizardsDAO"
                )
            );
        } else {
            description = string(
                abi.encodePacked(
                    "Wizard #",
                    wizardId,
                    " is a member of the WizardsDAO"
                )
            );
        }

        return genericDataURI(name, description, seed);
    }

    /**
     * @notice Given a name, description, and seed, construct a base64 encoded data URI.
     */
    function genericDataURI(
        string memory name,
        string memory description,
        ISeeder.Seed memory seed
    ) public view override returns (string memory) {
        NFTDescriptor.TokenURIParams memory params = NFTDescriptor
            .TokenURIParams({
                name: name,
                description: description,
                parts: _getPartsForSeed(seed),
                background: backgrounds[seed.background]
            });
        return NFTDescriptor.constructTokenURI(params, palettes);
    }

    /**
     * @notice Given a seed, construct a base64 encoded SVG image.
     */
    function generateSVGImage(ISeeder.Seed memory seed)
        external
        view
        override
        returns (string memory)
    {
        MultiPartRLEToSVG.SVGParams memory params = MultiPartRLEToSVG
            .SVGParams({
                parts: _getPartsForSeed(seed),
                background: backgrounds[seed.background]
            });
        return NFTDescriptor.generateSVGImage(params, palettes);
    }

    /**
     * @notice Add a single color to a color palette.
     */
    function _addColorToPalette(uint8 _paletteIndex, string calldata _color)
        internal
    {
        palettes[_paletteIndex].push(_color);
    }

    /**
     * @notice Add a single one of one wizard.
     */
    function _addOneOfOne(bytes calldata _oneOfOne) internal {
        oneOfOnes.push(_oneOfOne);
    }

    /**
     * @notice Add a background.
     */
    function _addBackground(string calldata _background) internal {
        backgrounds.push(_background);
    }

    /**
     * @notice Add a skin.
     */
    function _addSkin(bytes calldata _skin) internal {
        skins.push(_skin);
    }

    /**
     * @notice Add clothes.
     */
    function _addClothes(bytes calldata _clothes) internal {
        clothes.push(_clothes);
    }

    /**
     * @notice Add accessories.
     */
    function _addAccessory(bytes calldata _accessory) internal {
        accessory.push(_accessory);
    }

    /**
     * @notice Add bg items.
     */
    function _addBgItem(bytes calldata _bgItem) internal {
        bgItems.push(_bgItem);
    }

    /**
     * @notice Add a mouth.
     */
    function _addMouth(bytes calldata _mouth) internal {
        mouths.push(_mouth);
    }

    /**
     * @notice Add eyes.
     */
    function _addEyes(bytes calldata _eyes) internal {
        eyes.push(_eyes);
    }

    /**
     * @notice Add hat.
     */
    function _addHat(bytes calldata _hat) internal {
        hats.push(_hat);
    }

    /**
     * @notice Get all parts for the passed `seed`.
     */
    function _getPartsForSeed(ISeeder.Seed memory seed)
        internal
        view
        returns (bytes[] memory)
    {
        if (seed.oneOfOne) {
            bytes[] memory _oneOfOneParts = new bytes[](1);
            _oneOfOneParts[0] = oneOfOnes[seed.oneOfOneIndex];
            return _oneOfOneParts;
        }

        bytes[] memory _parts = new bytes[](7);
        _parts[0] = skins[seed.skin];
        _parts[1] = clothes[seed.clothes];
        _parts[2] = eyes[seed.eyes];
        _parts[3] = mouths[seed.mouth];
        _parts[4] = accessory[seed.accessory];
        _parts[5] = bgItems[seed.bgItem];
        _parts[6] = hats[seed.hat];

        return _parts;
    }
}
