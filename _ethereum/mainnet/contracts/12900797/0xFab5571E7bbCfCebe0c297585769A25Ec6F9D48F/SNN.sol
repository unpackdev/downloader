// SPDX-License-Identifier: MIT
pragma solidity = 0.8.4;

import "./ERC20.sol";
import "./Ownable.sol";

contract SNN is ERC20, Ownable{

    constructor(string memory name_, string memory symbol_) ERC20(name_, symbol_){}

    function Mint(address account, uint256 amount) public onlyOwner {
        _mint(account, amount);
    }

    function Burn(address account, uint256 amount) public onlyOwner {
        _burn(account, amount);
    }
}