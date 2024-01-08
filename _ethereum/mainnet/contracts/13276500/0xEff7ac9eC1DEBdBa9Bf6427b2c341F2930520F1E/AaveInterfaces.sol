// SPDX-License-Identifier: Apache-2.0

pragma solidity ^0.6.12;
pragma experimental ABIEncoderV2;

import "./DataTypes.sol";
import "./ILendingPoolAddressesProvider.sol";
import "./ILendingPool.sol";

// Adding functionality that's deployed to Aave V2 a tokens in production but not yet 
// released on Aave's https://github.com/aave/protocol-v2 repo
// A Token
interface IAToken {
  function UNDERLYING_ASSET_ADDRESS() external returns (address);
  function balanceOf(address owner) external view returns (uint256);
  function totalSupply() external view returns (uint256);
  function decimals() external view returns (uint8);
  function getIncentivesController() external view returns(address);
}

interface IAaveIncentivesController {
  // Differs from Aave's https://github.com/aave/protocol-v2 repo but matches
  // Aave's on-chain incentives controller
  function handleAction(
    address user,
    uint256 totalSupply,
    uint256 userBalance
  ) external;

  function getRewardsBalance(address[] calldata assets, address user)
    external
    view
    returns (uint256);

  function claimRewards(
    address[] calldata assets,
    uint256 amount,
    address to
  ) external returns (uint256);

  function assets(address asset) external view
    returns(
      uint104 emissionPerSecond,
      uint104 index,
      uint40 lastUpdateTimestamp
    );

  function REWARD_TOKEN() external view returns (address);
}
