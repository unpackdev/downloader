// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.4;

interface IStake {
  function getStaked(
    address _addr,
    address _tokenAddr,
    uint256 tokenId
  ) external view returns (uint256);
}
