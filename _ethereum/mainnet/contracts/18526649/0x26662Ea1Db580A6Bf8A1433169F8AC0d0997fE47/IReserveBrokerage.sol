// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface IReserveBrokerage {
  function burnAndVest(uint amount, uint period, address account) external;
  function depositTokens(uint amount) external;
}