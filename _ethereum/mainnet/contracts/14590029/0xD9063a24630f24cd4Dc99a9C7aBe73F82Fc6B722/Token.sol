// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./ERC20.sol";
import "./Ownable.sol";

contract Arenum is ERC20, Ownable {
    uint8 decimals_;

    constructor(
        string memory _name,
        string memory _symbol,
        uint8 _decimals,
        uint256 _totalSupply,
        address _owner
    ) ERC20(_name, _symbol) {
        decimals_ = _decimals;
        _mint(_owner, _totalSupply * (10**_decimals));
        transferOwnership(_owner);
    }

    function decimals() public view override returns (uint8) {
        return decimals_;
    }
}
