// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./Ownable.sol";
import "./ERC20.sol";
import "./ILunchMoney.sol";

contract LunchMoney is ERC20, Ownable, ILunchMoney{
    uint256 private immutable _SUPPLY_CAP;

    constructor(
        uint256 _cap
    ) ERC20("LunchMoney", "LUNCH") {

        _SUPPLY_CAP = _cap;
    }

    function mint(address account, uint256 amount) external override onlyOwner returns (bool status) {
        if (totalSupply() + amount <= _SUPPLY_CAP) {
            _mint(account, amount);
            return true;
        }
        return false;
    }

    function SUPPLY_CAP() external view override returns (uint256) {
        return _SUPPLY_CAP;
    }
}