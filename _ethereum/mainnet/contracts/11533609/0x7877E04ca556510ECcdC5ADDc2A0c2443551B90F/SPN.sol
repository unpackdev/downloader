// contracts/GLDToken.sol
// SPDX-License-Identifier: MIT
import "./ERC20.sol";
import "./Ownable.sol";
pragma solidity ^0.6.0;

contract SPN is ERC20, Ownable {
  constructor() public ERC20("Sapiens", "SCB") {
    _mint(msg.sender, 1000000000 * 10 ** uint256(decimals()));
  }
}
