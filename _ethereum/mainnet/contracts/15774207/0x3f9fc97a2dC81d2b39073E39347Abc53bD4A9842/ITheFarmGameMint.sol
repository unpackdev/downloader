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

pragma solidity ^0.8.17;

interface ITheFarmGameMint {
  function addCommitRandom(uint256 seed) external;

  function canMint() external view returns (bool);

  function getSaleStatus() external view returns (string memory);

  function mint(uint256 quantity, bool stake) external payable;

  function mintCommit(uint256 quantity, bool stake) external;

  function mintCostEGG(uint256 tokenId) external view returns (uint256);

  function mintReveal() external;

  function paused() external view returns (bool);

  function preSaleMint(
    uint256 quantity,
    bool stake,
    bytes32[] memory merkleProof,
    uint256 maxQuantity,
    uint256 priceInWei
  ) external payable;

  function preSaleTokens() external view returns (uint256);

  function preSalePrice() external view returns (uint256);
}
