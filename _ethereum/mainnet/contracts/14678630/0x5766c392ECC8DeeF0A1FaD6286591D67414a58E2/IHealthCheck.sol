// SPDX-License-Identifier: MIT
pragma solidity =0.8.9;

interface IHealthCheck {
  function check(
    address callerStrategy,
    uint256 profit,
    uint256 loss,
    uint256 debtPayment,
    uint256 debtOutstanding,
    uint256 totalDebt
  ) external view returns (bool);

  function doHealthCheck(address _strategy) external view returns (bool);

  function enableCheck(address _strategy) external;
}
