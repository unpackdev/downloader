// SPDX-License-Identifier: bsl-1.1

/*
  Copyright 2020 Artem Zakharov (az@unit.xyz).
*/
pragma solidity ^0.8.15;

import "./VaultParameters.sol";
import "./Initializable.sol";
import "./UUPSUpgradeable.sol";

/**
 * @title GCD token implementation
 * @dev ERC20 token
 **/
contract GCD is Initializable, UUPSUpgradeable, AuthInitializable {

    // name of the token
    string public constant name = "GCD Stablecoin";

    // symbol of the token
    string public constant symbol = "GCD";

    // version of the token
    string public constant version = "1";

    // number of decimals the token uses
    uint8 public constant decimals = 18;

    // total token supply
    uint public totalSupply;

    // balance information map
    mapping(address => uint) public balanceOf;

    // token allowance mapping
    mapping(address => mapping(address => uint)) public allowance;

    /**
     * @dev Trigger on any successful call to approve(address spender, uint amount)
    **/
    event Approval(address indexed owner, address indexed spender, uint value);

    /**
     * @dev Trigger when tokens are transferred, including zero value transfers
    **/
    event Transfer(address indexed from, address indexed to, uint value);

    /**
      * @param _parameters The address of system parameters contract
     **/
    function initialize(address _parameters) public initializer {
        initializeAuth(_parameters);
    }

    /**
      * Restricted upgrades function
     **/
    function _authorizeUpgrade(address) internal override onlyManager {}

    /**
      * @notice Only Vault can mint GCD
      * @dev Mints 'amount' of tokens to address 'to', and MUST fire the
      * Transfer event
      * @param to The address of the recipient
      * @param amount The amount of token to be minted
     **/
    function mint(address to, uint amount) external onlyVault {
        require(to != address(0), "GCD: ZERO_ADDRESS");

        balanceOf[to] = balanceOf[to] + amount;
        totalSupply = totalSupply + amount;

        emit Transfer(address(0), to, amount);
    }

    /**
      * @notice Only manager can burn tokens from manager's balance
      * @dev Burns 'amount' of tokens, and MUST fire the Transfer event
      * @param amount The amount of token to be burned
     **/
    function burn(uint amount) external onlyManager {
        _burn(msg.sender, amount);
    }

    /**
      * @notice Only Vault can burn tokens from any balance
      * @dev Burns 'amount' of tokens from 'from' address, and MUST fire the Transfer event
      * @param from The address of the balance owner
      * @param amount The amount of token to be burned
     **/
    function burn(address from, uint amount) external onlyVault {
        _burn(from, amount);
    }

    /**
      * @dev Transfers 'amount' of tokens to address 'to', and MUST fire the Transfer event. The
      * function SHOULD throw if the _from account balance does not have enough tokens to spend.
      * @param to The address of the recipient
      * @param amount The amount of token to be transferred
     **/
    function transfer(address to, uint amount) external returns (bool) {
        return transferFrom(msg.sender, to, amount);
    }

    /**
      * @dev Transfers 'amount' of tokens from address 'from' to address 'to', and MUST fire the
      * Transfer event
      * @param from The address of the sender
      * @param to The address of the recipient
      * @param amount The amount of token to be transferred
     **/
    function transferFrom(address from, address to, uint amount) public returns (bool) {
        require(to != address(0), "GCD: ZERO_ADDRESS");
        require(balanceOf[from] >= amount, "GCD: INSUFFICIENT_BALANCE");

        if (from != msg.sender) {
            require(allowance[from][msg.sender] >= amount, "GCD: INSUFFICIENT_ALLOWANCE");
            _approve(from, msg.sender, allowance[from][msg.sender] - amount);
        }
        balanceOf[from] = balanceOf[from] - amount;
        balanceOf[to] = balanceOf[to] + amount;

        emit Transfer(from, to, amount);
        return true;
    }

    /**
      * @dev Allows 'spender' to withdraw from your account multiple times, up to the 'amount' amount. If
      * this function is called again it overwrites the current allowance with 'amount'.
      * @param spender The address of the account able to transfer the tokens
      * @param amount The amount of tokens to be approved for transfer
     **/
    function approve(address spender, uint amount) external returns (bool) {
        _approve(msg.sender, spender, amount);
        return true;
    }

    /**
     * @dev Atomically increases the allowance granted to `spender` by the caller.
     *
     * This is an alternative to `approve` that can be used as a mitigation for
     * problems described in `IERC20.approve`.
     *
     * Emits an `Approval` event indicating the updated allowance.
     *
     * Requirements:
     *
     * - `spender` cannot be the zero address.
     */
    function increaseAllowance(address spender, uint addedValue) public virtual returns (bool) {
        _approve(msg.sender, spender, allowance[msg.sender][spender] + addedValue);
        return true;
    }

    /**
     * @dev Atomically decreases the allowance granted to `spender` by the caller.
     *
     * This is an alternative to `approve` that can be used as a mitigation for
     * problems described in `IERC20.approve`.
     *
     * Emits an `Approval` event indicating the updated allowance.
     *
     * Requirements:
     *
     * - `spender` cannot be the zero address.
     * - `spender` must have allowance for the caller of at least
     * `subtractedValue`.
     */
    function decreaseAllowance(address spender, uint subtractedValue) public virtual returns (bool) {
        _approve(msg.sender, spender, allowance[msg.sender][spender] - subtractedValue);
        return true;
    }

    function _approve(address owner, address spender, uint amount) internal virtual {
        require(owner != address(0), "GCD: approve from the zero address");
        require(spender != address(0), "GCD: approve to the zero address");

        allowance[owner][spender] = amount;
        emit Approval(owner, spender, amount);
    }

    function _burn(address from, uint amount) internal virtual {
        // uint256 accountBalance = balanceOf[from];
        // require(accountBalance >= amount, "ERC20: burn amount exceeds balance");
        balanceOf[from] -= amount;
        totalSupply -= amount;

        emit Transfer(from, address(0), amount);
    }
}
