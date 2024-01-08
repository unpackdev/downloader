// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./Ownable.sol";

interface ITokenStorage {

  function createFile(uint256 tokenId, uint256 name, uint256 size) external;
  function getFileNames(uint256 tokenId) external view returns (uint256[] memory);
  function getFileSizes(uint256 tokenId) external view returns (uint256[] memory);

  function writeFileBatch(uint256 tokenId, uint256 fileName, uint256 batchIndex, uint256[] calldata batchData) external;
  function finalizeToken(uint256 tokenId) external;
  function isFinalized(uint256 tokenId) external view returns (bool);
  function getFileBatchLength(uint256 tokenId, uint256 fileName) external view returns (uint256);
  function getFileBatchData(uint256 tokenId, uint256 fileName, uint256 batchIndex) external view returns (uint256[] memory);
}
