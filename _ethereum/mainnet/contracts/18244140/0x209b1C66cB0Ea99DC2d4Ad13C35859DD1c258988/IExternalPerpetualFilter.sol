// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.18;

interface IExternalPerpetualFilter {
  function verifyPerpetual(address perpetual) external view returns(bool isPerpetual);
}
