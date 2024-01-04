// SPDX-License-Identifier: agpl-3.0
pragma solidity 0.6.12;

import "./IERC20.sol";

interface IATokenV1 is IERC20 {
  function redeem(uint256 _amount) external;

  function underlyingAssetAddress() external view returns (address);
}
