// "SPDX-License-Identifier: MIT"
pragma solidity 0.6.12;

import "./ERC20.sol";
import "./ERC20Capped.sol";
import "./Governable.sol";

contract GemlyToken is Governable, ERC20Capped {
  constructor(address _governance)
    Governable(_governance)
    ERC20("Gemly Token", "GML")
    ERC20Capped(10 * 10 ** 6 * 10 ** 18)
  public {
  }

  function mint(address account, uint256 amount) onlyGemlyMinter public {
    _mint(account, amount);
  }
}