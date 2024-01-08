// SPDX-License-Identifier: UNLICENSED
pragma solidity >=0.8.4 <0.9.0;

import "./Governable.sol";

contract GovernableForTest is Governable {
  constructor(address _governor) Governable(_governor) {}
}
