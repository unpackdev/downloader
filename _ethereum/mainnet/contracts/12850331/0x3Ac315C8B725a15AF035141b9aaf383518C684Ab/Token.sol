// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity 0.8.0;

import "./SafeMath.sol";
import "./Ownable.sol";
import "./ERC20.sol";
import "./ERC20Burnable.sol";
 
contract Token is ERC20, Ownable, ERC20Burnable {
    constructor(string memory name, string memory symbol) ERC20(name, symbol) public {}

    function mint(address to, uint256 value) external onlyOwner {
        super._mint(to, value);
    }

    function burn(address to, uint256 value) external onlyOwner {
        super._burn(to, value);
    }

    function burnFrom(address to, uint256 value) public virtual override {
        super.burnFrom(to, value);
    }
}