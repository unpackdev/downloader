// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

import "IERC20.sol";
import "CorvusStaking.sol";

contract CorvusToken is IERC20, CorvusStaking {

    string private _name;
    string private _symbol;
    uint8 private _decimals;
    uint256 private _totalSupply;

    mapping(address => uint256) balances;
    mapping(address => mapping(address => uint256)) allowed;

    constructor(string memory name_, string memory symbol_) {
        _name = name_;
        _symbol = symbol_;
        balances[msg.sender] = totalSupply();
    }

    function name() public view returns (string memory) {
        return _name;
    }

    function symbol() public view returns (string memory) {
        return _symbol;
    }

    function decimals() external pure returns (uint8) {
        return 9;
    }

    function totalSupply() public pure returns (uint256) {
        return 4.333333333e9 * 1e9;
    }

    function balanceOf(address _address) external view returns (uint256) {
        return balances[_address];
    }

    function transfer(address _to, uint256 _value) external virtual override returns (bool) {
        _transfer(msg.sender, _to, _value);
        return true;
    }

    function transferFrom (address _from, address _to, uint256 _value) external virtual override returns (bool) {
        require(allowed[_from][msg.sender] >= _value, "Insufficient allowance");
        allowed[_from][msg.sender] = allowed[_from][msg.sender] - _value;
        _transfer(_from, _to, _value);
        return true;
    }

    function _transfer(address _from, address _to, uint256 _value) internal {
        require(balances[_from] >= _value, "Insufficient balance");
        balances[_from] = balances[_from] - _value;
        balances[_to] = balances[_to] + _value;
        emit Transfer(_from, _to, _value);
    }

    function approve(address _spender, uint256 _value) external returns (bool) {
        allowed[msg.sender][_spender] = _value;
        emit Approval(msg.sender, _spender, _value);
        return true;
    }

    function allowance(address _owner, address _spender) external view returns (uint256) {
        return allowed[_owner][_spender];
    }

    function _burn(address account, uint256 amount) internal {
        require(account != address(0), "Cannot burn from zero address");
        require(balances[account] >= amount, "Cannot burn more than the account owns");

        balances[account] = balances[account] - amount;
        _totalSupply = _totalSupply - amount;
        emit Transfer(account, address(0), amount);
    }

    function _mint(address account, uint256 amount) internal {
        require(account != address(0), "Cannot mint to zero address");

        _totalSupply = _totalSupply + (amount);
        balances[account] = balances[account] + amount;
        emit Transfer(address(0), account, amount);
    }

    function stake(uint256 _amount) public {
        require(_amount < balances[msg.sender], "Cannot stake more than you own");
        _stake(_amount);
        _burn(msg.sender, _amount);
    }

    function withdrawStake(uint256 amount, uint256 stake_index)  public {
        uint256 amount_to_mint = _withdrawStake(amount, stake_index);
        _mint(msg.sender, amount_to_mint);
    }
}
