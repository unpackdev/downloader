// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "./ERC1155.sol";
import "./Address.sol";
import "./Ownable.sol";


contract SaffronStakingBetaTester is ERC1155, Ownable {
  using Address for address;

  string public name = "Saffron Finance Staking V2 Beta Tester";
  uint256 constant TESTER_ID = 1;
  string constant TESTER_URI = "https://app.spice.finance/assets/metadata/stakingtester/1";

  constructor () ERC1155(TESTER_URI) {
  }

  function mintTester(address to) external onlyOwner {
    if (!to.isContract()) {
      _mint(to, TESTER_ID, 1, "");
    }
  }

  function mintTesters(address[] calldata to) external onlyOwner {
    for (uint256 i = 0; i < to.length; ++i) {
      address t = to[i];
      if (!t.isContract()) {
        _mint(t, TESTER_ID, 1, "");
      }
    }
  }

  function setUri(string memory uri_) external onlyOwner {
    _setURI(uri_);
  }
}
