// SPDX-License-Identifier: MIT
pragma solidity >=0.5.0;


interface IERC20Metadata {
  function name() external view returns (string memory);
  function symbol() external view returns (string memory);
  function decimals() external view returns (uint8);
}


interface IERC20MetadataBytes32 {
  function name() external view returns (bytes32);
  function symbol() external view returns (bytes32);
}