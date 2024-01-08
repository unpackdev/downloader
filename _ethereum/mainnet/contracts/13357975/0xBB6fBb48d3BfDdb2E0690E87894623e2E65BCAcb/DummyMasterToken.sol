// SPDX-License-Identifier: MIT
pragma solidity 0.6.12;

import "./ERC20.sol";
import "./Ownable.sol";

contract DummyMasterToken is ERC20, Ownable {
  constructor() public ERC20('Dummy Master Token', 'DMT') {
    _mint(msg.sender, 1e18);
  }
}
