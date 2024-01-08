pragma solidity ^0.8.4;
// SPDX-License-Identifier: GPL-3.0-or-later

import "./ERC20.sol";
import "./IERC20.sol";
import "./ERC20Burnable.sol";
import "./Pausable.sol";
import "./Ownable.sol";
import "./AccessControl.sol";

/**
 * Sandalwood rewarded as part of the Opening Ceremony quests
 */
contract SandalwoodToken is ERC20, ERC20Burnable {
    constructor() ERC20("Sandalwood", "Sandalwood") {
      _mint(_msgSender(), 1e12 * 1e18);
    }
}