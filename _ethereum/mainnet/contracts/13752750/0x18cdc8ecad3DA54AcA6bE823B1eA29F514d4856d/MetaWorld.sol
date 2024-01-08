// SPDX-License-Identifier: MIT
pragma solidity ^0.8.2;

import "./ERC20Capped.sol";
import "./ERC20Burnable.sol";
import "./Ownable.sol";

contract MetaWorld is ERC20Burnable, Ownable, ERC20Capped {

    uint256 public constant CAP_AMOUNT = 2000000000 * 10 ** 18;
    constructor() ERC20("MetaWorld", "METW") ERC20Capped(CAP_AMOUNT){}

    function mint(address to, uint256 amount) public onlyOwner {
        _mint(to, amount);
    }

    function _mint(address account, uint256 amount) internal virtual override(ERC20, ERC20Capped) {
        super._mint(account, amount);
    }
}
