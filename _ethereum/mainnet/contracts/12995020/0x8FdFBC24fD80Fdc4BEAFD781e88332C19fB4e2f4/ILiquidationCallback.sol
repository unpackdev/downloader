// SPDX-License-Identifier: agpl-3.0
pragma solidity 0.7.6;


import "./IERC20Ext.sol";

interface ILiquidationCallback {
  function liquidationCallback(
    address caller,
    IERC20Ext[] calldata sources,
    uint256[] calldata amounts,
    address payable recipient,
    IERC20Ext dest,
    uint256 minReturn,
    bytes calldata txData
  ) external;
}
