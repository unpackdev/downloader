// SPDX-License-Identifier: UNLICENSED

pragma solidity >=0.7.0;

interface ICallee {

  function wildCall(bytes calldata _data) external;
}