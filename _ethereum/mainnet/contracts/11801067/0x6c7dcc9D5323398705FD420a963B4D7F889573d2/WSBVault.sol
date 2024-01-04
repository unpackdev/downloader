// SPDX-License-Identifier: MIT
pragma solidity ^0.6.0;

import "./TimedVault.sol";

contract WSBVault is TimedVault {
  constructor(address beneficiary) TimedVault(0x9d0A4859Aa6a2909E7421b09F701f677F27f1aB4, beneficiary) public {
  }
}
