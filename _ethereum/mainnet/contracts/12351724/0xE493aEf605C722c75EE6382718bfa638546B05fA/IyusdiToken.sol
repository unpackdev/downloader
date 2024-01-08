// SPDX-License-Identifier: Apache-2.0
pragma solidity >=0.8.0;
import "./ERC20.sol";

contract IyusdiToken is ERC20 {
  uint256 constant MINT_TOKENS = 100_000_000 ether;

  constructor (string memory name, string memory symbol, address protocol) ERC20(name, symbol) {
    _mint(protocol, MINT_TOKENS);
  }

}
