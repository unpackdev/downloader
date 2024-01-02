// SPDX-License-Identifier: MIT
pragma solidity 0.8.4;

import "./ERC20.sol";
import "./Ownable.sol";

contract FlokiRewardToken is ERC20, Ownable {
    uint8 private _decimals;

    constructor(
        string memory name,
        string memory symbol,
        uint8 totalDecimals,
        uint256 initialSupply,
        address treasury
    ) ERC20(name, symbol) {
        _decimals = totalDecimals;
        _mint(treasury, initialSupply * 10**totalDecimals);
    }

    function decimals() public view override returns (uint8) {
        return _decimals;
    }

    function mint(uint256 amount) external onlyOwner {
        _mint(_msgSender(), amount);
    }
}
