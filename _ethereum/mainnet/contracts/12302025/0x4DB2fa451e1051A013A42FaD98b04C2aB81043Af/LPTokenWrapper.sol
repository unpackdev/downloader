// SPDX-License-Identifier: MIT
pragma solidity >=0.6.0;

import "./SafeMath.sol";
import "./SafeERC20.sol";
import "./IERC20.sol";

contract LPTokenWrapper {
    using SafeMath for uint256;
    using SafeERC20 for IERC20;

    address public lpt;

    uint256 public _totalSupply;
    mapping(address => uint256) public _balances;

    function totalSupply() public view returns (uint256) {
        return _totalSupply;
    }

    function balanceOf(address account) public view returns (uint256) {
        return _balances[account];
    }

    function stake(address staker, address from, uint256 amount) internal {
        _totalSupply = _totalSupply.add(amount);
        _balances[staker] = _balances[staker].add(amount);
        IERC20(lpt).safeTransferFrom(from, address(this), amount);
    }

    function withdraw(uint256 amount) public virtual {
        _totalSupply = _totalSupply.sub(amount);
        _balances[msg.sender] = _balances[msg.sender].sub(amount);
        IERC20(lpt).safeTransfer(msg.sender, amount);
    }
}
