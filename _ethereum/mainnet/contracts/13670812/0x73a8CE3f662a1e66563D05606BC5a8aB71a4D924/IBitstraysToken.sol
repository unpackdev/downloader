// SPDX-License-Identifier: GPL-3.0

/// @title Interface for BitstraysToken

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

interface IBitstraysToken is IERC721 {
    event BitstrayCreated(uint256 indexed tokenId, IBitstraysSeeder.Seed seed);

    event BitstrayBurned(uint256 indexed tokenId);

    event BitstraysDAOUpdated(address bitstraysDAO);

    event DescriptorUpdated(IBitstraysDescriptor descriptor);

    event DescriptorLocked();

    event SeederUpdated(IBitstraysSeeder seeder);

    event SeederLocked();

    event PublicSaleActive(bool enabled);

    event PublicPresaleActive(bool enabled);

    function toggleIsSaleActive() external;

    function toggleIsPresaleActive() external;

    function isSaleActive() external returns (bool);

    function isPresaleActive() external returns (bool);

    function mint() external returns (uint256);

    function mintTo(address to) external returns (uint256);

    function publicMint(uint256 amount, bytes32[] memory proof) external payable;

    function burn(uint256 tokenId) external;

    function dataURI(uint256 tokenId) external returns (string memory);

    function setBitstraysDAO(address bitstraysDAO) external;

    function setDescriptor(IBitstraysDescriptor descriptor) external;

    function lockDescriptor() external;

    function setSeeder(IBitstraysSeeder seeder) external;

    function lockSeeder() external;

    function getTokensMintedAtPresale(address account) external returns(uint256);
}
