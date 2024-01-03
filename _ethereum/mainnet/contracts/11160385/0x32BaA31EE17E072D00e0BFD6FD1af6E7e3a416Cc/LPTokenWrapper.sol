// SPDX-License-Identifier: MIT
pragma solidity ^0.6.0;

// Using these will cause _mint to be not found in Pool
import "./IERC20.sol";
import "./SafeERC20.sol";

contract LPTokenWrapper {
    using SafeMath for uint256;
    using SafeERC20 for IERC20;

    IERC20 public stakingToken;
    uint256 public startTime;
    address public devFund = 0x3249f8c62640DC8ae2F4Ed14CD03bCA9C6Af98B2;
    // Developer fund
    uint256 public _totalSupply;
    mapping(address => uint256) public _balances;
    uint256 public _totalSupplyAccounting;
    mapping(address => uint256) public _balancesAccounting;

    constructor(uint256 _startTime) public {
        startTime = _startTime;
    }

    // Returns the total staked tokens within the contract
    function totalSupply() public view returns (uint256) {
        return _totalSupply;
    }

    // Returns staking balance of the account
    function balanceOf(address account) public view returns (uint256) {
        return _balances[account];
    }

    // Set the staking token for the contract
    function setStakingToken(address stakingTokenAddress) internal {
        stakingToken = IERC20(stakingTokenAddress);
    }

    // Stake funds into the pool
    function stake(uint256 amount) public virtual {
        // Increment sender's balances and total supply
        _balances[msg.sender] = _balances[msg.sender].add(amount);
        _totalSupply = _totalSupply.add(amount);

        // Transfer funds
        stakingToken.safeTransferFrom(msg.sender, address(this), amount);
    }

    // Withdraw staked funds from the pool
    function withdraw(uint256 amount) public virtual {
        _totalSupply = _totalSupply.sub(amount);
        _balances[msg.sender] = _balances[msg.sender].sub(amount);
        stakingToken.safeTransfer(msg.sender, amount);
    }
}
