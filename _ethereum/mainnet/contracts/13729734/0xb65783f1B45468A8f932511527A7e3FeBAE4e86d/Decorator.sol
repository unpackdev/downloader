// SPDX-License-Identifier: GPL-3.0

pragma solidity ^0.8.6;

import "./IGorfDecorator.sol";
import "./IGorfDescriptor.sol";
import "./IGorfSeeder.sol";
import "./MultiPartRLEToSVG.sol";
import "./base64.sol";
import "./Ownable.sol";

contract Decorator is IGorfDecorator, Ownable {
    IGorfDescriptor public descriptor;

    // Noun Backgrounds
    string[] public backgroundMapping;

    // Noun Bodies
    string[] public bodyMapping;

    // Noun Accessories
    string[] public accessoryMapping;

    // Noun Heads
    string[] public headMapping;

    // Noun Glasses
    string[] public glassesMapping;

    // Noun Color Palettes (Index => Hex Colors)
    mapping(uint8 => string[]) public palettes;

    constructor() {
        descriptor = IGorfDescriptor(0x0Cfdb3Ba1694c2bb2CFACB0339ad7b1Ae5932B63);
    }

    function addManyBackgroundsToMap(string[] calldata _backgrounds) external onlyOwner {
        for (uint256 i = 0; i < _backgrounds.length; i++) {
            _addBackgroundToMap(_backgrounds[i]);
        }
    }

    function addManyBodiesToMap(string[] calldata _bodies) external onlyOwner {
        for (uint256 i = 0; i < _bodies.length; i++) {
            _addBodyToMap(_bodies[i]);
        }
    }

    function addManyAccessoriesToMap(string[] calldata _accessories) external onlyOwner {
        for (uint256 i = 0; i < _accessories.length; i++) {
            _addAccessoryToMap(_accessories[i]);
        }
    }

    function addManyHeadsToMap(string[] calldata _heads) external onlyOwner {
        for (uint256 i = 0; i < _heads.length; i++) {
            _addHeadToMap(_heads[i]);
        }
    }

    function addManyGlassesToMap(string[] calldata _glasses) external onlyOwner {
        for (uint256 i = 0; i < _glasses.length; i++) {
            _addGlassesToMap(_glasses[i]);
        }
    }

    /**
     * @notice Given a name, description, and seed, construct a base64 encoded data URI.
     */
    function genericDataURI(string memory name, string memory description, IGorfSeeder.Seed memory seed) public view override returns (string memory) {
        MultiPartRLEToSVG.SVGParams memory params = MultiPartRLEToSVG.SVGParams({
            parts: _getPartsForSeed(seed),
            background: descriptor.backgrounds(seed.background)
        });

        string memory image = Base64.encode(bytes(MultiPartRLEToSVG.generateSVG(params, palettes)));
        string memory attributes = _generateAttributes(seed);

        // prettier-ignore
        return string(
            abi.encodePacked(
                'data:application/json;base64,',
                Base64.encode(
                    bytes(
                        abi.encodePacked('{"name":"', name, '", "description":"', description, '", "image": "', 'data:image/svg+xml;base64,', image, '", "attributes": [', attributes, ']}')
                    )
                )
            )
        );
    }

    function _generateAttributes(IGorfSeeder.Seed memory seed) internal view returns (string memory) {
        return string(
            abi.encodePacked(
                '{"trait_type": "Background", "value": "', backgroundMapping[seed.background], '"},',
                '{"trait_type": "Body", "value": "', bodyMapping[seed.body], '"},',
                '{"trait_type": "Accessory", "value": "', accessoryMapping[seed.accessory], '"},',
                '{"trait_type": "Head", "value": "', headMapping[seed.head], '"},',
                '{"trait_type": "Glasses", "value": "', glassesMapping[seed.glasses], '"}'
            )
        );
    }

    function _addBackgroundToMap(string calldata _background) internal {
        backgroundMapping.push(_background);
    }

    function _addBodyToMap(string calldata _body) internal {
        bodyMapping.push(_body);
    }

    function _addAccessoryToMap(string calldata _accessory) internal {
        accessoryMapping.push(_accessory);
    }

    function _addHeadToMap(string calldata _head) internal {
        headMapping.push(_head);
    }

    function _addGlassesToMap(string calldata _glasses) internal {
        glassesMapping.push(_glasses);
    }

    /**
     * @notice Add colors to a color palette.
     * @dev This function can only be called by the owner.
     */
    function addManyColorsToPalette(uint8 paletteIndex, string[] calldata newColors) external onlyOwner {
        require(palettes[paletteIndex].length + newColors.length <= 256, 'Palettes can only hold 256 colors');
        for (uint256 i = 0; i < newColors.length; i++) {
            _addColorToPalette(paletteIndex, newColors[i]);
        }
    }

    /**
     * @notice Add a single color to a color palette.
     * @dev This function can only be called by the owner.
     */
    function addColorToPalette(uint8 _paletteIndex, string calldata _color) external onlyOwner {
        require(palettes[_paletteIndex].length <= 255, 'Palettes can only hold 256 colors');
        _addColorToPalette(_paletteIndex, _color);
    }

    /**
     * @notice Add a single color to a color palette.
     */
    function _addColorToPalette(uint8 _paletteIndex, string calldata _color) internal {
        palettes[_paletteIndex].push(_color);
    }

    /**
     * @notice Get all Noun parts for the passed `seed`.
     */
    function _getPartsForSeed(IGorfSeeder.Seed memory seed) internal view returns (bytes[] memory) {
        bytes[] memory _parts = new bytes[](4);
        _parts[0] = descriptor.bodies(seed.body);
        _parts[1] = descriptor.accessories(seed.accessory);
        _parts[2] = descriptor.heads(seed.head);
        _parts[3] = descriptor.glasses(seed.glasses);
        return _parts;
    }
}