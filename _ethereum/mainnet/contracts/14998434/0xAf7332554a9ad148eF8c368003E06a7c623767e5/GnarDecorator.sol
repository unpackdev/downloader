// SPDX-License-Identifier: GPL-3.0

pragma solidity ^0.8.6;

import "./IGnarDecorator.sol";
import "./IGNARSeederV2.sol";
import "./MultiPartRLEToSVG.sol";
import "./base64.sol";
import "./Ownable.sol";

contract GnarDecorator is IGnarDecorator, Ownable {
    // Noun Backgrounds
    string[] public override backgrounds;

    // Noun Bodies
    string[] public override bodies;

    // Noun Accessories
    string[] public override accessories;

    // Noun Heads
    string[] public override heads;

    // Noun Glasses
    string[] public override glasses;

    function addManyBackgrounds(string[] calldata _backgrounds) external override onlyOwner {
        for (uint256 i = 0; i < _backgrounds.length; i++) {
            _addBackground(_backgrounds[i]);
        }
    }

    function addManyBodies(string[] calldata _bodies) external override onlyOwner {
        for (uint256 i = 0; i < _bodies.length; i++) {
            _addBody(_bodies[i]);
        }
    }

    function addManyAccessories(string[] calldata _accessories) external override onlyOwner {
        for (uint256 i = 0; i < _accessories.length; i++) {
            _addAccessory(_accessories[i]);
        }
    }

    function addManyHeads(string[] calldata _heads) external override onlyOwner {
        for (uint256 i = 0; i < _heads.length; i++) {
            _addHead(_heads[i]);
        }
    }

    function addManyGlasses(string[] calldata _glasses) external override onlyOwner {
        for (uint256 i = 0; i < _glasses.length; i++) {
            _addGlasses(_glasses[i]);
        }
    }

    function _addBackground(string calldata _background) internal {
        backgrounds.push(_background);
    }

    function _addBody(string calldata _body) internal {
        bodies.push(_body);
    }

    function _addAccessory(string calldata _accessory) internal {
        accessories.push(_accessory);
    }

    function _addHead(string calldata _head) internal {
        heads.push(_head);
    }

    function _addGlasses(string calldata _glasses) internal {
        glasses.push(_glasses);
    }
}
