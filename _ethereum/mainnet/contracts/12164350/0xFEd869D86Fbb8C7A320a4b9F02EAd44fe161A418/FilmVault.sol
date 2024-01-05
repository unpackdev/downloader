// SPDX-License-Identifier: MIT
pragma solidity 0.8.1;

import "./ERC20PresetMinterPauser.sol";
import "./ERC20Capped.sol";

contract FilmVault is ERC20PresetMinterPauser, ERC20Capped {
    constructor() ERC20PresetMinterPauser("FilmVault", "FilmVault") ERC20Capped(1000000 * (10 ** uint256(decimals()))) {
    }

    function decimals() public view virtual override returns (uint8) {
        return 9;
    }

    function _mint(address account, uint256 amount) internal virtual override(ERC20, ERC20Capped) {
        super._mint(account, amount);
    }

    function _beforeTokenTransfer(address from, address to, uint256 amount) internal virtual override(ERC20, ERC20PresetMinterPauser) {
        super._beforeTokenTransfer(from, to, amount);
    }
}
