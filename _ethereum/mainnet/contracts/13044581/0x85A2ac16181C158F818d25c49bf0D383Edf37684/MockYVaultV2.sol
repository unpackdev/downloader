pragma solidity ^0.8.5;

import "./IYVaultV2.sol";

/**
 * @notice Mock yVault, implemented the same way as a Yearn vault, but with configurable parameters for testing
 */
contract MockYVaultV2 is IYVaultV2 {
  uint256 public override pricePerShare;
  uint256 public underlyingDecimals = 6; // decimals of USDC underlying
  uint256 public override totalSupply; // not used, but needed so this is not an abstract contract

  constructor() {
    // Initializing the values based on the yUSDC values on 2021-06-03
    pricePerShare = 1058448;
  }

  /**
   * @notice Set the pricePerShare
   * @param _pricePerShare New pricePerShare value
   */
  function set(uint256 _pricePerShare) external {
    pricePerShare = _pricePerShare;
  }
}
