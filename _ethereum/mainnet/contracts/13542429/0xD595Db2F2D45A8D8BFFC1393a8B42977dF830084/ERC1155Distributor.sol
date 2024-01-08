// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "./IERC1155.sol";

contract ERC1155Distributor {
  function distributeTokens(IERC1155 _tokenAddress, address[] memory _to, uint256 _tokenId, uint256 _amount) external {
    require(_to.length <= 255);

    for (uint8 i = 0; i < _to.length; i++) {
      _tokenAddress.safeTransferFrom(msg.sender, _to[i], _tokenId, _amount, "0x");
    }
  }
}
