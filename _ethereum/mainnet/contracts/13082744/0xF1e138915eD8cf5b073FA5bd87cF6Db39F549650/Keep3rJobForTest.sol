// SPDX-License-Identifier: UNLICENSED
pragma solidity >=0.8.4 <0.9.0;

import "./Keep3rJob.sol";

contract Keep3rJobForTest is Keep3rJob {
  constructor(
    address _governor,
    address _keep3r,
    address _bond,
    uint256 _minBond,
    uint256 _earned,
    uint256 _age,
    bool _onlyEOA
  ) Governable(_governor) Keep3rJob(_keep3r, _bond, _minBond, _earned, _age, _onlyEOA) {}
}
