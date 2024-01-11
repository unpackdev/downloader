// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./IERC721.sol";

interface INoundles is IERC721 {
  function getNoundlesFromWallet(address _address)
    external
    view
    returns (uint256[] memory);

  function tokenURI(uint256 _tokenId) external view returns (string memory);

  function noundleBalance(address owner) external view returns (uint256);
}
