// SPDX-License-Identifier: MIT
pragma solidity 0.8.9;

import "./PaymentSplitter.sol";

contract Treasury is PaymentSplitter {
   address[] public shareholders = [
       0xEFCd4BEBb296E11729cD2cE33B19093FE838044e,
       0x839802854939d444B90451Ed31CaC1dd624d25cE,
       0xC90741D8C64092079fE887Bf7B1D3999e265cd08,
       0xa81BB6074D3fa1F69e24Bb3e7DC0329677ffBB60,
       0xa6564E2a8b74A9fEC918C38f2a698e7cba0A96Aa,
       0x6c979141D9173369437A6E64961883248B98F4D9
   ];
   uint256[] public percentageStakes = [
       100,
       466,
       466,
       466,
       6502,
       2000
   ];
  constructor() PaymentSplitter(shareholders, percentageStakes) {}
}
