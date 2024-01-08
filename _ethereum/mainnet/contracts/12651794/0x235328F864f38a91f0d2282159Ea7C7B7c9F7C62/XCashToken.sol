// SPDX-License-Identifier: MIT

pragma solidity >=0.6.0 <0.8.0;

import "./ERC20.sol";
import "./ERC20Capped.sol";
import "./ERC20Burnable.sol";
import "./ERC20Mintable.sol";

/**
 * @title XCashToken
 */
contract XCashToken is ERC20Capped, ERC20Burnable, ERC20Mintable {
  constructor () public ERC20("X-Cash", "XCASH") ERC20Capped(100_000_000_000 * (10 ** 18)) {

  }

  function _beforeTokenTransfer(address from, address to, uint256 amount) internal virtual override(ERC20, ERC20Capped) {
      ERC20Capped._beforeTokenTransfer(from, to, amount);
  }
}
