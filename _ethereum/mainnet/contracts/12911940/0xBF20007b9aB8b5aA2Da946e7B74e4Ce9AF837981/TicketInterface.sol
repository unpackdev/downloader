// SPDX-License-Identifier: GPL-3.0

pragma solidity =0.6.12;

interface TicketInterface {
  function draw(uint256 randomNumber) external view returns (address);
}