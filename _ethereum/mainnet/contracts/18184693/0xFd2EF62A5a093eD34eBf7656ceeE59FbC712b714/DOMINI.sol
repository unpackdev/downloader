// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

import "./ERC20.sol";
import "./ERC20Burnable.sol";
import "./Ownable.sol";
import "./console.sol";


contract DOMINI is ERC20, ERC20Burnable, Ownable {
    uint256 constant MAX_BP = 10000;
    uint256 constant VESTING_BP = 6500;
    uint256 constant OWNER_BP = 3500;

    uint256 constant BUY_BURN_TAX_BP = 200;
    uint256 constant BUY_OWNER_TAX_BP = 600;

    uint256 constant SELL_BURN_TAX_BP = 200;
    uint256 constant SELL_OWNER_TAX_BP = 600;

    uint256 constant private TOKEN_SUPPLY = 1_000_000_000 ether;

    address private taxOwner;

    mapping(address => bool) public whitelistedPools;

    event AddToWhitelist(address pool);
    event RemoveFromWhitelist(address pool);
    event SetTaxOwner(address owner);

    constructor(address vestingContract, address owner) ERC20("DOMINI", "DOMI") {
        require(vestingContract != address(0), "invalid vesting contract address");
        require(owner != address(0), "invalid owner address");
        taxOwner = owner;
        _mint(owner, TOKEN_SUPPLY * OWNER_BP / MAX_BP);
        _mint(vestingContract, TOKEN_SUPPLY * VESTING_BP / MAX_BP);
    }

    function addToWhitelist(address pool) external onlyOwner {
        whitelistedPools[pool] = true;
        emit AddToWhitelist(pool);
    }

    function removeFromWhitelist(address pool) external onlyOwner {
        whitelistedPools[pool] = false;
        emit RemoveFromWhitelist(pool);
    }

    function setTaxOwner(address owner) external onlyOwner {
        taxOwner = owner;
        emit SetTaxOwner(owner);
    }

    function transfer(address to, uint256 _amount) public virtual override returns (bool) {
        uint256 amount = _amount;

        if (whitelistedPools[msg.sender]) {
            _burn(msg.sender, _amount * BUY_BURN_TAX_BP / MAX_BP);
            super.transfer(taxOwner, _amount * BUY_OWNER_TAX_BP / MAX_BP);
            amount = _amount - (_amount * (BUY_BURN_TAX_BP + BUY_OWNER_TAX_BP) / MAX_BP);
        } else if (whitelistedPools[to]) {
            _burn(msg.sender, _amount * SELL_BURN_TAX_BP / MAX_BP);
            super.transfer(taxOwner, _amount * SELL_OWNER_TAX_BP / MAX_BP);
            amount = _amount - (_amount * (SELL_BURN_TAX_BP + SELL_OWNER_TAX_BP) / MAX_BP);
        }

        return super.transfer(to, amount);
    }

    function transferFrom(address from, address to, uint256 _amount) public virtual override returns (bool) {
        uint256 amount = _amount;

        if (whitelistedPools[from]) {
            _burn(from, _amount * BUY_BURN_TAX_BP / MAX_BP);
            super.transferFrom(from, taxOwner, _amount * BUY_OWNER_TAX_BP / MAX_BP);
            amount = _amount - (_amount * (BUY_BURN_TAX_BP + BUY_OWNER_TAX_BP) / MAX_BP);
        } else if (whitelistedPools[to]) {
            _burn(from, _amount * SELL_BURN_TAX_BP / MAX_BP);
            super.transferFrom(from, taxOwner, _amount * SELL_OWNER_TAX_BP / MAX_BP);
            amount = _amount - (_amount * (SELL_BURN_TAX_BP + SELL_OWNER_TAX_BP) / MAX_BP);
        }

        return super.transferFrom(from, to, amount);
    }
}