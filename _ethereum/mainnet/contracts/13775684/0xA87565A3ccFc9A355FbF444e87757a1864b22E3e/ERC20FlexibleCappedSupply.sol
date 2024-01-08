// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

import "./ERC20.sol";
import "./ERC20Burnable.sol";
import "./Pausable.sol";
import "./Ownable.sol";

/**
 * @title ERC20FlexibleCappedSupply
 * @dev Implementation of the Token
 */
contract ERC20FlexibleCappedSupply is ERC20, ERC20Burnable, Pausable, Ownable {
    uint256 private immutable _cap;

    /**
     * @param name Name of the token
     * @param symbol Symbol to be used as ticker
     * @param supplyCap Maximum number of tokens mintable
     * @param initialSupply Initial token supply
     */
    constructor(
        string memory name,
        string memory symbol,
        uint256 supplyCap,
        uint256 initialSupply
    ) ERC20(name, symbol) {
        require(supplyCap > 0, "ERC20FlexibleCappedSupply: cap is 0");
        _cap = supplyCap;

        _mint(_msgSender(), initialSupply);
    }

    /**
     * @dev Returns the cap on the token's total supply.
     */
    function cap() public view returns (uint256) {
        return _cap;
    }

    /**
     * @dev Pauses all token transfers.
     */
    function pause() public onlyOwner {
        _pause();
    }

    /**
     * @dev Unpauses all token transfers.
     */
    function unpause() public onlyOwner {
        _unpause();
    }

    /**
     * @dev Mints new tokens.
     * @param to The address that will receive the minted tokens
     * @param amount The amount of tokens to mint
     */
    function mint(address to, uint256 amount) public onlyOwner {
        require(
            ERC20.totalSupply() + amount <= cap(),
            "ERC20FlexibleCappedSupply: cap exceeded"
        );
        _mint(to, amount);
    }

    /**
     * @dev See {ERC20-_beforeTokenTransfer}.
     */
    function _beforeTokenTransfer(
        address from,
        address to,
        uint256 amount
    ) internal override whenNotPaused {
        super._beforeTokenTransfer(from, to, amount);
    }
}
