// contracts/ExampleToken.sol
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;
import "./ERC20Burnable.sol";
import "./Ownable.sol";

contract TBZ is ERC20Burnable, Ownable {
  constructor () ERC20("Tabzcoin", "TBZ") {
    _mint(
      msg.sender,
      2000000000 * (10**uint256(decimals()))
    );
  }
}