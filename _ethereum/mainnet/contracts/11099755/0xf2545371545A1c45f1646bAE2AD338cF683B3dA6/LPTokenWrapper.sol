// SPDX-License-Identifier: MIT

pragma solidity >=0.6.8;

import "./SafeMath.sol";
import "./SafeERC20.sol";

contract LPTokenWrapper {
  using SafeMath for uint256;
  using SafeERC20 for IERC20;

  IERC20 public lp;

  uint256 private _totalSupply;
  mapping(address => uint256) private _balances;

  constructor(address _lp) public {
    lp = IERC20(_lp);
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
    lp.safeTransferFrom(msg.sender, address(this), amount);
  }

  function withdraw(uint256 amount) public virtual {
    _totalSupply = _totalSupply.sub(amount);
    _balances[msg.sender] = _balances[msg.sender].sub(amount);
    lp.safeTransfer(msg.sender, amount);
  }
}