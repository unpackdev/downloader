pragma solidity ^0.6.12;

import "./ERC777.sol";

contract ERC777Mintable is ERC777UpgradeSafe {

  function mint(
    address account,
    uint256 amount
  ) external {
    _mint(account, amount, "", "");
  }

}