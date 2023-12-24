// contracts/GLDToken.sol
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./ERC20.sol";
import "./Ownable.sol";

contract SIXToken is ERC20, Ownable {
    constructor(uint256 initialSupply) ERC20("SIX Token", "SIX") {
        _mint(msg.sender, initialSupply);
    }

    function burn(uint256 amount) public {
        _burn(_msgSender(), amount);
    }

    function mint(address account, uint256 amount) public onlyOwner {
        _mint(account, amount);
    }
}
