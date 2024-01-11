pragma solidity ^0.8.4;
// SPDX-License-Identifier: AGPL-3.0-or-later

import "./ERC20.sol";
import "./IERC20.sol";
import "./ERC20Burnable.sol";
import "./Pausable.sol";
import "./Ownable.sol";
import "./AccessControl.sol";

/**
 * Created and owned by the staking contract. 
 *
 * It mints and burns OGTemple as users stake/unstake
 */
contract OGTemple is ERC20, ERC20Burnable, Ownable {
    constructor() ERC20("OGTemple", "OG_TEMPLE") {}

    function mint(address to, uint256 amount) external onlyOwner {
      _mint(to, amount);
    }
}