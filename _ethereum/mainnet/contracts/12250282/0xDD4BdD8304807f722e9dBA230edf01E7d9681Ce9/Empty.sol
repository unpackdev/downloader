// SPDX-License-Identifier: agpl-3.0
pragma solidity 0.7.5;

contract Empty {
  event Empty();

  constructor() {
    emit Empty();
  }
}