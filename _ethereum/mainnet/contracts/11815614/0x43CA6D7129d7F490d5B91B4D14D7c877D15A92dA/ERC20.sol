// SPDX-License-Identifier: MIT

pragma solidity >=0.6.0 <0.8.0;

import "./IERC20.sol";
import "./UnsignedSafeMath.sol";

/**
 * @title ERC20 Implementation
 */
contract ERC20 is IERC20 {

    using UnsignedSafeMath for uint256;

    string _name;
    string _symbol;
    uint8 _decimals = 18;
    uint256 _totalSupply;

    mapping (address => uint256) _balances;
    mapping (address => mapping (address => uint256)) _allowances;

    constructor (string memory name_, string memory symbol_) {
        _name = name_;
        _symbol = symbol_;
    }

    /**
     * @dev See {IERC20}.{name}
     */
    function name() public view override returns (string memory) {
        return _name;
    }

    /**
     * @dev See {IERC20}.{symbol}
     */
    function symbol() public view override returns (string memory) {
        return _symbol;
    }

    /**
     * @dev See {IERC20}.{decimals}
     */
    function decimals() public view override returns (uint8) {
        return _decimals;
    }

    /**
     * @dev See {IERC20}.{totalSupply}
     */
    function totalSupply() public view override returns (uint256) {
        return _totalSupply;
    }

    /**
     * @dev See {IERC20}.{balanceOf}
     */
    function balanceOf(address account) public view override returns (uint256) {
        return _balances[account];
    }

    /**
     * @dev See {IERC20}.{allowance}
     */
    function allowance(address owner, address spender) public view override returns (uint256) {
        return _allowances[owner][spender];
    }

    /**
     * @dev See {IERC20}.{approve}
     */
    function approve(address spender, uint256 amount) public override returns (bool) {
        require(spender != address(0), "ERC20: approve to 0 address");
        _approve(msg.sender, spender, amount);
        return true;
    }

    /**
     * @dev See {IERC20}.{transfer}
     */
    function transfer(address to, uint256 amount) public override returns (bool) {
        require(to != address(0), "ERC20: transfer to 0 address");
        require(_balances[msg.sender] >= amount, "ERC20: transfer amount exceeds balance");
        _transfer(msg.sender, to, amount);
        return true;
    }

    /**
     * @dev See {IERC20}.{transferFrom}
     */
    function transferFrom(address from, address to, uint256 amount) public override returns (bool) {
        require(to != address(0), "ERC20: transferFrom to 0 address");
        if (_allowances[from][msg.sender] != uint256(-1)) {
            require(_allowances[from][msg.sender] >= amount, "ERC20: transferFrom not approved");
            _allowances[from][msg.sender] = _allowances[from][msg.sender].sub(amount);
        }
        _transfer(from, to, amount);
        return true;
    }


    /**
     * @dev Sets `amount` as the allowance of `spender` over the `owner`.
     * Emits an {Approval} event.
     *
     * Parameters check should be carried out before calling this function.
     */
    function _approve(address owner, address spender, uint256 amount) internal {
        _allowances[owner][spender] = amount;
        emit Approval(owner, spender, amount);
    }

    /**
     * @dev Moves tokens `amount` from `from` to `to`.
     * Emits a {Transfer} event.
     *
     * Parameters check should be carried out before calling this function.
     */
    function _transfer(address from, address to, uint256 amount) internal {
        _balances[from] = _balances[from].sub(amount);
        _balances[to] = _balances[to].add(amount);
        emit Transfer(from, to, amount);
    }

}
