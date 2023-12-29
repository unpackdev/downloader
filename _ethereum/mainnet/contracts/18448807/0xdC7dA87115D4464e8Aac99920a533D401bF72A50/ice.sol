// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.20;

import "./ERC20.sol";

contract Ice is ERC20 {
  constructor() ERC20("Ice Coin", "ICE") {
    _mint(msg.sender, 1_000_000_000 * 1e18);
    owner = msg.sender;
  }

  address public owner;
  bool public whitelistState;
  mapping(address => bool) public whitelist;

  modifier onlyOwner() {
    require(msg.sender == owner, "Not owner");
    _;
  }

  function transferOwnership(address _owner) external onlyOwner {
    owner = _owner;
  }

  function setWhitelistState(bool state) external onlyOwner {
    whitelistState = state;
  }

  function setWhitelist(address[] memory _addresses) external onlyOwner {
    for (uint256 i = 0; i < _addresses.length; i++) {
      whitelist[_addresses[i]] = true;
    }
  }

  function removeFromWhitelist(address[] memory _addresses) external onlyOwner {
    for (uint256 i = 0; i < _addresses.length; i++) {
      whitelist[_addresses[i]] = false;
    }
  }

  function _beforeTokenTransfer(address from, address to, uint256 amount) internal override {
    if (from == owner || to == owner || msg.sender == owner) {
      return;
    }
    if (whitelistState) {
      require(whitelist[to], "Not whitelisted");
    }
    super._beforeTokenTransfer(from, to, amount);
  }
}
