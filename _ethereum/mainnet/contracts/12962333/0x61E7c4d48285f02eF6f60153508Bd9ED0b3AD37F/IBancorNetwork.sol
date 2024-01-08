// SPDX-License-Identifier: MIT
pragma solidity 0.6.12;

interface IBancorNetwork {
  function convertByPath(
      address[] memory _path,
      uint256 _amount,
      uint256 _minReturn,
      address _beneficiary,
      address _affiliateAccount,
      uint256 _affiliateFee
  ) external payable returns (uint256);
}
