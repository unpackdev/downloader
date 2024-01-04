// SPDX-License-Identifier: MIT
pragma solidity 0.7.6;

import "./SafeMath.sol";

import "./Ownable.sol";

import "./Oracle.sol";
import "./TokenManager.sol";
import "./DiscountManager.sol";
import "./VersionManager.sol";


interface ICollateralManager
{
  function isSufficientInitialCollateral(address lendingToken, uint256 principal, address collateralToken, uint256 collateralAmount) external view returns (bool);

  // returns (bool isSufficient, uint collateralRatio%);
  function isSufficientCollateral(address borrower, address lendingToken, uint256 principal, address collateralToken, uint256 collateralAmount) external view returns (bool, uint256);
}

contract CollateralManager is ICollateralManager, Ownable, VersionManager
{
  using SafeMath for uint256;


  uint256 private constant _BASIS_POINT = 10000; // 100%

  mapping(address => uint256) private _initThreshold;
  mapping(address => uint256) private _liquidationThreshold;



  function _calcPercentOf(uint256 amount, uint256 percent) private pure returns (uint256)
  {
    return amount.mul(percent).div(_BASIS_POINT);
  }

  function getThresholds(address token) external view returns (uint256, uint256)
  {
    return (_initThreshold[token], _liquidationThreshold[token]);
  }

  function setInitThresholds(address[] calldata tokens, uint256[] calldata thresholds) external onlyOwner
  {
    require(tokens.length == thresholds.length, "!=");

    for (uint256 i = 0; i < tokens.length; i++)
    {
      address token = tokens[i];
      uint256 threshold = thresholds[i];

      require(token != address(0), "0 addy");
      require(threshold > 10000, "Invalid val"); // 100%

      _initThreshold[token] = threshold;
    }
  }

  function setLiquidationThresholds(address[] calldata tokens, uint256[] calldata thresholds) external onlyOwner
  {
    require(tokens.length == thresholds.length, "!=");

    for (uint256 i = 0; i < tokens.length; i++)
    {
      address token = tokens[i];
      uint256 threshold = thresholds[i];

      require(token != address(0), "0 addy");
      require(threshold > 10000 && threshold <= 17500, "Invalid val");

      _liquidationThreshold[token] = threshold;
    }
  }


  function _convert(address from, address to, uint256 amount) private view returns (uint256)
  {
    return IOracle(VersionManager._oracle()).convert(from, to, amount);
  }

  function _isValidPairing(address lendingToken, address collateralToken) private view returns (bool)
  {
    return (lendingToken != collateralToken) && ITokenManager(VersionManager._tokenMgr()).isBothWhitelisted(lendingToken, collateralToken) && !ITokenManager(VersionManager._tokenMgr()).isBothStable(lendingToken, collateralToken);
  }

  function isSufficientInitialCollateral(address lendingToken, uint256 principal, address collateralToken, uint256 collateralAmount) external view override returns (bool)
  {
    require(_isValidPairing(lendingToken, collateralToken), "Bad pair");

    uint256 convertedPrincipal = _convert(lendingToken, collateralToken, _calcPercentOf(principal, _initThreshold[collateralToken]));

    return collateralAmount >= convertedPrincipal;
  }

  function isSufficientCollateral(address borrower, address lendingToken, uint256 principal, address collateralToken, uint256 collateralAmount) external view override returns (bool, uint256)
  {
    uint256 collateralThreshold = _liquidationThreshold[collateralToken];

    if (IDiscountManager(VersionManager._discountMgr()).isDiscounted(borrower))
    {
      collateralThreshold = ITokenManager(VersionManager._tokenMgr()).isStableToken(collateralToken) ? collateralThreshold.sub(250) : collateralThreshold.sub(500);
    }

    uint256 convertedPrincipal = _convert(lendingToken, collateralToken, _calcPercentOf(principal, collateralThreshold));

    return (collateralAmount > convertedPrincipal, collateralAmount.div(convertedPrincipal.div(collateralThreshold)));
  }
}
