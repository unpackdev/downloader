// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity ^0.6.0;

abstract contract OracleAncillaryInterface {
  function requestPrice(
    bytes32 identifier,
    uint256 time,
    bytes memory ancillaryData
  ) public virtual;

  function hasPrice(
    bytes32 identifier,
    uint256 time,
    bytes memory ancillaryData
  ) public view virtual returns (bool);

  function getPrice(
    bytes32 identifier,
    uint256 time,
    bytes memory ancillaryData
  ) public view virtual returns (int256);
}
