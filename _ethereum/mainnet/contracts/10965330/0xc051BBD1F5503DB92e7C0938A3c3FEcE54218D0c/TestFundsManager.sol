// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.6.0;

import "./FundsManager.sol";

contract TestFundsManager is FundsManager {
  address constant _MOCK_ANYTHING = address(0x919b4b4B561C72c990DC868F751328eF127c45F4);
  address constant _TEST_AUSDC = address(0xbe65A1F9a31D5E81d5e2B863AEf15bF9b3d92891);
  address constant _TEST_CRUSDC = address(0xB63181CD1B0A347003137a9A2703Bb1429FA852a);
  address constant _TEST_USDC = address(0x3307C25998C69ec9c37C71D2D2e2dF837D254133); 
  address constant _TEST_CRV = address(0x25C344e14b5df94e89021f3B09dAd5f462e9B777);
  address constant _TEST_THREE_CRV = address(0xDC150Be5AF9874DBc233Fa4Aebb25a252069851b);
  address constant _TEST_SWERVE_POOL_1 = _MOCK_ANYTHING;
  address constant _TEST_THREE_CRV_GAUGE = _MOCK_ANYTHING;
  address constant _TEST_CRV_MINTR = _MOCK_ANYTHING;
  address constant _TEST_MINTR = _MOCK_ANYTHING;
  address constant _TEST_THREE_POOL_SWAPK = _MOCK_ANYTHING;
  address constant _TEST_CREAM_COMPTROLLER = _MOCK_ANYTHING;
  address constant _TEST_AAVE_LENDING_POOL_CORE = _MOCK_ANYTHING;
  address constant _TEST_AAVE_LENDING_POOL = _MOCK_ANYTHING;
  function USDC() internal override pure returns (address) {
    return _TEST_USDC;
  }
  function AAVE_AUSDC() internal override pure returns (address) {
    return _TEST_AUSDC;
  }
  function SWERVE_POOL_1() internal override pure returns (address) {
    return _TEST_SWERVE_POOL_1;
  }
  function THREE_CRV_GAUGE() internal override pure returns (address) {
    return _TEST_THREE_CRV_GAUGE;
  }
  function CRV() internal override pure returns (address) {
    return _TEST_CRV;
  }
  function CRV_MINTR() internal override pure returns (address) {
    return _TEST_MINTR;
  }
  function THREE_CRV() internal virtual override pure returns (address) {
    return _TEST_THREE_CRV;
  }
  function THREE_POOL_SWAPK() internal override pure returns (address) {
    return _TEST_THREE_POOL_SWAPK;
  }
  function CREAM_COMPTROLLER() internal override pure returns (address) {
    return _TEST_CREAM_COMPTROLLER;
  }
  function CRUSDC() internal override pure returns (address) {
    return _TEST_CRUSDC;
  }
  function AAVE_LENDING_POOL() internal override pure returns (address) {
    return _TEST_AAVE_LENDING_POOL;
  }
  function AAVE_LENDING_POOL_CORE() internal override pure returns (address) {
    return _TEST_AAVE_LENDING_POOL_CORE;
  }
}
