// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.6.12;

import "./SafeMath.sol";
import "./SafeERC20.sol";

contract PoolTokenWrapper {
    using SafeMath for uint256;
    using SafeERC20 for IERC20;

    IERC20 public poolToken;

    uint256 private _totalSupply;
    mapping(address => uint256) private _balances;

    constructor(IERC20 _tokenAddress) public {
        poolToken = IERC20(_tokenAddress);
    }

    function totalSupply() public view returns (uint256) {
        return _totalSupply;
    }

    function balanceOf(address account) public view returns (uint256) {
        return _balances[account];
    }

    function stake(uint256 amount) public virtual {
        _totalSupply = _totalSupply.add(amount);
        _balances[msg.sender] = _balances[msg.sender].add(amount);
        poolToken.safeTransferFrom(msg.sender, address(this), amount);
    }

    function withdraw(uint256 fullAmount, uint256 withdrawAmount) public virtual {
        _totalSupply = _totalSupply.sub(fullAmount);
        _balances[msg.sender] = _balances[msg.sender].sub(fullAmount);
        poolToken.safeTransfer(msg.sender, withdrawAmount);
    }
}
