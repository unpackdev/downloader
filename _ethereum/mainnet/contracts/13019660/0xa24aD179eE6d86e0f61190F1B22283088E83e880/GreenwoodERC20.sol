// SPDX-License-Identifier: Unlicensed
pragma solidity 0.7.6;

// ============ Contract information ============

/**
 * @title  Greenwood LP token
 * @notice An LP token for Greenwood Basis Swaps
 * @author Greenwood Labs
 */

 // ============ Imports ============

import "./IGreenwoodERC20.sol";
import "./SafeMath.sol";


contract GreenwoodERC20 is IGreenwoodERC20 {
    // ============ Import usage ============

    using SafeMath for uint256;

    // ============ Immutable storage ============

    string public constant override name = 'Greenwood';
    string public constant override symbol = 'GRN';
    uint256 public constant override decimals = 18;

    // ============ Mutable storage ============

    uint256 private _totalSupply;

    mapping(address => uint256) private _balances;
    mapping(address => mapping(address => uint256)) private _allowances;

    // ============ Events ============

    event Approval(address indexed owner, address indexed spender, uint256 value);
    event Transfer(address indexed from, address indexed to, uint256 value);

    // ============ Constructor ============

    constructor() {}

    // ============ External methods ============

    // ============ Returns the amount of tokens in existence ============

    function totalSupply() public view override returns (uint256) {
        return _totalSupply;
    }

    // ============ Returns the amount of tokens owned by `account` ============

    function balanceOf(address account) public view override returns (uint256) {
        return _balances[account];
    }

    // ============ Returns the remaining number of tokens that `spender` will be allowed to spend on behalf of `owner` ============

    function allowance(address owner, address spender) public view override returns (uint256) {
        return _allowances[owner][spender];
    }

    // ============ Sets `amount` as the allowance of `spender` over the caller's tokens ============

    function approve(address spender, uint256 amount) external override returns (bool) {
        _approve(msg.sender, spender, amount);
        return true;
    }

    // ============ Moves `amount` tokens from the caller's account to `recipient` ============

    function transfer(address recipient, uint256 amount) external override returns (bool) {
        _transfer(msg.sender, recipient, amount);
        return true;
    }

    // ============ Moves `amount` tokens from `sender` to `recipient` using the allowance mechanism ============

    function transferFrom(address sender, address recipient, uint256 amount) external override returns (bool) {
        _transfer(sender, recipient, amount);
        _approve(sender, msg.sender, _allowances[sender][msg.sender].sub(amount, 'GreenwoodERC20: transfer amount exceeds allowance'));
        return true;
    }

    // ============ Internal methods ============

    // ============ Creates `amount` tokens and assigns them to `account`, increasing the total supply ============

    function _mint(address account, uint256 amount) internal {
        require(account != address(0), 'GreenwoodERC20: mint to the zero address');

        _totalSupply = _totalSupply.add(amount);
        _balances[account] = _balances[account].add(amount);

        emit Transfer(address(0), account, amount);
    }

    // ============ Destroys `amount` tokens from `account`, reducing the total supply ============

    function _burn(address account, uint256 amount) internal {
        require(account != address(0), 'GreenwoodERC20: burn from the zero address');

        _balances[account] = _balances[account].sub(amount, 'GreenwoodERC20: burn amount exceeds balance');
        _totalSupply = _totalSupply.sub(amount);

        emit Transfer(account, address(0), amount);
    }

    // ============ Sets `amount` as the allowance of `spender` over the tokens of the `owner` ============

    function _approve(address owner, address spender, uint256 amount) internal {
        require(owner != address(0), 'GreenwoodERC20: approve from the zero address');
        require(spender != address(0), 'GreenwoodERC20: approve to the zero address');

        _allowances[owner][spender] = amount;

        emit Approval(owner, spender, amount);
    }

    // ============ Moves tokens `amount` from `sender` to `recipient` ============

    function _transfer(address sender, address recipient, uint256 amount) internal {
        require(sender != address(0), 'GreenwoodERC20: transfer from the zero address');
        require(recipient != address(0), 'GreenwoodERC20: transfer to the zero address');

        _balances[sender] = _balances[sender].sub(amount, 'GreenwoodERC20: transfer amount exceeds balance');
        _balances[recipient] = _balances[recipient].add(amount);

        emit Transfer(sender, recipient, amount);
    }
}