// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./IERC721.sol";

contract BatchTransfer {
  function transferTokens(
    address tokenAddress,
    address to,
    uint256[] calldata tokenIds
  ) external {
    IERC721 tokenContract = IERC721(tokenAddress);

    uint256 numTokens = tokenIds.length;
    for (uint256 i; i < numTokens; ++i) {
      address owner = tokenContract.ownerOf(tokenIds[i]);
      tokenContract.transferFrom(owner, to, tokenIds[i]);
    }
  }

  function safeTransferTokens(
    address tokenAddress,
    address to,
    uint256[] calldata tokenIds
  ) external {
    IERC721 tokenContract = IERC721(tokenAddress);

    uint256 numTokens = tokenIds.length;
    for (uint256 i; i < numTokens; ++i) {
      address owner = tokenContract.ownerOf(tokenIds[i]);
      tokenContract.safeTransferFrom(owner, to, tokenIds[i]);
    }
  }

  function safeTransferTokens(
    address tokenAddress,
    address to,
    uint256[] calldata tokenIds,
    bytes calldata data
  ) external {
    IERC721 tokenContract = IERC721(tokenAddress);

    uint256 numTokens = tokenIds.length;
    for (uint256 i; i < numTokens; ++i) {
      address owner = tokenContract.ownerOf(tokenIds[i]);
      tokenContract.safeTransferFrom(owner, to, tokenIds[i], data);
    }
  }
}
