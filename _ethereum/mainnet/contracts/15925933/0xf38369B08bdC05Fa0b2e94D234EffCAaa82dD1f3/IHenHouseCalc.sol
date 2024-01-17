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

import "./IHenHouse.sol";

pragma solidity ^0.8.17;

interface IHenHouseCalc {
  // struct to store a stake's token, owner, and earning values
  struct Stake {
    uint16 tokenId;
    address owner;
    uint80 eggPerRank; // This is the value of EggPerRank (Coyote/Rooster)
    uint80 rescueEggPerRank; // Value per rank of rescued $EGG
    uint256 oneOffEgg; // One off per staker
    uint256 stakedTimestamp;
    uint256 unstakeTimestamp;
  }

  function calculateRewards(uint256 tokenId) external view returns (uint256 owed);

  function calculateAllRewards(uint256[] calldata tokenIds) external view returns (uint256 owed);

  function calculateRewardsHen(uint256 tokenId, IHenHouse.Stake memory stake) external returns (uint256 owed);

  function calculateRewardsCoyote(uint256 tokenId, uint8 rank) external returns (uint256 owed);

  function calculateRewardsRooster(
    uint256 tokenId,
    uint8 rank,
    IHenHouse.Stake memory stake
  ) external returns (uint256 owed);
}
