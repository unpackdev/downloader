// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

import "./ERC20.sol";
import "./Ownable.sol";

contract VultorToken is Ownable, ERC20 {

    event TokenCreated(address indexed owner, address indexed token);

    uint8 _decimals;

    constructor (
        string memory name_,
        string memory symbol_,
        uint8 decimals_,
        uint256 totalSupply_
    ) ERC20(name_, symbol_) {
        _decimals = decimals_;

        _mint(owner(), totalSupply_);

        emit TokenCreated(owner(), address(this));
    }

    function decimals() public view virtual override returns (uint8) {
        return _decimals;
    }

    function burn(uint256 value) external {
        _burn(msg.sender, value);
    }
}
