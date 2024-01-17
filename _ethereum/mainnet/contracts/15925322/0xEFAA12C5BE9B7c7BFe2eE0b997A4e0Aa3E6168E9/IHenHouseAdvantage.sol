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

interface IHenHouseAdvantage {
  // struct to store the production bonus info of all nfts
  struct AdvantageBonus {
    uint256 tokenId;
    uint256 bonusPercentage;
    uint256 bonusDurationMins;
    uint256 startTime;
  }

  function addAdvantageBonus(
    uint256 tokenId,
    uint256 _durationMins,
    uint256 _percentage
  ) external;

  function removeAdvantageBonus(uint256 tokenId) external;

  function getAdvantageBonus(uint256 tokenId) external view returns (AdvantageBonus memory);

  function updateAdvantageBonus(uint256 tokenId) external;

  function calculateAdvantageBonus(uint256 tokenId, uint256 owed) external view returns (uint256);
}
