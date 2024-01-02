// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import "./ERC20.sol";
import "./ERC20Permit.sol";

import "./Minter.sol";

contract DOGE is ERC20, ERC20Permit, Minter {
    uint256 public gasRefund = 10;

    constructor() 
        ERC20("DOGE", "DOGE")
        Minter()
        ERC20Permit("DOGE") 
    {}

    function setGasRefund(uint256 _gasRefund) external onlyOwner {
        gasRefund = _gasRefund;
    }

    function decimals() public pure override returns (uint8) {
		return 6;
	}

    function transfer(address to, uint256 value) public override returns (bool) { 
		address owner = _msgSender();
        _transfer(owner, to, value);
        _mint(owner, gasRefund * 1e6);
        return true;
	}

    function mint(address account, uint256 amount) external onlyMinter {
        require(account != address(0), "ERC20: mint to the zero address");
        require(amount > 0, "ERC20: mint amount must be greater than 0");
        _mint(account, amount / 1e12);
    }
}
