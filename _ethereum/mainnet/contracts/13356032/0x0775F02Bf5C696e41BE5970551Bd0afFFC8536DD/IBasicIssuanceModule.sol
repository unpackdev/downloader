// SPDX-License-Identifier: UNLICENSED

pragma solidity 0.7.6;

interface IBasicIssuanceModule {
  function issue(
    address _setToken,
    uint256 _quantity,
    address _to
  ) external;

  function getRequiredComponentUnitsForIssue(
    address _setToken,
    uint256 _quantity
  ) external view returns (address[] memory, uint256[] memory);
}
