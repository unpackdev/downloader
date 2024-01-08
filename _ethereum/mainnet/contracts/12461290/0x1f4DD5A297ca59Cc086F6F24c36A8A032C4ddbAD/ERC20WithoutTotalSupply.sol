// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./Math.sol";
import "./SafeMath.sol";
import "./IERC20.sol";

abstract contract ERC20WithoutTotalSupply is IERC20 {
    using SafeMath for uint256;

    mapping(address => uint256) private _balances;
    mapping(address => mapping(address => uint256)) private _allowances;

    function balanceOf(address account) public view override returns (uint256) {
        return _balances[account];
    }

    function allowance(address owner, address spender) public view override returns (uint256) {
        return _allowances[owner][spender];
    }

    function transfer(address recipient, uint256 amount) public override returns (bool) {
        _transfer(msg.sender, recipient, amount);
        return true;
    }

    function approve(address spender, uint256 amount) public override returns (bool) {
        _approve(msg.sender, spender, amount);
        return true;
    }

    function transferFrom(address sender, address recipient, uint256 amount) public override returns (bool) {
        _transfer(sender, recipient, amount);
        uint256 allowed = _allowances[sender][msg.sender];
        if ((allowed >> 255) == 0) {
            _approve(sender, msg.sender, allowed.sub(amount, "ERC20: transfer amount exceeds allowance"));
        }
        return true;
    }

    function _transfer(address sender, address recipient, uint256 amount) internal {
        _balances[sender] = _balances[sender].sub(amount, "ERC20: transfer amount exceeds balance");
        _balances[recipient] = _balances[recipient].add(amount);
        emit Transfer(sender, recipient, amount);
    }

    function _approve(address owner, address spender, uint256 amount) internal {
        _allowances[owner][spender] = amount;
        emit Approval(owner, spender, amount);
    }

    function _mint(address account, uint256 amount) internal {
        _balances[account] = _balances[account].add(amount);
        emit Transfer(address(0), account, amount);
    }

    function _burn(address account, uint256 amount) internal {
        _balances[account] = _balances[account].sub(amount, "ERC20: burn amount exceeds balance");
        emit Transfer(account, address(0), amount);
    }

    function _burnFrom(address account, uint256 amount) internal {
        _burn(account, amount);
        uint256 allowed = _allowances[account][msg.sender];
        if ((allowed >> 255) == 0) {
            _approve(account, msg.sender, allowed.sub(amount, "ERC20: burn amount exceeds allowance"));
        }
    }
}