// SPDX-License-Identifier: MIT

pragma solidity >=0.6.12;
pragma experimental ABIEncoderV2;

import "./IGoldfinchConfig.sol";
import "./IGoldfinchFactory.sol";
import "./IERC20.sol";
import "./IStakingRewards.sol";

interface IProtocolHelper {
  function gfConfig() external returns (IGoldfinchConfig);

  function fidu() external returns (IERC20);

  function gfi() external returns (IERC20);

  function gfFactory() external returns (IGoldfinchFactory);

  function stakingRewards() external returns (IStakingRewards);

  function usdc() external returns (IERC20);
}
