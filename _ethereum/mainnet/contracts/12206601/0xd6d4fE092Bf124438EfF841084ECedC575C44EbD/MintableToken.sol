// SPDX-License-Identifier: GPL-3.0-only
pragma solidity ^0.7.6;

import "./ERC20Upgradeable.sol";
import "./OwnableUpgradeable.sol";

interface IERC20Mintable is IERC20Upgradeable {

    function mint(address account, uint256 amount) external;

    function burn(address account, uint256 amount) external;
}

contract MintableToken is OwnableUpgradeable, ERC20Upgradeable {

    function initialize(string memory name, string memory symbol) public initializer {
        __Ownable_init();
        __ERC20_init(name, symbol);
    }

    function mint(address owner, uint256 amount) public onlyOwner {
        _mint(owner, amount);
    }

    function burn(address owner, uint256 amount) public onlyOwner {
        _burn(owner, amount);
    }
}