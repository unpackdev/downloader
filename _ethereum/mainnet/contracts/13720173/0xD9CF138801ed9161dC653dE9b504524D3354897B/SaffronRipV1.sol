// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "./ERC1155.sol";
import "./Address.sol";
import "./Ownable.sol";


contract SaffronRipV1 is ERC1155, Ownable {
  using Address for address;

  string public name = "Saffron Finance Halloween 2021";
  uint256 constant RIP_ID = 1;
  string constant RIP_URI = "https://app.spice.finance/assets/metadata/ripv1/1";

  constructor () ERC1155(RIP_URI) {
  }

  function mintRIP(address to) external onlyOwner {
    if (!to.isContract()) {
      _mint(to, RIP_ID, 1, "");
    }
  }

  function mintRIPs(address[] calldata to) external onlyOwner {
    for (uint256 i = 0; i < to.length; ++i) {
      address t = to[i];
      if (!t.isContract()) {
        _mint(t, RIP_ID, 1, "");
      }
    }
  }

  function setUri(string memory uri_) external onlyOwner {
    _setURI(uri_);
  }
}
