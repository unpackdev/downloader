// SPDX-License-Identifier: MIT

pragma solidity ^0.8.4;

import "./ERC165.sol";

import "./IRebelsRenderer.sol";

contract FixedURIRenderer is IRebelsRenderer, ERC165 {
  string public uri;

  constructor(string memory uri_) {
    uri = uri_;
  }

  function tokenURI(uint256) external view override returns (string memory) {
    return uri;
  }

  function beforeTokenTransfer(
    address from,
    address to,
    uint256 id
  ) external pure override {}

  function supportsInterface(bytes4 interfaceId) public view
      override(ERC165, IERC165) returns (bool) {
    return interfaceId == type(IRebelsRenderer).interfaceId ||
           super.supportsInterface(interfaceId);
  }
}
