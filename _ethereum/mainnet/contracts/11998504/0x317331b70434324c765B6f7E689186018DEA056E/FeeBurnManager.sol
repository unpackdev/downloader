// SPDX-License-Identifier: MIT
pragma solidity 0.7.6;

import "./SafeMath.sol";

import "./Ownable.sol";

import "./Oracle.sol";
import "./DiscountManager.sol";
import "./VersionManager.sol";


interface IFeeBurnManager
{
  function burner() external view returns (address);

  function getDefaultingFee(uint256 collateral) external view returns (uint256);

  function getFeeOnInterest(address lender, address lendingToken, uint256 principal, uint256 interest) external view returns (uint256);

  function getFeeOnPrincipal(address borrower, address lendingToken, uint256 principal, address collateralToken) external view returns (uint256);
}


contract FeeBurnManager is IFeeBurnManager, Ownable, VersionManager
{
  using SafeMath for uint256;


  uint256 private constant _BASIS_POINT = 10000;

  address private _burner;
  uint256 private _defaultingFeePct = 700;
  uint256 private _lenderInterestFeePct = 750;
  uint256 private _borrowerPrincipalFeePct = 100;


  constructor()
  {
    _burner = msg.sender;
  }

  function _calcPercentOf(uint256 amount, uint256 percent) private pure returns (uint256)
  {
    return amount.mul(percent).div(_BASIS_POINT);
  }

  function burner() external view override returns (address burnerAddress)
  {
    return _burner;
  }

  function getFeePcts () public view returns (uint256, uint256, uint256)
  {
    return (_lenderInterestFeePct, _borrowerPrincipalFeePct, _defaultingFeePct);
  }

  function getFeeOnInterest(address lender, address lendingToken, uint256 principal, uint256 interest) external view override returns (uint256)
  {
    uint256 interestAmount = _calcPercentOf(principal, interest);
    uint256 oneUSDOfToken = IOracle(VersionManager._oracle()).convertFromUSD(lendingToken, 1e18);

    uint256 discountedFeePct = _calcPercentOf(_lenderInterestFeePct, 7500); // 7500 = 75%

    uint256 fee = _calcPercentOf(interestAmount, IDiscountManager(VersionManager._discountMgr()).isDiscounted(lender) ? discountedFeePct : _lenderInterestFeePct);

    return fee < oneUSDOfToken ? oneUSDOfToken : fee;
  }

  function getFeeOnPrincipal(address borrower, address lendingToken, uint256 principal, address collateralToken) external view override returns (uint256)
  {
    return _calcPercentOf(IOracle(VersionManager._oracle()).convert(lendingToken, collateralToken, principal), IDiscountManager(VersionManager._discountMgr()).isDiscounted(borrower) ? _borrowerPrincipalFeePct.sub(25) : _borrowerPrincipalFeePct);
  }

  function getDefaultingFee(uint256 collateral) external view override returns (uint256)
  {
    return _calcPercentOf(collateral, _defaultingFeePct);
  }

  function setBurner(address newBurner) external onlyOwner
  {
    require(newBurner != address(0), "0 addy");

    _burner = newBurner;
  }

  function setDefaultingFeePct(uint256 newPct) external onlyOwner
  {
    require(newPct > 0 && newPct <= 750, "Invalid val"); // 750 = 7.5%

    _defaultingFeePct = newPct;
  }

  function setPeerFeePcts(uint256 newLenderFeePct, uint256 newBorrowerFeePct) external onlyOwner
  {
    require(newLenderFeePct > 0 && newBorrowerFeePct > 0, "0% fee");
    require(newLenderFeePct <= 1000 && newBorrowerFeePct <= 150, "Too high"); // 1000 = 10%

    _lenderInterestFeePct = newLenderFeePct;
    _borrowerPrincipalFeePct = newBorrowerFeePct;
  }
}
