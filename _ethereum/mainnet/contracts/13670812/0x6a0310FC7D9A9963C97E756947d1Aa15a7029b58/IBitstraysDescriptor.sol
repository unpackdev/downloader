// SPDX-License-Identifier: GPL-3.0

/// @title Interface for BitstraysDescriptor

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

import "./IBitstraysSeeder.sol";

interface IBitstraysDescriptor {
    
    event PartsLocked();

    event DataURIToggled(bool enabled);

    event AttributesToggled(bool enabled);

    event BaseURIUpdated(string baseURI);

    function arePartsLocked() external returns (bool);

    function areAttributesEnabled() external returns (bool);

    function isDataURIEnabled() external returns (bool);

    function baseURI() external returns (string memory);

    function palettes(uint8 paletteIndex, uint256 colorIndex) external view returns (string memory);
    
    function metadata(uint8 index, uint256 traitIndex) external view returns (string memory);

    function traitNames(uint256 index) external view returns (string memory);

    function backgrounds(uint256 index) external view returns (string memory);

    function arms(uint256 index) external view returns (bytes memory);

    function shirts(uint256 index) external view returns (bytes memory);

    function motives(uint256 index) external view returns (bytes memory);

    function heads(uint256 index) external view returns (bytes memory);

    function eyes(uint256 index) external view returns (bytes memory);

    function mouths(uint256 index) external view returns (bytes memory);

    function backgroundCount() external view returns (uint256);

    function armsCount() external view returns (uint256);

    function shirtsCount() external view returns (uint256);

    function motivesCount() external view returns (uint256);

    function headCount() external view returns (uint256);

    function eyesCount() external view returns (uint256);

    function mouthsCount() external view returns (uint256);

    function addManyMetadata(string[] calldata _metadata) external;

    function addManyColorsToPalette(uint8 paletteIndex, string[] calldata newColors) external;

    function addManyBackgrounds(string[] calldata backgrounds) external;

    function addManyArms(bytes[] calldata _arms) external;

    function addManyShirts(bytes[] calldata _shirts) external;

    function addManyMotives(bytes[] calldata _motives) external;

    function addManyHeads(bytes[] calldata _heads) external;

    function addManyEyes(bytes[] calldata _eyes) external;

    function addManyMouths(bytes[] calldata _mouths) external;

    function addColorToPalette(uint8 paletteIndex, string calldata color) external;

    function addBackground(string calldata background) external;

    function addArms(bytes calldata body) external;

    function addShirt(bytes calldata shirt) external;

    function addMotive(bytes calldata motive) external;

    function addHead(bytes calldata head) external;

    function addEyes(bytes calldata eyes) external;

    function addMouth(bytes calldata mouth) external;

    function lockParts() external;

    function toggleDataURIEnabled() external;

    function toggleAttributesEnabled() external;

    function setBaseURI(string calldata baseURI) external;

    function tokenURI(uint256 tokenId, IBitstraysSeeder.Seed memory seed) external view returns (string memory);

    function dataURI(uint256 tokenId, IBitstraysSeeder.Seed memory seed) external view returns (string memory);

    function genericDataURI(
        string calldata name,
        string calldata description,
        IBitstraysSeeder.Seed memory seed
    ) external view returns (string memory);

    function generateSVGImage(IBitstraysSeeder.Seed memory seed) external view returns (string memory);
}
