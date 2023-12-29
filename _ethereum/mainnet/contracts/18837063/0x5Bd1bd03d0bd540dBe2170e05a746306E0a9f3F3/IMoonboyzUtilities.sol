// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;


interface IMoonboyzUtilities {
  function tradingEnabled(address from,address to,uint256 amount) external view returns (bool);
}
