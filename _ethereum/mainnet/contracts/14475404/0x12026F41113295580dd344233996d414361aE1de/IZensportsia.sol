// SPDX-License-Identifier: MIT
pragma solidity 0.8.2;

interface IZensportsia {
  struct SalePlans {
    uint256 startTime;
    uint256 mintPrice1;
    uint256 mintPrice2;
    uint256 limitPerMint;
    uint256 presaleAllocation;
    uint256 teamAllocation;
  }

  function mint(uint256) external payable;

  function mintForTeam(address[] memory, uint256[] memory) external;
}
