//SPDX-License-Identifier: Unlicense
pragma solidity 0.8.11;

interface IVoyager {
   function price() external view returns (uint256);
   function supply() external view returns (uint256);
   function totalSupply() external view returns (uint256);
   function adminMint(uint256, address) external;
}