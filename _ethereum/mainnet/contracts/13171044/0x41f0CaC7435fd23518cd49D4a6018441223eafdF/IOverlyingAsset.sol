// SPDX-License-Identifier: AGPL-3.0
pragma solidity 0.6.12;

interface IOverlyingAsset {
  function UNDERLYING_ASSET_ADDRESS() external view returns (address);
}
