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

interface IFarmAnimalsTraits {
  function tokenURI(uint16 tokenId) external view returns (string memory);

  function changeName(uint16 tokenId, string memory name) external;

  function changeDesc(uint16 tokenId, string memory desc) external;

  function changeBGColor(uint16 tokenId, string memory BGColor) external;
}
