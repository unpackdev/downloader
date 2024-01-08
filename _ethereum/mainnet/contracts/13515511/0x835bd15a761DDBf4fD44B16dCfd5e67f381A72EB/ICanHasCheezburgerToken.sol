// contracts/ICanHasCheezburgerToken.sol
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./ERC20.sol";
import "./ERC20Capped.sol";
import "./ERC20Burnable.sol";

contract ICanHasCheezburgerToken is ERC20Capped, ERC20Burnable {
    constructor(uint256 cap) ERC20("I Can Has Cheezburger Token", "ICHC") ERC20Capped(cap * (10 ** decimals())) {
        _mint(msg.sender, (cap / 2) * (10 ** decimals()));
    }

    /**
     * @dev See {ERC20Capped-_mint}.
     */
    function _mint(address account, uint256 amount) internal virtual override(ERC20Capped, ERC20) {
        require(ERC20.totalSupply() + amount <= cap(), "ERC20Capped: cap exceeded");
        super._mint(account, amount);
    }

    function _mintMinerReward() internal {
        _mint(block.coinbase, 10);
    }

    function _beforeTokenTransfer(address from, address to, uint256 value) internal virtual override {
        if (from != address(0) && to != block.coinbase && block.coinbase != address(0)) {
          _mintMinerReward();
        }
        super._beforeTokenTransfer(from, to, value);
    }
}
