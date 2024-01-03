// SPDX-License-Identifier: Apache-2.0-with-puul-exception
pragma solidity >=0.6.12;

interface ICurveMinter {
  function mint(address gauge) external;
}
