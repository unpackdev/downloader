// SPDX-License-Identifier: GPL-3.0

pragma solidity =0.6.12;

interface ReserveInterface {
  function reserveRateMantissa() external view returns (uint256);
}
