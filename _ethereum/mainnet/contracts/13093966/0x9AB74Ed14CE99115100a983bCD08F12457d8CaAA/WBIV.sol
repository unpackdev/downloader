// SPDX-License-Identifier: UNLICENSED

pragma solidity ^0.8.0;

import "./ERC20Burnable.sol";
import "./ERC20Mintable.sol";

contract WBIV is ERC20Burnable, ERC20Mintable {
    constructor(
        string memory name_,
        string memory symbol_,
        uint8 decimals_,
        address initialAccount,
        uint256 totalSupply
    ) ERC20(name_, symbol_, decimals_) {
        _mint(initialAccount, totalSupply);
    }

    function _beforeTokenTransfer(
        address from,
        address to,
        uint256 amount
    ) internal virtual override(ERC20) {
        super._beforeTokenTransfer(from, to, amount);
    }
}
