// SPDX-License-Identifier: GPL-3.0-only
pragma solidity ^0.8.18;

import "./ERC20Burnable.sol";
import "./Ownable.sol";

/// @title   PeggingToken Contract
/// @author  Sammy
/// @notice  ERC20 token contract of the pegging token, pool contract will mint and burn pegging token
contract InverseBondingCurveToken is ERC20Burnable, Ownable {
    constructor(string memory name_, string memory symbol_) ERC20(name_, symbol_) Ownable() {
    }

    function mint(address to, uint256 amount) public onlyOwner {
        _mint(to, amount);
    }

    function burn(uint256 amount) public override onlyOwner {
        super.burn(amount);
    }

    function burnFrom(address account, uint256 amount) public override onlyOwner {
        super.burnFrom(account, amount);
    }
}
