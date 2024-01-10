// SPDX-License-Identifier: AGPL-3.0
pragma solidity 0.8.3;

interface IMultiex {
  struct Call {
    address target;
    bytes data;
  }

  function multiexcall(Call[] calldata calls)
    external
    returns (bytes[] memory returnData);
}
