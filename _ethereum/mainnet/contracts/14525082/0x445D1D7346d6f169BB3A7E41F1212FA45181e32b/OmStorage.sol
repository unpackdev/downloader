// SPDX-License-Identifier: MIT
// Omnus Contracts (contracts/storage/OmStorage.sol)
// https://omnuslab.com/omstorage
 
// OmStorage (Gas efficient storage)

pragma solidity ^0.8.13;

import "./Context.sol";  

/**
* @dev OM Storage
* 
* Allows the storage of multiple integers in a single uint256, allowing greatly reduced gas cost for storage.
* For example, rather than defining storage for 12 integers that need to be acccessed individualy, you could use 
* a single storage integer, which needs access only once.
*
* The contract stores a single uint256, the Network Unified Storage, or NUS. This NUS can be broken down into
* units of Operational Memory, called OMs. There can be up to 12 OM in a single NUS.
*
*/

abstract contract OmStorage is Context {

  /**
  *
  * @dev only storage is a single uint256, the NUS:
  *
  */
  uint256 public nus;

  /**
  *
  * @dev mapping details for OMs held as immutable items in the compiled bytecode:
  *
  */
  uint256 private immutable om1Length;
  uint256 private immutable om2Length;
  uint256 private immutable om3Length;
  uint256 private immutable om4Length;
  uint256 private immutable om5Length;
  uint256 private immutable om6Length;
  uint256 private immutable om7Length;
  uint256 private immutable om8Length;
  uint256 private immutable om9Length;
  uint256 private immutable om10Length;
  uint256 private immutable om11Length;
  uint256 private immutable om12Length;

  uint256 private immutable om1Modulo;
  uint256 private immutable om2Modulo;
  uint256 private immutable om3Modulo;
  uint256 private immutable om4Modulo;
  uint256 private immutable om5Modulo;
  uint256 private immutable om6Modulo;
  uint256 private immutable om7Modulo;
  uint256 private immutable om8Modulo;
  uint256 private immutable om9Modulo;
  uint256 private immutable om10Modulo;
  uint256 private immutable om11Modulo;
  uint256 private immutable om12Modulo;

  uint256 private immutable om2Divisor;
  uint256 private immutable om3Divisor;
  uint256 private immutable om4Divisor;
  uint256 private immutable om5Divisor;
  uint256 private immutable om6Divisor;
  uint256 private immutable om7Divisor;
  uint256 private immutable om8Divisor;
  uint256 private immutable om9Divisor;
  uint256 private immutable om10Divisor;
  uint256 private immutable om11Divisor;
  uint256 private immutable om12Divisor;

  /**
  *
  * @dev The contstructor sets up the NUS with the modulo and divisor offsets:
  *
  */
  constructor(uint256 _om1Length, uint256 _om2Length, uint256 _om3Length, uint256 _om4Length, 
    uint256 _om5Length, uint256 _om6Length, uint256 _om7Length, uint256 _om8Length, uint256 _om9Length, 
    uint256 _om10Length, uint256 _om11Length, uint256 _om12Length) {
    
    om1Length  = _om1Length;
    om2Length  = _om2Length;
    om3Length  = _om3Length;
    om4Length  = _om4Length;
    om5Length  = _om5Length;
    om6Length  = _om6Length;
    om7Length  = _om7Length;
    om8Length  = _om8Length;
    om9Length  = _om9Length;
    om10Length = _om10Length;
    om11Length = _om12Length;
    om12Length = _om12Length;

    uint256 moduloExponent;
    uint256 divisorExponent;

    moduloExponent += _om1Length;
    om1Modulo = 10 ** moduloExponent;

    divisorExponent = moduloExponent;
    moduloExponent  += _om2Length;
    om2Divisor      = 10 ** divisorExponent;
    om2Modulo       = 10 ** moduloExponent;

    divisorExponent = moduloExponent;
    moduloExponent  += _om3Length;
    om3Divisor      = 10 ** divisorExponent;
    om3Modulo       = 10 ** moduloExponent;

    divisorExponent = moduloExponent;
    moduloExponent  += _om4Length;
    om4Divisor      = 10 ** divisorExponent;
    om4Modulo       = 10 ** moduloExponent;

    divisorExponent = moduloExponent;
    moduloExponent  += _om5Length;
    om5Divisor      = 10 ** divisorExponent;
    om5Modulo       = 10 ** moduloExponent;

    divisorExponent = moduloExponent;
    moduloExponent  += _om6Length;
    om6Divisor      = 10 ** divisorExponent;
    om6Modulo       = 10 ** moduloExponent;

    divisorExponent = moduloExponent;
    moduloExponent  += _om7Length;
    om7Divisor      = 10 ** divisorExponent;
    om7Modulo       = 10 ** moduloExponent;

    divisorExponent = moduloExponent;
    moduloExponent  += _om8Length;
    om8Divisor      = 10 ** divisorExponent;
    om8Modulo       = 10 ** moduloExponent;

    divisorExponent = moduloExponent;
    moduloExponent  += _om9Length;
    om9Divisor      = 10 ** divisorExponent;
    om9Modulo       = 10 ** moduloExponent;

    divisorExponent = moduloExponent;
    moduloExponent  += _om10Length;
    om10Divisor      = 10 ** divisorExponent;
    om10Modulo       = 10 ** moduloExponent;

    divisorExponent = moduloExponent;
    moduloExponent  += _om11Length;
    om11Divisor      = 10 ** divisorExponent;
    om11Modulo       = 10 ** moduloExponent;

    divisorExponent = moduloExponent;
    moduloExponent  += _om12Length;
    om12Divisor      = 10 ** divisorExponent;
    om12Modulo       = 10 ** moduloExponent;

    require(moduloExponent < 76, "Too wide");
  }

  /**
  *
  * @dev getOmnn function calls return the value for that OM:
  *
  */
  function getOm01() public view returns(uint256 om1_) {
    return(om1Value(nus));
  }
  function getOm02() public view returns(uint256 om2_) {
    return(om2Value(nus));
  }
  function getOm03() public view returns(uint256 om3_) {
    return(om3Value(nus));
  }
  function getOm04() public view returns(uint256 om4_) {
    return(om4Value(nus));
  }
  function getOm05() public view returns(uint256 om5_) {
    return(om5Value(nus));
  }
  function getOm06() public view returns(uint256 om6_) {
    return(om6Value(nus));
  }
  function getOm07() public view returns(uint256 om7_) {
    return(om7Value(nus));
  }
  function getOm08() public view returns(uint256 om8_) {
    return(om8Value(nus));
  }
  function getOm09() public view returns(uint256 om9_) {
    return(om9Value(nus));
  }
  function getOm10() public view returns(uint256 om10_) {
    return(om10Value(nus));
  }
  function getOm11() public view returns(uint256 om11_) {
    return(om11Value(nus));
  }
  function getOm12() public view returns(uint256 om12_) {
    return(om12Value(nus));
  }

  /**
  *
  * @dev omnValue function calls decode a passed NUS value to the OM:
  *
  */
  function om1Value(uint256 _nus) internal view returns(uint256 om1_){
    if (om1Length == 0) return(0);
    return(_nus % om1Modulo);
  }

  function om2Value(uint256 _nus) internal view returns(uint256 om2_) {
    if (om2Length == 0) return(0);
    return((_nus % om2Modulo) / om2Divisor);
  }

  function om3Value(uint256 _nus) internal view returns(uint256 om3_) {
    if (om3Length == 0) return(0);
    return((_nus % om3Modulo) / om3Divisor);
  }

  function om4Value(uint256 _nus) internal view returns(uint256 om4_) {
    if (om4Length == 0) return(0);
    return((_nus % om4Modulo) / om4Divisor);
  }

  function om5Value(uint256 _nus) internal view returns(uint256 om5_) {
    if (om5Length == 0) return(0);
    return((_nus % om5Modulo) / om5Divisor);
  }

  function om6Value(uint256 _nus) internal view returns(uint256 om6_) {
    if (om6Length == 0) return(0);
    return((_nus % om6Modulo) / om6Divisor);
  }

  function om7Value(uint256 _nus) internal view returns(uint256 om7_) {
    if (om7Length == 0) return(0);
    return((_nus % om7Modulo) / om7Divisor);
  }

  function om8Value(uint256 _nus) internal view returns(uint256 om8_) {
    if (om8Length == 0) return(0);
    return((_nus % om8Modulo) / om8Divisor);
  }

  function om9Value(uint256 _nus) internal view returns(uint256 om9_) {
    if (om9Length == 0) return(0);
    return((_nus % om9Modulo) / om9Divisor);
  }

  function om10Value(uint256 _nus) internal view returns(uint256 om10_) {
    if (om10Length == 0) return(0);
    return((_nus % om10Modulo) / om10Divisor);
  }

  function om11Value(uint256 _nus) internal view returns(uint256 om11_) {
    if (om11Length == 0) return(0);
    return((_nus % om11Modulo) / om11Divisor); 
  }

  function om12Value(uint256 _nus) internal view returns(uint256 om12_) {
    if (om12Length == 0) return(0);
    return((_nus % om12Modulo) / om12Divisor);  
  }

  /**
  *
  * @dev Decode the full NUS into OMs
  *
  */
  function decodeNus() public view returns(uint256 om1, uint256 om2, uint256 om3, uint256 om4, uint256 om5, 
  uint256 om6, uint256 om7, uint256 om8, uint256 om9, uint256 om10, uint256 om11, uint256 om12){

    uint256 _nus = nus;

    om1 = om1Value(_nus);
    if (om2Length == 0)  return(om1, om2, om3, om4, om5, om6, om7, om8, om9, om10, om11, om12);
      om2 = om2Value(_nus);
    if (om3Length == 0)  return(om1, om2, om3, om4, om5, om6, om7, om8, om9, om10, om11, om12);
      om3 = om3Value(_nus);
    if (om4Length == 0)  return(om1, om2, om3, om4, om5, om6, om7, om8, om9, om10, om11, om12);
      om4 = om4Value(_nus);
    if (om5Length == 0)  return(om1, om2, om3, om4, om5, om6, om7, om8, om9, om10, om11, om12);
      om5 = om5Value(_nus);
    if (om6Length == 0)  return(om1, om2, om3, om4, om5, om6, om7, om8, om9, om10, om11, om12);
      om6 = om6Value(_nus);
    if (om7Length == 0)  return(om1, om2, om3, om4, om5, om6, om7, om8, om9, om10, om11, om12);
      om7 = om7Value(_nus);
    if (om8Length == 0)  return(om1, om2, om3, om4, om5, om6, om7, om8, om9, om10, om11, om12);
      om8 = om8Value(_nus);
    if (om9Length == 0)  return(om1, om2, om3, om4, om5, om6, om7, om8, om9, om10, om11, om12);
      om9 = om9Value(_nus);
    if (om10Length == 0) return(om1, om2, om3, om4, om5, om6, om7, om8, om9, om10, om11, om12);
      om10 = om10Value(_nus);
    if (om11Length == 0) return(om1, om2, om3, om4, om5, om6, om7, om8, om9, om10, om11, om12);
      om11 = om11Value(_nus);
    if (om12Length == 0) return(om1, om2, om3, om4, om5, om6, om7, om8, om9, om10, om11, om12);
      om12 = om12Value(_nus);
    return(om1, om2, om3, om4, om5, om6, om7, om8, om9, om10, om11, om12);
  }

  /**
  *
  * @dev Encode the OMs to the NUS
  *
  */
  function encodeNus(uint256 _om1, uint256 _om2, uint256 _om3, uint256 _om4, uint256 _om5, 
  uint256 _om6, uint256 _om7, uint256 _om8, uint256 _om9, uint256 _om10, uint256 _om11, uint256 _om12) internal {
    checkOverflow(_om1,_om2, _om3, _om4, _om5, _om6, _om7, _om8, _om9, _om10, _om11, _om12);
    nus = sumOmNus (_om1,_om2, _om3, _om4, _om5, _om6, _om7, _om8, _om9, _om10, _om11, _om12);      
  }

  /**
  *
  * @dev Sum variables
  *
  */
  function sumOmNus(uint256 _om1, uint256 _om2, uint256 _om3, uint256 _om4, uint256 _om5, 
  uint256 _om6, uint256 _om7, uint256 _om8, uint256 _om9, uint256 _om10, uint256 _om11, uint256 _om12) view internal returns(uint256 nus_) {
    nus_ = _om1;
    if (om2Length == 0)  return(nus_);
    nus_ += _om2 * om2Divisor;
    if (om3Length == 0)  return(nus_);
    nus_ += _om3 * om3Divisor;
    if (om4Length == 0)  return(nus_);
    nus_ += _om4 * om4Divisor;
    if (om5Length == 0)  return(nus_);
    nus_ += _om5 * om5Divisor;
    if (om6Length == 0)  return(nus_);
    nus_ += _om6 * om6Divisor;
    if (om7Length == 0)  return(nus_);
    nus_ += _om7 * om7Divisor;
    if (om8Length == 0)  return(nus_);
    nus_ += _om8 * om8Divisor;
    if (om9Length == 0)  return(nus_);
    nus_ += _om9 * om9Divisor;
    if (om10Length == 0)  return(nus_);
    nus_ += _om10 * om10Divisor;
    if (om11Length == 0)  return(nus_);
    nus_ += _om11 * om11Divisor;
    if (om12Length == 0)  return(nus_);
    nus_ += _om12 * om12Divisor;
    return(nus_);
  }        

  /**
  *
  * @dev Check for OM overflow
  *
  */
  function checkOverflow(uint256 _om1, uint256 _om2, uint256 _om3, uint256 _om4, uint256 _om5, 
  uint256 _om6, uint256 _om7, uint256 _om8, uint256 _om9, uint256 _om10, uint256 _om11, uint256 _om12) view internal {
    require((_om1  / om1Modulo == 0), "om1 overflow");
    if (om2Length == 0) return;
    require((_om2  / om2Modulo == 0), "om2 overflow");
    if (om3Length == 0) return;
    require((_om3  / om3Modulo == 0), "om3 overflow");
    if (om4Length == 0) return;
    require((_om4  / om4Modulo == 0), "om4 overflow");
    if (om5Length == 0) return;
    require((_om5  / om5Modulo == 0), "om5 overflow");
    if (om6Length == 0) return;
    require((_om6  / om6Modulo == 0), "om6 overflow");
    if (om7Length == 0) return;
    require((_om7  / om7Modulo == 0), "om7 overflow");
    if (om8Length == 0) return;
    require((_om8  / om8Modulo == 0), "om8 overflow");
    if (om9Length == 0) return;
    require((_om9  / om9Modulo == 0), "om9 overflow");
    if (om10Length == 0) return;
    require((_om10 / om10Modulo == 0), "om10 overflow");
    if (om11Length == 0) return;
    require((_om11 / om11Modulo == 0), "om11 overflow");
    if (om2Length == 0) return;
    require((_om12 / om12Modulo == 0), "om12 overflow"); 
  }
}