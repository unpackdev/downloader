// SPDX-License-Identifier: MIT
pragma solidity ^0.8.7;
import "./IERC20Upgradeable.sol";

interface IRibbonPoolMaster is IERC20Upgradeable {
  function getCurrentExchangeRate() external view returns (uint256);

  function provide(uint256 usdcAmount, address referral) external;

  function redeem(uint256 tokenAmount) external;
}
