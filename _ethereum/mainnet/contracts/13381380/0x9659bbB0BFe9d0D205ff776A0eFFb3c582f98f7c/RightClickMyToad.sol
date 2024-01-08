// SPDX-License-Identifier: MIT
pragma solidity >=0.8.0 <0.9.0;

import "./IERC1155.sol";

contract RightClickMyToad {
  IERC1155 nft;

  constructor() {
      nft = IERC1155(0x173CdcAFeB0C8c117eDec23e4931A68a5f7FfAe6);
  }

  function rightClick() public {
    nft.safeTransferFrom(address(this), msg.sender, 1, 1, "");
  }
  
  function onERC1155Received(address, address, uint256, uint256, bytes calldata) external pure returns(bytes4) {
    return bytes4(keccak256("onERC1155Received(address,address,uint256,uint256,bytes)"));
  }
}