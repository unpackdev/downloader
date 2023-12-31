// SPDX-License-Identifier: MIT
pragma solidity 0.8.18;

import "./ERC20.sol";
import "./Ownable.sol";

contract EGG is ERC20, Ownable {
    uint8 private _decimals;

    constructor(
        string memory _name,
        string memory _symbol,
        uint8 __decimals,
        uint256 _totalSupply
    ) ERC20(_name, _symbol) {
        _decimals = __decimals;
        _mint(msg.sender, _totalSupply * (10 ** __decimals));
    }

    function decimals() public view override returns (uint8) {
        return _decimals;
    }
}
