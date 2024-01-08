// SPDX-License-Identifier: Apache-2.0
pragma solidity >=0.8.0;

contract IyusdiBondingCurves {

  struct BondingCurve {
    uint256 A;
    uint256 B;
    uint256 C;
    int256 D;
    uint256 ConstExp;
    uint256 MaxPrints;
  }

  uint256 constant SIG_DIGITS = 3;
  uint256 constant public ENIGMA_A = 12;
  uint256 constant public ENIGMA_B = 140;
  uint256 constant public ENIGMA_C = 100;
  uint256 constant public ENIGMA_D = 0;
  uint256 constant public ENIGMA_CONST_EXP = 100;
  uint256 constant public ENIGMA_MAX_PRINTS = 160;

  function _getPrintPrice(uint256 printNumber, BondingCurve storage curve) internal view returns (uint256 price) {
    uint256 decimals = 10 ** SIG_DIGITS;
    if (printNumber <= curve.ConstExp) {
      price = 0;
    } else if (printNumber < curve.B) {
      price = (10 ** ( curve.B - printNumber )) * decimals / (curve.A ** ( curve.B - printNumber));
    } else if (printNumber == curve.B) {
      price = decimals;
    } else {
      price = (curve.A ** ( printNumber - curve.B )) * decimals / (10 ** ( printNumber - curve.B ));
    }
    price = price + (curve.C * printNumber);
    int256 adjusted = int256(price) + curve.D;
    require(adjusted >= 0, '!price');
    price = uint256(adjusted);
    // Convert to wei
    price = price * 1 ether / decimals;
  }

  function _getPrintPriceFromMem(uint256 printNumber, BondingCurve memory curve) internal pure returns (uint256 price) {
    uint256 decimals = 10 ** SIG_DIGITS;
    if (printNumber <= curve.ConstExp) {
      price = 0;
    } else if (printNumber < curve.B) {
      price = (10 ** ( curve.B - printNumber )) * decimals / (curve.A ** ( curve.B - printNumber));
    } else if (printNumber == curve.B) {
      price = decimals;
    } else {
      price = (curve.A ** ( printNumber - curve.B )) * decimals / (10 ** ( printNumber - curve.B ));
    }
    price = price + (curve.C * printNumber);
    int256 adjusted = int256(price) + curve.D;
    price = uint256(adjusted);
    // Convert to wei
    price = price * 1 ether / decimals;
  }

  uint256 constant MAX_ITER = 50;
  function _validateBondingCurve(BondingCurve memory curve) internal pure returns(bool) {
    // TODO check these
    require(curve.A > 0, '!A');
    require(curve.B >= 0, '!B');
    require(curve.C > 0, '!C');
    require(curve.ConstExp < curve.B, '!ConstExp');
    require(curve.MaxPrints > curve.B, '!MaxPrints');
    // TODO see how long this takes, should be ok, max 100
    uint256 prev = 0;
    uint256 iter = curve.MaxPrints / MAX_ITER;
    if (iter == 0) iter = 1; 
    for (uint256 i = 0; i < curve.MaxPrints; i += iter) {
      uint256 current = _getPrintPriceFromMem(i + 1, curve);
      require(current > 0 && current >= prev, '!curve');
      prev = current;
    }
    return true;
  }

}
