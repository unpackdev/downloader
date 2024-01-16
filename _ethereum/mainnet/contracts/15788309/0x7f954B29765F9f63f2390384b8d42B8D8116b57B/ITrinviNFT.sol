// SPDX-License-Identifier: MIT

pragma solidity ^0.8.4;

interface ITrinviNFT {

  // Modifiers:
  // - OnlySaleContract
  // - IsInitialized
  function mintTo(address to, uint qty) external;

  // Modifiers:
  // OnlyOwner
  //
  // After called successfully, `isInitialized()` should return true
  function initialize(address saleContract) external;

  function saleContractAddress() external view returns (address);

  // Returns true after `setSaleContract()` is called
  function isInitialized() external view returns (bool);

}