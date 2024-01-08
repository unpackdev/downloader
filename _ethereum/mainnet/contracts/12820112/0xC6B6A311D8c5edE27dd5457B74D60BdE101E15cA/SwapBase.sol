// SPDX-License-Identifier: MIT
import "./Address.sol";
import "./SafeMath.sol";

pragma solidity 0.6.12;

abstract contract SwapBase {

  using Address for address;
  using SafeMath for uint256;

  uint256 public constant PRECISION_DECIMALS = 18;

  address factoryAddress;

  constructor(address _factoryAddress) public {
    require(_factoryAddress!=address(0), "Factory must be set");
    factoryAddress = _factoryAddress;
    initializeFactory();
  }

  function initializeFactory() internal virtual;

  /// @dev Check what token is pool of this Swap
  function isPool(address token) public virtual view returns(bool);

  /// @dev Get underlying tokens and amounts
  function getUnderlying(address token) public virtual view returns (address[] memory, uint256[] memory);

  /// @dev Gives a pool with largest liquidity for a given token and a given tokenset (either keyTokens or pricingTokens)
  function getLargestPool(address token, address[] memory tokenList) public virtual view returns (address, address, uint256);
  // return (largestKeyToken, largestPoolAddress, largestPoolSize);

  /// @dev Generic function giving the price of a given token vs another given token
  function getPriceVsToken(address token0, address token1, address poolAddress) public virtual view returns (uint256) ;

}
