//SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface IPlotMetadata {
  function getMetadata(
    uint256 tokenId,
    bool staked,
    string[] calldata additionalAttributes
  ) external view returns (string memory);
}
