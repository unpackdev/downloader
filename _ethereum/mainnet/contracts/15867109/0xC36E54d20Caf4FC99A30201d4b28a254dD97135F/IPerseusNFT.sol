// SPDX-License-Identifier: NO LICENSE

pragma solidity ^0.8.4;

interface IPerseusNFT {
  function mint(
    address _recipient,
    uint256 _silverAmount,
    uint256 _goldAmount,
    uint256 _platinumAmount,
    uint256 _blackAmount
  ) external;
}
