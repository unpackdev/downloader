// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "./IERC721.sol";
import "./OKLGWithdrawable.sol";

contract OKLGNftUtils is OKLGWithdrawable {
  function depositNfts(
    address nftContractAddy,
    address to,
    uint256[] memory _tokenIds
  ) external {
    to = to == address(0) ? address(this) : to;
    IERC721 nftContract = IERC721(nftContractAddy);
    for (uint256 i = 0; i < _tokenIds.length; i++) {
      nftContract.transferFrom(msg.sender, to, _tokenIds[i]);
    }
  }

  function withdrawNfts(address nftContractAddy, uint256[] memory _tokenIds)
    external
    onlyOwner
  {
    IERC721 nftContract = IERC721(nftContractAddy);
    for (uint256 i = 0; i < _tokenIds.length; i++) {
      nftContract.transferFrom(address(this), owner(), _tokenIds[i]);
    }
  }
}
