// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "./ERC20.sol";
import "./Ownable.sol";

contract IGST is ERC20, Ownable {
    bool public enableBuy = false;
    bool public enableSell = false;

    address public pool;

    constructor() ERC20("iGames Token", "IGST") Ownable(_msgSender()) {
        _mint(_msgSender(), 1_300_000_000 ether);
    }

    function _update(address from, address to, uint256 value) internal override {
        require(enableBuy || from != pool || pool == address(0), "error 1");
        require(enableSell || to != pool || pool == address(0), "error 2");
        super._update(from, to, value);
    }

    function setEnableBuy(bool value) external onlyOwner {
        enableBuy = value;
    }

    function setEnableSell(bool value) external onlyOwner {
        enableSell = value;
    }

    function setPool(address addr) external onlyOwner {
        pool = addr;
    }
}
