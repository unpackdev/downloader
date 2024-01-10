// SPDX-License-Identifier: GPL-3.0-only

pragma solidity 0.8.9;

import "./Ownable.sol";
import "./ERC20.sol";
import "./ERC20Burnable.sol";

/**
 * @title A mintable {ERC20} token.
 */
contract InputTokenDummy is ERC20Burnable, Ownable {
    uint8 private _decimals;

    /**
     * @dev Constructor that gives msg.sender an initial supply of tokens.
     */
    constructor(
        string memory name_,
        string memory symbol_,
        uint8 decimals_,
        uint256 initialSupply_
    ) ERC20(name_, symbol_) {
        _decimals = decimals_;
        _mint(msg.sender, initialSupply_);
    }

    /**
     * @dev Creates `amount` new tokens for `to`.
     */
    function mint(address to, uint256 amount) public {
        _mint(to, amount);
    }

    function decimals() public view override returns (uint8) {
        return _decimals;
    }
}
