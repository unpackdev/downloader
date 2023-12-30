pragma experimental ABIEncoderV2;
// SPDX-License-Identifier: MIT
pragma solidity ^0.6.0;

import "./BorrowProxyLib.sol";

interface IModuleRegistryProvider {
  function fetchModuleHandler(address to, bytes4 sig) external returns (BorrowProxyLib.Module memory);
}
