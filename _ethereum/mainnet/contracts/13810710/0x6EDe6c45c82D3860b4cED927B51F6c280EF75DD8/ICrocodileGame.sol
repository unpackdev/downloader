/*
 ██████╗██████╗  ██████╗  ██████╗ ██████╗ ██████╗ ██╗██╗     ███████╗     ██████╗  █████╗ ███╗   ███╗███████╗
██╔════╝██╔══██╗██╔═══██╗██╔════╝██╔═══██╗██╔══██╗██║██║     ██╔════╝    ██╔════╝ ██╔══██╗████╗ ████║██╔════╝
██║     ██████╔╝██║   ██║██║     ██║   ██║██║  ██║██║██║     █████╗      ██║  ███╗███████║██╔████╔██║█████╗  
██║     ██╔══██╗██║   ██║██║     ██║   ██║██║  ██║██║██║     ██╔══╝      ██║   ██║██╔══██║██║╚██╔╝██║██╔══╝  
╚██████╗██║  ██║╚██████╔╝╚██████╗╚██████╔╝██████╔╝██║███████╗███████╗    ╚██████╔╝██║  ██║██║ ╚═╝ ██║███████╗
 ╚═════╝╚═╝  ╚═╝ ╚═════╝  ╚═════╝ ╚═════╝ ╚═════╝ ╚═╝╚══════╝╚══════╝     ╚═════╝ ╚═╝  ╚═╝╚═╝     ╚═╝╚══════╝
*/

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.10;

interface ICrocodileGame {
  function stakeTokens(address, uint16[] calldata, uint8[] calldata) external;
  //function randomFoxOwner(uint256) external view returns (address);
  function randomKarmaOwner(uint256) external view returns (address);
  //function isValidSignature(address, bool, uint48, uint256, bytes memory) external view returns (bool);
}