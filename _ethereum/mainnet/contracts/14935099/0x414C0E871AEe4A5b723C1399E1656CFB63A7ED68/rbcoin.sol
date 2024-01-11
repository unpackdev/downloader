// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "./ERC20Burnable.sol";
import "./Ownable.sol";

contract RumbleBirdsCoin is ERC20Burnable, Ownable {
    string private NAME;
    string private SYMBOL;
    uint8 private DECIMALS ;

    event Burned(address addr, uint256 amount);
    
    constructor(
        string memory _name,
        string memory _symbol,
        uint8 _decimals,
        uint256 _initialSupply
    ) ERC20(_name, _symbol) {
        NAME = _name;
        SYMBOL = _symbol;
        DECIMALS = _decimals;
        _mint(msg.sender, _initialSupply * 10 ** _decimals);
    }

    function mint(uint256 amount) public onlyOwner {
        _mint(msg.sender, amount);
    }

    function burn(uint256 amount) public override onlyOwner {
        super.burn(amount);
        emit Burned(msg.sender, amount);
    }

    function decimals() public view virtual override returns (uint8) {
        return DECIMALS;
    }
}