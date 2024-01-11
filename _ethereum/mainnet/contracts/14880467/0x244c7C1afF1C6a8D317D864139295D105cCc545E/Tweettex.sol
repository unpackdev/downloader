// SPDX-License-Identifier: MIT LICENSE

pragma solidity ^0.8.9;

import "./ERC20Burnable.sol";

contract Tweettex is ERC20Burnable {
  uint256 public constant MAX_TOTAL_SUPPLY = 500_000_000 ether;

  address public operator;
  bool public openTrading = false;
  mapping(address => bool) public whitelistAddresses;

  bool public isDistributed;

  constructor() ERC20("Tweettex Token", "TWTT") {
      operator = msg.sender;
      includeToWhitelist(operator);
  }

  function OpenTrade() external {
      require(msg.sender == operator, "No operator.");
      require(!openTrading, "Trade already opened.");
      openTrading = true;
  }

  function includeToWhitelist(address _address) public returns (bool) {
      require(msg.sender == operator, "No operator.");
      require(!whitelistAddresses[_address], "address can't be included");
      whitelistAddresses[_address] = true;
      return true;
  }

  function excludeFromWhitlist(address _address) public returns (bool) {
      require(msg.sender == operator, "No operator.");
      require(whitelistAddresses[_address], "address can't be excluded");
      whitelistAddresses[_address] = false;
      return true;
  }

  function _transfer(address sender, address recipient, uint256 amount) internal virtual override {
      require(openTrading || whitelistAddresses[sender], "Trade not opened");
      super._transfer(sender, recipient, amount);
  }

  function distributeToken(address twttPool) external {
      require(msg.sender == operator, "No operator.");
      require(!isDistributed, "only can distribute once");
      require(twttPool != address(0), "!No zero address");

      isDistributed = true;

      _mint(twttPool, MAX_TOTAL_SUPPLY);
  }
}
