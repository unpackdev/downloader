// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.8;

import "./Models.sol";

interface IBuilder is Models {

    function buildCarMetadata(
        uint _carId,
        Car memory _car,
        Base memory _base,
        ColoredPaths[2] memory _tires,
        string[2] memory _tiresPos,
        string[] memory _rim,
        PartWithPos[5] memory _partsWPos,
        Part[] memory _parts
    ) external view returns (string memory);

    function buildPartMetadata(
        uint _partId,
        uint _partIndex,
        ColoredPaths memory _paths,
        string memory _color
    ) external view returns (string memory);
    
    function buildColoredPaths(ColoredPaths memory _cPaths, string memory _defaultColor) view external returns (bytes memory);

    function wrapSVG(bytes memory _svg) pure external returns (bytes memory);

    function wrapBoxedSVG(bytes memory _svg) pure external returns (bytes memory);
    
    function wrapInGroup(bytes memory _svg, string memory _pos, bytes memory _addon) view external returns (bytes memory);
}