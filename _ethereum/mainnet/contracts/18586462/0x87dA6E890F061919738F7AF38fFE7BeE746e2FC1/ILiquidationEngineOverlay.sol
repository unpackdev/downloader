// SPDX-License-Identifier: GPL-3.0
pragma solidity 0.8.19;

interface ILiquidationEngineOverlay {
  function modifyParameters(bytes32 _cType, bytes32 _param, uint256 _data) external;

  function authorizedAccounts(address _account) external view returns (uint256 _authorized);
}
