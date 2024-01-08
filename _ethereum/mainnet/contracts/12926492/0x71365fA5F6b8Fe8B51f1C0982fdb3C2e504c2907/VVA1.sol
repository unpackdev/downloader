// SPDX-License-Identifier: GPL-3.0
pragma solidity 0.8.4;

import "./ERC20.sol";
import "./Ownable.sol";
import "./SafeMath.sol";


contract VVA1 is ERC20, Ownable {
    using SafeMath for uint256;
    
    uint256 public constant CAP = 1000 * 1e6 * 1e18; // 1 Billion

    constructor(uint256 initialSupply) ERC20("VELO virtual asset 1", "VVA1") {
        require(initialSupply <= CAP, "Cannot mint more than limit");
        _mint(msg.sender, initialSupply);
    }

    function mint(address account, uint256 amount) external onlyOwner {
        require(totalSupply().add(amount) <= CAP, "Cannot mint more than limit");
        _mint(account, amount);
    }

    function burn(uint256 amount) external {
        _burn(msg.sender, amount);
    }
} 