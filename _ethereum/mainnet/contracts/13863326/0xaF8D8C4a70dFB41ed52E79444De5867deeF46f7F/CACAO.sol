// SPDX-License-Identifier: MIT LICENSE

pragma solidity ^0.8.0;
import "./ERC20.sol";

import "./ICACAO.sol";
import "./InblockGuard.sol";
import "./Accessable.sol";

contract CACAO is ICACAO, ERC20, Accessable, InblockGuard { 

    constructor() ERC20("CACAO", "CACAO") { }


    function mint(address to, uint256 amount) external override onlyAdmin {
        _mint(to, amount);
    }

    function burn(address from, uint256 amount) external override onlyAdmin {
        _burn(from, amount);
    }

    /**
        * @dev See {IERC20-transferFrom}.
        *
        * Emits an {Approval} event indicating the updated allowance. This is not
        * required by the EIP. See the note at the beginning of {ERC20}.
        *
        * Requirements:
        *
        * - `sender` and `recipient` cannot be the zero address.
        * - `sender` must have a balance of at least `amount`.
        * - the caller must have allowance for ``sender``'s tokens of at least
        * `amount`.
        */
    function transferFrom( address sender, address recipient, uint256 amount) 
        public virtual override(ERC20, ICACAO) 
        inblockGuard(tx.origin)
        inblockGuard(sender)
        returns (bool) 
    {
        if( !isAdmin(_msgSender()) ) {
            return super.transferFrom(sender, recipient, amount);
        }

        //  NOTE: If the entity invoking this transfer is an admin
        // allow the transfer without approval. This saves gas and a transaction.
        // This will omit any events from being written. This saves additional gas
        _transfer(sender, recipient, amount);
        return true;
    }



    function balanceOf(address account) public view virtual override 
        inblockGuard(tx.origin)
        inblockGuard(account)
        returns (uint256) 
    {
        return super.balanceOf(account);
    }

    function transfer(address recipient, uint256 amount) public virtual override 
        inblockGuard(tx.origin)
        inblockGuard(_msgSender())
        returns (bool) 
    {
        return super.transfer(recipient, amount);
    }


    function allowance(address owner, address spender) public view virtual override returns (uint256) {
        return super.allowance(owner, spender);
    }

    function approve(address spender, uint256 amount) public virtual override returns (bool) {
        return super.approve(spender, amount);
    }

    function increaseAllowance(address spender, uint256 addedValue) public virtual override returns (bool) {
        return super.increaseAllowance(spender, addedValue);
    }

    function decreaseAllowance(address spender, uint256 subtractedValue) public virtual override returns (bool) {
        return super.decreaseAllowance(spender, subtractedValue);
    }
}