/*
  .oooooo.              o8o                           o8o                     
 d8P'  `Y8b             `"'                           `"'                     
888           .ooooo.  oooo  ooo. .oo.   oooo    ooo oooo   .oooo.o  .ooooo.  
888          d88' `88b `888  `888P"Y88b   `88.  .8'  `888  d88(  "8 d88' `88b 
888          888   888  888   888   888    `88..8'    888  `"Y88b.  888ooo888 
`88b    ooo  888   888  888   888   888     `888'     888  o.  )88b 888    .o 
 `Y8bood8P'  `Y8bod8P' o888o o888o o888o     `8'     o888o 8""888P' `Y8bod8P' 
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface IVestingProxy {
  function vestingFactory() external view returns (address);

  function vesting() external view returns (address);

  function upgradeVesting(address) external;
}
