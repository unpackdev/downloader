// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.20;

import "./Ownable.sol";
import "./ERC20.sol";
import "./ERC20Burnable.sol";
import "./ERC20Capped.sol";
import "./ERC20Permit.sol";
import "./Pausable.sol";

contract SityERC20Token is
    ERC20Burnable,
    ERC20Capped,
    Pausable,
    ERC20Permit,
    Ownable
{
    constructor()
        ERC20("Sity Token", "SITY")
        ERC20Permit("Sity Token")
        ERC20Capped(10000000000 * 10 ** 18)
    {
        super._mint(msg.sender, 10000000000 * 10 ** 18);
    }

    function pause() public onlyOwner {
        _pause();
    }

    function unpause() public onlyOwner {
        _unpause();
    }

    /**
     * @dev See {ERC20-_beforeTokenTransfer}.
     *
     * Requirements:
     *
     * - the contract must not be paused.
     */
    function _beforeTokenTransfer(
        address from,
        address to,
        uint256 amount
    ) internal virtual override {
        super._beforeTokenTransfer(from, to, amount);

        require(!paused(), "ERC20Pausable: token transfer while paused");
    }

    function burnFrom(address from, uint256 amount) public override onlyOwner {
        ERC20Burnable.burnFrom(from, amount);
    }

    function burn(uint256 amount) public override onlyOwner {
        ERC20Burnable.burn(amount);
    }

    function _mint(
        address account,
        uint256 amount
    ) internal virtual override(ERC20, ERC20Capped) {
        super._mint(account, amount);
    }
}
