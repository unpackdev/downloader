// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

import "./ERC20.sol";
import "./Ownable.sol";
import "./ERC20Burnable.sol";

contract TestERC20 is ERC20, Ownable, ERC20Burnable {
    constructor() ERC20("TestERC20", "MTK") {}

    function mint(uint256 amount) external {
        _mint(_msgSender(), amount);
    }

    function _beforeTokenTransfer(
        address from,
        address to,
        uint256 amount
    ) internal virtual override(ERC20) {
        super._beforeTokenTransfer(from, to, amount);
    }
}
