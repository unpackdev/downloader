// SPDX-License-Identifier: MIT
pragma solidity ^0.6.0;

import "./TimedVault.sol";

contract WSBETHLPVault is TimedVault {
  constructor(address beneficiary) TimedVault(0x177BA6390e3434801529724019e1eaECc7130655, beneficiary) public {
  }
}
