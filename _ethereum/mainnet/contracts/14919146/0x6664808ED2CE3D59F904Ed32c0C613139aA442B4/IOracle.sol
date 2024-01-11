// SPDX-License-Identifier: MIT
pragma solidity >=0.7.6 <=0.8.9;

interface IOracle {

  function price(address[] memory tokenPath, address[] memory quotePools, uint8 fromDecimals, uint32 period) external view returns (uint256);

}
