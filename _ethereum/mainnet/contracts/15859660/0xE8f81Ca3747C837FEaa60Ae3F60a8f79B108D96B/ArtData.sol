// File: contracts/ArtData.sol


// SPDX-License-Identifier: MIT
pragma solidity >=0.4.22 <0.9.0;

import "./Ownable.sol";
import "./Strings.sol";
import "./IArtData.sol";
import "./IColors.sol";

contract ArtData is IArtData, Ownable{

    //plane specific
    uint256 _numOfX = 100;  //possible locations on x axis
    uint256 _numOfY = 100;  //possible locations on y axis
    uint256 _numAngles = 7;  //directions
    uint8[] _planeTypeR = [20, 38, 51, 63, 73, 82, 89, 95, 98, 100];  //10 plane type rarities
    uint8[] _speedR = [20, 80, 100];  //slow medium fast rarities
    uint8[] _levelR = [3, 8, 18, 28, 45, 65, 75 ,85, 95, 100];  //plane altitude rarities

    //art specific
    string[] _proximity = ['Distant', 'Far', 'Near', 'Close'];
    uint8[] _proximityR = [20, 55, 85, 100];  //zoom level rarities of the art
    uint maxNumPlanes = 7;  //possible number of planes in an artowrk

    //color data source
    IColors colors;

    function setColorsAddr(address addr) external onlyOwner {
        colors = IColors(addr);
    }

    function getProps() public view virtual override returns(ArtProps memory) {
        ArtProps memory artProps;
        artProps.numOfX = getNumOfX();
        artProps.numOfY = getNumOfY();
        artProps.numAngles = getNumAngles();
        artProps.numTypes = getNumTypes();

        return artProps;
    }

    function getNumOfX() public view virtual override returns (uint) {
        return _numOfX;
    }

    function getNumOfY() public view virtual override returns (uint) {
        return _numOfY;
    }

    function getNumAngles() public view virtual override returns (uint) {
        return _numAngles;
    }

    function getNumTypes() public view virtual override returns (uint) {
        return _planeTypeR.length;
    }

    function getNumSpeeds() public view virtual override returns (uint) {
        return _speedR.length;
    }

    function getSkyName(uint index) external view virtual override returns (string memory) {
        return colors.getSkyName(index);
    }

    function getNumSkyCols() external view virtual override returns (uint) {
        return colors.getNumSkys();
    }

    function getColorPaletteName(uint paletteIdx) external view virtual override returns (string memory) {
        return colors.getPaletteName(paletteIdx);
    }

    function getNumColorPalettes() external view virtual override returns (uint) {
        return colors.getNumPalettes();
    }

    function getPaletteSize(uint paletteIdx) external view virtual override returns (uint) {
        require(address(colors) != address(0), "No col addr");
        return colors.getPaletteSize(paletteIdx);
    }

    function getProximityName(uint index) external view virtual override returns (string memory) {
        return _proximity[index];
    }

    function getNumProximities() external view virtual override returns (uint) {
        return _proximityR.length;
    }

    function getMaxNumPlanes() external view virtual override returns (uint) {
        return maxNumPlanes;
    }

    function getLevelRarities() external view virtual override returns (uint8[] memory) {
        return _levelR;
    }

    function getSpeedRarities() external view virtual override returns (uint8[] memory) {
        return _speedR;
    }

    function getPlaneTypeRarities() external view virtual override returns (uint8[] memory) {
        return _planeTypeR;
    }

    function getProximityRarities() external view virtual override returns (uint8[] memory) {
        return _proximityR;
    }

    function getSkyRarities() external view virtual override returns (uint8[] memory) {
        return colors.getSkyRarities();
    }

    function getColorPaletteRarities() external view virtual override returns (uint8[] memory) {
        return colors.geColorPaletteRarities();
    }

}
