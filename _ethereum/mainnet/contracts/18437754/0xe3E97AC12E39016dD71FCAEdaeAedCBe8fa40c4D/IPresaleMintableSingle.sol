// SPDX-License-Identifier: GPL-3.0-or-later

pragma solidity ^0.8.17;

interface IPresaleMintableSingle {
  function presaleMint(address _receiver, uint256 _amount) external payable;
}