// SPDX-License-Identifier: UNLICENSED

pragma solidity ^0.8.20;

import "./Ownable.sol";
import "./LogosTypes.sol";

contract LogosTraits is Ownable {
    
    mapping (uint8 => L.CharacterInfo) private _charactersByID;
    mapping (uint8 => L.ShapeInfo) private _shapesPrimaryByID;
    mapping (uint8 => L.ShapeInfo) private _shapesSecondaryByID;
    mapping (uint16 => L.ColorPalette) private _colorPalettesByID;

    event CharacterInfoAdded(uint8 id, L.CharacterInfo info);
    event PrimaryShapeInfoAdded(uint8 id, L.ShapeInfo info);
    event SecondaryShapeInfoAdded(uint8 id, L.ShapeInfo info);
    event ColorPaletteAdded(uint16 id, L.ColorPalette info);
    event CharactersEnabled(uint8 startID, uint8 endID);
    event PrimaryShapesEnabled(uint8 startID, uint8 endID);
    event SecondaryShapesEnabled(uint8 startID, uint8 endID);
    event ColorPalettesEnabled(uint16 startID, uint16 endID);
    event CharacterInfoRemoved(uint8 id);
    event PrimaryShapeInfoRemoved(uint8 id);
    event SecondaryShapeInfoRemoved(uint8 id);
    event ColorPaletteRemoved(uint16 id);
    
    constructor() Ownable() {
        
    }

    function charactersByID(uint8 id) external view returns (L.CharacterInfo memory) {
        return _charactersByID[id];
    }

    function shapesPrimaryByID(uint8 id) external view returns (L.ShapeInfo memory) {
        return _shapesPrimaryByID[id];
    }

    function shapesSecondaryByID(uint8 id) external view returns (L.ShapeInfo memory) {
        return _shapesSecondaryByID[id];
    }

    function colorPalettesByID(uint16 id) external view returns (L.ColorPalette memory) {
        return _colorPalettesByID[id];
    }

    function addCharacterInfo(uint8 id, L.CharacterInfo calldata info) external onlyOwner {
        _charactersByID[id] = info;
        emit CharacterInfoAdded(id, info);
    }
    
    function addPrimaryShapeInfo(uint8 id, L.ShapeInfo memory info) external onlyOwner {
        _shapesPrimaryByID[id] = info;
        emit PrimaryShapeInfoAdded(id, info);
    }

    function addSecondaryShapeInfo(uint8 id, L.ShapeInfo memory info) external onlyOwner {
        _shapesSecondaryByID[id] = info;
        emit SecondaryShapeInfoAdded(id, info);
    }

    function addColorPalette(uint16 id, L.ColorPalette memory info) external onlyOwner {
        _colorPalettesByID[id] = info;
        emit ColorPaletteAdded(id, info);
    }

    function enableCharacters(uint8 startID, uint8 endID) external onlyOwner {
        for (uint8 i = startID; i <= endID; i++) {
            _charactersByID[i].enabled = true;
        }
        emit CharactersEnabled(startID, endID);
    }

    function enablePrimaryShapes(uint8 startID, uint8 endID) external onlyOwner {
        for (uint8 i = startID; i <= endID; i++) {
            _shapesPrimaryByID[i].enabled = true;
        }
        emit PrimaryShapesEnabled(startID, endID);
    }

    function enableSecondaryShapes(uint8 startID, uint8 endID) external onlyOwner {
        for (uint8 i = startID; i <= endID; i++) {
            _shapesSecondaryByID[i].enabled = true;
        }
        emit SecondaryShapesEnabled(startID, endID);
    }

    function enableColorPalettes(uint16 startID, uint16 endID) external onlyOwner {
        for (uint16 i = startID; i <= endID; i++) {
            _colorPalettesByID[i].enabled = true;
        }
        emit ColorPalettesEnabled(startID, endID);
    }

    function removeCharacterInfo(uint8 id) external onlyOwner {
        delete _charactersByID[id];
        emit CharacterInfoRemoved(id);
    }

    function removePrimaryShapeInfo(uint8 id) external onlyOwner {
        delete _shapesPrimaryByID[id];
        emit PrimaryShapeInfoRemoved(id);
    }

    function removeSecondaryShapeInfo(uint8 id) external onlyOwner {
        delete _shapesSecondaryByID[id];
        emit SecondaryShapeInfoRemoved(id);
    }

    function removeColorPalette(uint16 id) external onlyOwner {
        delete _colorPalettesByID[id];
        emit ColorPaletteRemoved(id);
    }
}