// SPDX-License-Identifier: MIT

import "./SafeMath.sol";
import "./SafeERC20.sol";
import "./IERC20Detailed.sol";

pragma solidity >=0.6.0 <0.8.0;

contract LPTokenWrapper {
    using SafeMath for uint256;
    using SafeERC20 for IERC20Detailed;

    IERC20Detailed public b;

    uint256 private _totalSupply;
    mapping(address => uint256) private _balances;

    constructor (address _b) internal {
        b = IERC20Detailed(_b);
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
        b.safeTransferFrom(msg.sender, address(this), amount);
    }

    function withdraw(uint256 amount) public virtual {
        _totalSupply = _totalSupply.sub(amount);
        _balances[msg.sender] = _balances[msg.sender].sub(amount);
        b.safeTransfer(msg.sender, amount);
    }
}
