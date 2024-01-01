// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.20;

import "./ERC20.sol";
import "./SafeERC20.sol";
import "./ERC20Burnable.sol";
import "./Ownable.sol";

contract Ice is ERC20, Ownable {
  using SafeERC20 for ERC20;

  constructor() ERC20("Fake Test Token", "FTT") {}

  event BeforeTransfer(uint256 counter, address from, address to, uint256 amount);

  uint256 public constant MAX_SUPPLY = 1_000_000_000 * 1e18;

  mapping(address => bool) public blacklists;
  bool public blacklistState;
  bool public whitelistState;
  mapping(address => bool) public whitelist;

  uint256 public transferCounter;

  function mint(address to, uint256 amount) public onlyOwner {
    _mint(to, amount);
  }

  function transfer(address recipient, uint256 amount) public override returns (bool) {
    _transfer(_msgSender(), recipient, amount);
    return true;
  }

  function setBlacklistsState(bool state) external onlyOwner {
    blacklistState = state;
  }

  function setWhitelistState(bool state) external onlyOwner {
    whitelistState = state;
  }

  function blacklist(address _address, bool _isBlacklisting) external onlyOwner {
    blacklists[_address] = _isBlacklisting;
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
    transferCounter++;
    emit BeforeTransfer(transferCounter, from, to, amount);
    if (blacklistState) {
      require(!blacklists[to] && !blacklists[from], "Blacklisted");
    }
    if (whitelistState) {
      require(whitelist[to], "Not whitelisted");
    }
    super._beforeTokenTransfer(from, to, amount);
  }

  function burn(uint256 value) external {
    _burn(msg.sender, value);
  }
}
