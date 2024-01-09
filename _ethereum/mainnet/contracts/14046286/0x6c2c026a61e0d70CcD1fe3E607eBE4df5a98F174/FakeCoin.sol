// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "./ERC20.sol";

contract FakeCoin is ERC20 {
  address private _minter;

  constructor(address minter_) ERC20("Fake Coin", "FAKE") {
    _minter = minter_;
  }

  modifier onlyMinter() {
    require(_minter == _msgSender(), "Caller is not the minter");
    _;
  }

  function mintTo(address _address, uint256 amount) external onlyMinter {
    _mint(_address, amount);
  }

  function burn(uint256 amount) external {
    _burn(_msgSender(), amount);
  }
}