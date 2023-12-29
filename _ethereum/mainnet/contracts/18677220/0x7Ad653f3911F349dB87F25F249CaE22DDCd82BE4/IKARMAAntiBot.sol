// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity ^0.8.17;

interface IKARMAAntiBot {
  function setTokenOwner(address owner) external;
  function launch(address pair, address router) external;

  function onPreTransferCheck(
    address from,
    address to,
    uint256 amount
  ) external;
}