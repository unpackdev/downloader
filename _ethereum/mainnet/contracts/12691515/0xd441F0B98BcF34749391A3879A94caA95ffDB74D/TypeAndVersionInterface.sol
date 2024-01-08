// SPDX-License-Identifier: MIT
pragma solidity ^0.7.0;

interface TypeAndVersionInterface{
  function typeAndVersion()
    external
    pure
    returns (
      string memory
    );
}
