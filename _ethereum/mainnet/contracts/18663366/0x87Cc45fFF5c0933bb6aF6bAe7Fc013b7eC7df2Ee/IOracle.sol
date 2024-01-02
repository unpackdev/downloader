//SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.19;

import "./Structs.sol";

interface IOracle {
  function getPriceInUSD(address, AssetInfo calldata) external view returns (uint256);

  function getGweiPrice() external view returns (uint256);
}
