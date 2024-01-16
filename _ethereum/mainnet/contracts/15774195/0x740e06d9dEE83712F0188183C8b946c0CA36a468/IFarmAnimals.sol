// SPDX-License-Identifier: MIT

/*

&_--~- ,_                     /""\      ,
{        ",       THE       <>^  L____/|
(  )_ ,{ ,_@       FARM	     `) /`   , /
 |/  {|\{           GAME       \ `---' /
 ""   " "                       `'";\)`
W: https://thefarm.game           _/_Y
T: @The_Farm_Game

 * Howdy folks! Thanks for glancing over our contracts
 * If you're interested in working with us, you can email us at farmhand@thefarm.game
 * Found a broken egg in our contracts? We have a bug bounty program bugs@thefarm.game
 * Y'all have a nice day

*/

pragma solidity ^0.8.13;

import "./IERC721AQueryable.sol";

interface IFarmAnimals is IERC721AQueryable {
  // Kind of Character
  enum Kind {
    HEN,
    COYOTE,
    ROOSTER
  }

  // NFT Traits
  struct Traits {
    Kind kind;
    uint8 advantage;
    uint8[8] traits;
  }

  function burn(uint16 tokenId) external;

  function maxGen0Supply() external view returns (uint16);

  function maxSupply() external view returns (uint256);

  function getTokenTraits(uint16 tokenId) external view returns (Traits memory);

  function getTokenWriteBlock(uint256 tokenId) external view returns (uint64);

  function mint(address recipient, uint256 seed) external returns (uint16[] memory);

  function minted() external view returns (uint16);

  function mintedRoosters() external returns (uint16);

  function specialMint(
    address recipient,
    uint256 seed,
    uint16 specificKind,
    bool twinHen,
    uint16 quantity
  ) external;

  function ownerOf(uint256 tokenId) external view returns (address owner);

  function safeTransferFrom(
    address from,
    address to,
    uint256 tokenId,
    bytes memory data
  ) external;

  function transferFrom(
    address from,
    address to,
    uint256 tokenId
  ) external;

  function updateAdvantage(
    uint16 tokenId,
    uint8 score,
    bool decrement
  ) external;

  function updateOriginAccess(uint16[] memory tokenIds) external;
}
