//SPDX-License-Identifier: MIT

pragma solidity 0.6.12;

import "./SafeMath.sol";
import "./IERC20.sol";
import "./SafeERC20.sol";
import "./ReentrancyGuard.sol";

contract Staker is ReentrancyGuard {
    using SafeMath for uint256;
    using SafeERC20 for IERC20;

    uint256 public constant BASIS_POINTS_DIVISOR = 10000;

    uint256 public rewardsDistributed;
    uint256 public lastUpdateTime;

    uint256 public totalRewards;
    uint256 public totalSupply;
    uint256 public totalShares;

    uint256 public endDate;
    uint256 public rewardsDuration;

    address public stakingToken;

    mapping (address => uint256) public balances;
    mapping (address => uint256) public shares;
    mapping (address => uint256) public claimed;

    constructor(address _stakingToken, uint256 _totalRewards, uint256 _endDate) public {
        require(endDate > block.timestamp, "Staker: endDate has passed");
        stakingToken = _stakingToken;
        totalRewards = _totalRewards;
        endDate = _endDate;
        rewardsDuration = endDate.sub(block.timestamp);
    }

    function stake(uint256 _amount) public nonReentrant {
        require(_amount > 0, "Staker: amount cannot be zero");
        require(endDate > block.timestamp, "Staker: endDate has passed");

        shares[msg.sender] = shares[msg.sender].add(_amount);
        claimed[msg.sender] = claimed[msg.sender].add(_amount);
        totalShares = totalShares.add(_amount);

        _mint(msg.sender, _amount);
        IERC20(stakingToken).safeTransferFrom(msg.sender, address(this), _amount);
    }

    function unstake(uint256 _amount) public nonReentrant {
        require(_amount > 0, "Staker: amount cannot be zero");
        _burn(msg.sender, _amount);
        IERC20(stakingToken).safeTransfer(msg.sender, _amount);
    }

    function getRewards(address _account) public view returns (uint256) {


    }

    function currentRewards() public view returns (uint256) {
        if (block.timestamp >= endDate) {
            return totalRewards;
        }

        if (lastUpdateTime >= block.timestamp) {
            return rewardsDistributed;
        }

        uint256 rewardsRemaining = totalRewards.sub(rewardsDistributed);
        uint256 durationRemaining = endDate.sub(block.timestamp);
        uint256 interval = block.timestamp.sub(lastUpdateTime);
        uint256 intervalRewards = rewardsRemaining.mul(interval).div(durationRemaining);

        return rewardsDistributed.add(intervalRewards);
    }

    function _updateRewards() private {
        if (block.timestamp <= lastUpdateTime) {
            return;
        }
        rewardsDistributed = currentRewards();
    }

    function _mint(address account, uint256 _amount) private {
        require(account != address(0), "Staker: mint to the zero address");

        balances[account] = balances[account].add(_amount);
        totalSupply = totalSupply.add(_amount);
    }

    function _burn(address _account, uint256 _amount) private {
        require(_account != address(0), "Staker: burn from the zero address");

        balances[_account] = balances[_account].sub(_amount, "Staker: burn amount exceeds balance");
        totalSupply = totalSupply.sub(_amount);
    }
}
