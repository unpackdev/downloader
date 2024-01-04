pragma solidity ^0.6.0;

import "./SafeMath.sol";
import "./SafeERC20.sol";
import "./IERC20.sol";

contract LPTokenWrapper {
    using SafeMath for uint256;
    using SafeERC20 for IERC20;

    IERC20 public lpt;

    uint256 private _totalSupply;
    uint256 private _totalInternalSupply;
    mapping(address => uint256) private _balances;
    mapping(address => uint256) private _internalBalances;

    function totalInternalSupply() public view returns (uint256) {
        return _totalInternalSupply;
    }

    function totalSupply() public view returns (uint256) {
        return _totalSupply;
    }

    function internalBalanceOf(address account) public view returns (uint256) {
        return _internalBalances[account];
    }

    function balanceOf(address account) public view returns (uint256) {
        return _balances[account];
    }

    function stake(uint256 amount, uint256 userBoostPower) internal {
        _totalSupply = _totalSupply.add(amount);
        _totalInternalSupply = _totalInternalSupply.add(amount.mul(userBoostPower.add(1e18)).div(1e18));
        _balances[msg.sender] = _balances[msg.sender].add(amount);
        _internalBalances[msg.sender] = _internalBalances[msg.sender].add((amount.mul(userBoostPower.add(1e18)).div(1e18)));
        lpt.safeTransferFrom(msg.sender, address(this), amount);
    }

    function withdraw(uint256 amount, uint256 userBoostPower) internal {
        _totalSupply = _totalSupply.sub(amount);
        _totalInternalSupply = _totalInternalSupply.sub(amount.mul(userBoostPower.add(1e18)).div(1e18));
        _balances[msg.sender] = _balances[msg.sender].sub(amount);
        _internalBalances[msg.sender] = _internalBalances[msg.sender].sub((amount.mul(userBoostPower.add(1e18)).div(1e18)));
        lpt.safeTransfer(msg.sender, amount);
    }

    function _update(uint256 _userBoostPower) internal {
        uint256 oldInternalBalance = _internalBalances[msg.sender];
        uint256 newInternalBalance = _balances[msg.sender].mul(_userBoostPower.add(1e18)).div(1e18);
        _internalBalances[msg.sender] = newInternalBalance;
        _totalInternalSupply = _totalInternalSupply.sub(oldInternalBalance).add(newInternalBalance);
    }
}
