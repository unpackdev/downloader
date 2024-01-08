// SPDX-License-Identifier: GPL-3.0

/// @title Interface for BitstraySantasToken

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

import "./IERC721.sol";
import "./IBitstraysDescriptor.sol";
import "./IBitstraysSeeder.sol";

interface IBitstraySantasToken is IERC721 {
    event BitstraySantaCreated(uint256 indexed tokenId, IBitstraysSeeder.Seed seed);

    event BitstraySantaBurned(uint256 indexed tokenId);

    event BitstraysDAOUpdated(address bitstraysDAO);

    event DescriptorUpdated(IBitstraysDescriptor descriptor);

    event DescriptorLocked();

    event SeederUpdated(IBitstraysSeeder seeder);

    event SeederLocked();

    event PublicMintActive(bool enabled);

    function toggleIsMintActive() external;

    function isMintActive() external returns (bool);

    function mint() external returns (uint256);

    function mintTo(address to) external returns (uint256);

    function giftTo(address to) external returns (uint256);

    function publicMint() external returns (uint256);

    function burn(uint256 tokenId) external;

    function dataURI(uint256 tokenId) external returns (string memory);

    function setBitstraysDAO(address bitstraysDAO) external;

    function setDescriptor(IBitstraysDescriptor descriptor) external;

    function lockDescriptor() external;

    function setSeeder(IBitstraysSeeder seeder) external;

    function lockSeeder() external;
}
