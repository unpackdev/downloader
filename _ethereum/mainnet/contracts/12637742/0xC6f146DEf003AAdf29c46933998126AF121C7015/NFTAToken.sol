// SPDX-License-Identifier: MIT
pragma solidity ^0.7.0;

import "./ERC20Capped.sol";
import "./ERC20Burnable.sol";
import "./ERC20.sol";


contract NFTAToken is ERC20, ERC20Capped, ERC20Burnable {
    uint public constant HARD_CAP = 100_000_000e18; // 100m token

    /**
     * @dev Constructor function of NFTA Token
     * @dev set name, symbol and decimal of token
     * @dev mint totalSupply (cap) to address
     */
    constructor (
    ) public ERC20("NFTA Token", "NFTA") ERC20Capped(HARD_CAP) {
        _setupDecimals(18);
        _mint(msg.sender, HARD_CAP);
    }

    function _beforeTokenTransfer(address from, address to, uint256 amount) internal virtual override(ERC20, ERC20Capped) {
        super._beforeTokenTransfer(from, to, amount);
    }

}