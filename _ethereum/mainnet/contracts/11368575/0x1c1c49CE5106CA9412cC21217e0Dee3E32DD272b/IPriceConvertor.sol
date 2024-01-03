// SPDX-License-Identifier: MIT
pragma solidity 0.6.12;

interface IPriceConvertor {
  function yCrvToUnderlying(uint256 _token_amount, uint256 i) external view returns (uint256);
}
