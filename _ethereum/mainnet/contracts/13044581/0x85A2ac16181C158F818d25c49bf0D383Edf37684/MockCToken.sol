pragma solidity ^0.8.5;

import "./ICToken.sol";

/**
 * @notice Mock CToken, implemented the same way as a Compound CToken, but with configurable parameters for testing
 */

contract MockCToken is ICToken {
  uint256 public override totalReserves;
  uint256 public override totalBorrows;
  uint256 public override totalSupply;
  uint256 public override exchangeRateStored;
  uint256 internal cash; // this is the balanceOf the underlying ERC20/ETH
  uint256 public underlyingDecimals = 6; // decimals of USDC underlying

  constructor() {
    // Initializing the values based on the cUSDC values on 2021-05-10 (around block 12,409,320)
    totalReserves = 5359893964073; // units of USDC
    totalBorrows = 3681673803163527; // units of USDC
    totalSupply = 20287132947568793418; // units of cUSDC
    exchangeRateStored = 219815665774648; // units of 10^(18 + underlyingDecimals - 8)
    cash = 783115726329188; // units of USDC
  }

  /**
   * @notice Set the value of a parameter
   * @param _name Name of the variable to set
   * @param _value Value to set the parameter to
   */
  function set(bytes32 _name, uint256 _value) external {
    if (_name == "totalReserves") totalReserves = _value;
    if (_name == "totalBorrows") totalBorrows = _value;
    if (_name == "totalSupply") totalSupply = _value;
    if (_name == "exchangeRateStored") exchangeRateStored = _value;
    if (_name == "cash") cash = _value;
  }

  /**
   * @notice Get cash balance of this cToken in the underlying asset
   * @return The quantity of underlying asset owned by this contract
   */
  function getCash() external view override returns (uint256) {
    return cash;
  }
}
