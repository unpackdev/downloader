// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./IERC20.sol";
import "./IERC1155.sol";
import "./IERC1155Receiver.sol";
import "./Ownable.sol";

contract SakeBurner is IERC1155Receiver {  
  IERC20 immutable public sakeToken;
  
  IERC1155 immutable public nft;
  uint256 immutable tokenId;

  uint256 constant private SAKE_DECIMALS = 1e18;

  constructor(address _sakeToken, address _nft, uint256 _tokenId) {
    sakeToken = IERC20(_sakeToken);
    nft = IERC1155(_nft);
    tokenId = _tokenId;
  }

  function burnSake(uint8 amount) public {
    // Have to use ..01 becasue the token has a protection against sending to ..00
    sakeToken.transferFrom(msg.sender, address(1), amount * SAKE_DECIMALS);
    nft.safeTransferFrom(address(this), msg.sender, tokenId, amount, "");
  }

  function onERC1155Received(
      address,
      address,
      uint256,
      uint256,
      bytes calldata
  ) override external pure returns (bytes4) {
    return 0xf23a6e61;
  }

  function onERC1155BatchReceived(
      address,
      address,
      uint256[] calldata,
      uint256[] calldata,
      bytes calldata
  ) override external pure returns (bytes4) {
    return 0xbc197c81;
  }

  function supportsInterface(bytes4 interfaceId) override external pure returns (bool) {
    return interfaceId == 0x01ffc9a7 || interfaceId == 0x4e2312e0;
  }
}