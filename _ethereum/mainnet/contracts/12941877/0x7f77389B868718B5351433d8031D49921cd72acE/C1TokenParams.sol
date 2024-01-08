// SPDX-License-Identifier: MIT
pragma solidity =0.7.6;

import "./CompoundInterfaces.sol";
import "./LowGasSafeMath.sol";
import "./MinimalSignedMath.sol";


library C1TokenParams {
  using LowGasSafeMath for uint256;
  using MinimalSignedMath for uint256;

  uint256 internal constant EXP_SCALE = 1e18;
  uint256 internal constant HALF_EXP_SCALE = 5e17;

  function getInterestRateParametersV1(address token) internal view returns (
    address model,
    uint256 cashPrior,
    uint256 borrowsPrior,
    uint256 reservesPrior,
    uint256 reserveFactorMantissa
  ) {
    ICToken cToken = ICToken(token);
    model = address(cToken.interestRateModel());
    cashPrior = cToken.getCash();
    borrowsPrior = cToken.totalBorrows();
    reservesPrior = cToken.totalReserves();
    uint256 accrualBlockNumber = cToken.accrualBlockNumber();
    reserveFactorMantissa = cToken.reserveFactorMantissa();
    if (block.number > accrualBlockNumber) {
      uint256 blockDelta = block.number - accrualBlockNumber;
      uint256 pendingBorrowRate = getBorrowRate(model, cashPrior, borrowsPrior, reservesPrior);
      uint256 interestAccumulated = mulScalarTruncate(pendingBorrowRate.mul(blockDelta), borrowsPrior);
      borrowsPrior = borrowsPrior.add(interestAccumulated);
      reservesPrior = mulScalarTruncate(reserveFactorMantissa, interestAccumulated).add(reservesPrior);
    }
  }

  function computeSupplyRateV1(
    address model,
    uint256 cashPrior,
    uint256 borrowsPrior,
    uint256 reservesPrior,
    uint256 reserveFactorMantissa,
    int256 liquidityDelta
  ) internal view returns (uint256) {
    uint256 underlying = cashPrior.add(liquidityDelta).add(borrowsPrior).sub(reservesPrior).mul(1e18);
    uint256 borrowsPer = divScalarByExp(borrowsPrior, underlying);
    uint256 borrowRateMantissa = getBorrowRate(model, cashPrior, borrowsPrior, reservesPrior);
    uint256 oneMinusReserveFactor = EXP_SCALE.sub(reserveFactorMantissa);
    return mulExp3(borrowRateMantissa, oneMinusReserveFactor, borrowsPer);
  }

  function getSupplyRateV1(address token, int256 liquidityDelta) internal view returns (uint256) {
    (
      address model,
      uint256 cashPrior,
      uint256 borrowsPrior,
      uint256 reservesPrior,
      uint256 reserveFactorMantissa
    ) = getInterestRateParametersV1(token);
    uint256 underlying = cashPrior.add(liquidityDelta).add(borrowsPrior).sub(reservesPrior).mul(1e18);
    uint256 borrowsPer = divScalarByExp(borrowsPrior, underlying);
    uint256 borrowRateMantissa = getBorrowRate(model, cashPrior, borrowsPrior, reservesPrior);
    uint256 oneMinusReserveFactor = EXP_SCALE.sub(reserveFactorMantissa);
    return mulExp3(borrowRateMantissa, oneMinusReserveFactor, borrowsPer);
  }

  function currentExchangeRate(address token) internal view returns (uint256 exchangeRate) {
    ICToken cToken = ICToken(token);
    uint256 blockDelta = block.number - cToken.accrualBlockNumber();
    if (blockDelta == 0) {
      return cToken.exchangeRateStored();
    }

    IInterestRateModel model = cToken.interestRateModel();

    uint256 cashPrior = cToken.getCash();
    uint256 borrowsPrior = cToken.totalBorrows();
    uint256 reservesPrior = cToken.totalReserves();
    uint256 reserveFactorMantissa = cToken.reserveFactorMantissa();
    if (blockDelta > 0) {
      uint256 borrowRateMantissa = getBorrowRate(address(model), cashPrior, borrowsPrior, reservesPrior);
      uint256 interestAccumulated = mulScalarTruncate(borrowRateMantissa.mul(blockDelta), borrowsPrior);
      borrowsPrior = borrowsPrior.add(interestAccumulated);
      reservesPrior = mulScalarTruncate(reserveFactorMantissa, interestAccumulated).add(reservesPrior);
    }

    return cashPrior.add(borrowsPrior).sub(reservesPrior).mul(1e18) / ICToken(token).totalSupply();
  }
  

  function truncate(uint256 x) internal pure returns (uint256) {
    return x / EXP_SCALE;
  }

  function mulScalarTruncate(uint256 x, uint256 y) internal pure returns (uint256) {
    return truncate(x.mul(y));
  }

  function mulScalarTruncateAddUInt(uint256 x, uint256 y, uint256 z) internal pure returns (uint256) {
    return mulScalarTruncate(x, y).add(z);
  }

  function divScalarByExp(uint256 scalar, uint256 exp) internal pure returns (uint256) {
    uint256 numerator = scalar.mul(EXP_SCALE);
    return numerator.mul(EXP_SCALE) / exp;
  }

  function mulExp(uint256 a, uint256 b) internal pure returns (uint256) {
    uint256 doubleScaledProduct = a.mul(b);
    uint256 doubleScaledProductWithHalfScale = HALF_EXP_SCALE.add(doubleScaledProduct);
    return doubleScaledProductWithHalfScale / EXP_SCALE;
  }

  function mulExp3(uint256 a, uint256 b, uint256 c) internal pure returns (uint256) {
    uint256 ab = mulExp(a, b);
    return mulExp(ab, c);
  }

  function getBorrowRate(
    address model,
    uint256 cash,
    uint256 borrows,
    uint256 reserves
  ) internal view returns (uint256 borrowRateMantissa) {
    (bool success, bytes memory retData) = model.staticcall(
      abi.encodeWithSelector(
        IInterestRateModel.getBorrowRate.selector,
        cash,
        borrows,
        reserves
      )
    );
    if (!success) revert(abi.decode(retData, (string)));
    assembly {
      switch lt(mload(retData), 64)
      case 0 {borrowRateMantissa := mload(add(retData, 64))}
      default {borrowRateMantissa := mload(add(retData, 32))}
    }
  }
}