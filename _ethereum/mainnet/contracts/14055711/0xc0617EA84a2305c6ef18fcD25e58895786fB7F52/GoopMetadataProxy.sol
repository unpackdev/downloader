// SPDX-License-Identifier: GPL-3.0

pragma solidity ^0.8.6;

import "./IGOOPsDescriptor.sol";
import "./IGOOPsSeeder.sol";
import "./IGorfDecorator.sol";
import "./base64.sol";
import "./Strings.sol";

contract GoopMetadataProxy is IGOOPsDescriptor {
    using Strings for uint256;

    address public descriptorAddress = 0x0Cfdb3Ba1694c2bb2CFACB0339ad7b1Ae5932B63;
    IGOOPsDescriptor nounsDescriptor = IGOOPsDescriptor(descriptorAddress);

    address public decoratorAddress = 0xb65783f1B45468A8f932511527A7e3FeBAE4e86d;
    IGorfDecorator gorfDecorator = IGorfDecorator(decoratorAddress);

    function genericDataURI(string memory name, string memory description, IGOOPsSeeder.Seed memory seed) public view override returns (string memory) {
        string memory attributes = generateAttributesList(seed);
        string memory image = nounsDescriptor.generateSVGImage(seed);

        return string(
            abi.encodePacked(
                'data:application/json;base64,',
                Base64.encode(
                    bytes(
                        abi.encodePacked('{"name": "', name, '", "description": "', description, '", "attributes": [', attributes, '], "image": "', 'data:image/svg+xml;base64,', image, '"}')
                    )
                )
            )
        );
    }

    function generateAttributesList(IGOOPsSeeder.Seed memory seed) public view returns (string memory) {
        return string(
            abi.encodePacked(
                '{"trait_type":"Background","value":"', gorfDecorator.backgroundMapping(seed.background), '"},',
                '{"trait_type":"Body","value":"', gorfDecorator.bodyMapping(seed.body), '"},',
                '{"trait_type":"Accessory","value":"', gorfDecorator.accessoryMapping(seed.accessory), '"},',
                '{"trait_type":"Head","value":"', gorfDecorator.headMapping(seed.head), '"},',
                '{"trait_type":"Glasses","value":"', gorfDecorator.glassesMapping(seed.glasses), '"}'
            )
        );
    }

    function arePartsLocked() external override returns (bool) {return nounsDescriptor.arePartsLocked();}

    function isDataURIEnabled() external override returns (bool) {return nounsDescriptor.isDataURIEnabled();}

    function baseURI() external override returns (string memory) {return nounsDescriptor.baseURI();}

    function palettes(uint8 paletteIndex, uint256 colorIndex) external override view returns (string memory) {return nounsDescriptor.palettes(paletteIndex, colorIndex);}

    function backgrounds(uint256 index) external override view returns (string memory) {return nounsDescriptor.backgrounds(index);}

    function bodies(uint256 index) external override view returns (bytes memory) {return nounsDescriptor.bodies(index);}

    function accessories(uint256 index) external override view returns (bytes memory) {return nounsDescriptor.accessories(index);}

    function heads(uint256 index) external override view returns (bytes memory) {return nounsDescriptor.heads(index);}

    function glasses(uint256 index) external override view returns (bytes memory) {return nounsDescriptor.glasses(index);}

    function backgroundCount() external override view returns (uint256) {return nounsDescriptor.backgroundCount();}

    function bodyCount() external override view returns (uint256) {return nounsDescriptor.bodyCount();}

    function accessoryCount() external override view returns (uint256) {return nounsDescriptor.accessoryCount();}

    function headCount() external override view returns (uint256) {return nounsDescriptor.headCount();}

    function glassesCount() external override view returns (uint256) {return nounsDescriptor.glassesCount();}

    function addManyColorsToPalette(uint8 paletteIndex, string[] calldata newColors) external override {}

    function addManyBackgrounds(string[] calldata backgrounds) external override {}

    function addManyBodies(bytes[] calldata bodies) external override {}

    function addManyAccessories(bytes[] calldata accessories) external override {}

    function addManyHeads(bytes[] calldata heads) external override {}

    function addManyGlasses(bytes[] calldata glasses) external override {}

    function addColorToPalette(uint8 paletteIndex, string calldata color) external override {}

    function addBackground(string calldata background) external override {}

    function addBody(bytes calldata body) external override {}

    function addAccessory(bytes calldata accessory) external override {}

    function addHead(bytes calldata head) external override {}

    function addGlasses(bytes calldata glasses) external override {}

    function lockParts() external override {}

    function toggleDataURIEnabled() external override {}

    function setBaseURI(string calldata baseURI) external override {}

    function tokenURI(uint256 tokenId, IGOOPsSeeder.Seed memory seed) external override view returns (string memory) {return nounsDescriptor.tokenURI(tokenId, seed);}

    function dataURI(uint256 tokenId, IGOOPsSeeder.Seed memory seed) external override view returns (string memory) {return nounsDescriptor.dataURI(tokenId, seed);}

    function generateSVGImage(IGOOPsSeeder.Seed memory seed) external override view returns (string memory) {return nounsDescriptor.generateSVGImage(seed);}
}