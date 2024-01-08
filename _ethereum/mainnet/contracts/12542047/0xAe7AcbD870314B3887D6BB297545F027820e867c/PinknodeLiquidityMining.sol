// SPDX-License-Identifier: MIT

pragma solidity ^0.6.0;

import "./Ownable.sol";
import "./SafeMath.sol";
import "./IERC20.sol";

contract PinknodeLiquidityMining is Ownable {

	using SafeMath for uint;

	// Events
	event Deposit(uint256 _timestmap, address indexed _address, uint256 indexed _pid, uint256 _amount);
	event Withdraw(uint256 _timestamp, address indexed _address, uint256 indexed _pid, uint256 _amount);
	event EmergencyWithdraw(uint256 _timestamp, address indexed _address, uint256 indexed _pid, uint256 _amount);

	// PNODE Token Contract & Funding Address
	IERC20 public constant PNODE = IERC20(0xAF691508BA57d416f895e32a1616dA1024e882D2);
	address public fundingAddress = 0xF7897E58A72dFf79Ab8538647A62fecEf8344ffe;

	struct LPInfo {
		// Address of LP token contract
		IERC20 lpToken;

		// LP reward per block
		uint256 rewardPerBlock;

		// Last reward block
		uint256 lastRewardBlock;

		// Accumulated reward per share (times 1e12 to minimize rounding errors)
		uint256 accRewardPerShare;
	}

	struct Staker {
		// Total Amount Staked
		uint256 amountStaked;

		// Reward Debt (pending reward = (staker.amountStaked * pool.accRewardPerShare) - staker.rewardDebt)
		uint256 rewardDebt;
	}

	// Liquidity Pools
	LPInfo[] public liquidityPools;

	// Info of each user that stakes LP tokens.
	// poolId => address => staker
    mapping (uint256 => mapping (address => Staker)) public stakers;

    // Starting block for mining
    uint256 public startBlock;

    // End block for mining (Will be ongoing if unset/0)
    uint256 public endBlock;

	/**
     * @dev Constructor
     */

	constructor(uint256 _startBlock) public {
		startBlock = _startBlock;
	}

	/**
     * @dev Contract Modifiers
     */

	function updateFundingAddress(address _address) public onlyOwner {
		fundingAddress = _address;
	}

	function updateStartBlock(uint256 _startBlock) public onlyOwner {
		require(startBlock > block.number, "Mining has started, unable to update startBlock");
		require(_startBlock > block.number, "startBlock has to be in the future");

        for (uint256 i = 0; i < liquidityPools.length; i++) {
            LPInfo storage pool = liquidityPools[i];
            pool.lastRewardBlock = _startBlock;
        }

		startBlock = _startBlock;
	}

	function updateEndBlock(uint256 _endBlock) public onlyOwner {
		require(endBlock > block.number || endBlock == 0, "Mining has ended, unable to update endBlock");
		require(_endBlock > block.number, "endBlock has to be in the future");

		endBlock = _endBlock;
	}

	/**
     * @dev Liquidity Pool functions
     */

    // Add liquidity pool
    function addLiquidityPool(IERC20 _lpToken, uint256 _rewardPerBlock) public onlyOwner {

    	uint256 lastRewardBlock = block.number > startBlock ? block.number : startBlock;

    	liquidityPools.push(LPInfo({
            lpToken: _lpToken,
            rewardPerBlock: _rewardPerBlock,
            lastRewardBlock: lastRewardBlock,
            accRewardPerShare: 0
        }));
    }

    // Update LP rewardPerBlock
    function updateRewardPerBlock(uint256 _pid, uint256 _rewardPerBlock) public onlyOwner {
        updatePoolRewards(_pid);

    	liquidityPools[_pid].rewardPerBlock = _rewardPerBlock;
    }

    // Update pool rewards variables
    function updatePoolRewards(uint256 _pid) public {
    	LPInfo storage pool = liquidityPools[_pid];

    	if (block.number <= pool.lastRewardBlock) {
            return;
        }

        uint256 lpSupply = pool.lpToken.balanceOf(address(this));
        if (lpSupply == 0) {
            pool.lastRewardBlock = block.number;
            return;
        }

        uint256 blockElapsed = 0;
        if (block.number < endBlock || endBlock == 0) {
            blockElapsed = (block.number).sub(pool.lastRewardBlock);
        } else if (endBlock >= pool.lastRewardBlock) {
            blockElapsed = endBlock.sub(pool.lastRewardBlock);
        }

        uint256 totalReward = blockElapsed.mul(pool.rewardPerBlock);
        pool.accRewardPerShare = pool.accRewardPerShare.add(totalReward.mul(1e12).div(lpSupply));
        pool.lastRewardBlock = block.number;
    }

	/**
     * @dev Stake functions
     */

	// Deposit LP tokens into the liquidity pool
	function deposit(uint256 _pid, uint256 _amount) public {
        require(block.number < endBlock || endBlock == 0);

		LPInfo storage pool = liquidityPools[_pid];
        Staker storage user = stakers[_pid][msg.sender];

        updatePoolRewards(_pid);

        // Issue accrued rewards to user
        if (user.amountStaked > 0) {
            uint256 pending = user.amountStaked.mul(pool.accRewardPerShare).div(1e12).sub(user.rewardDebt);
            if(pending > 0) {
            	_issueRewards(msg.sender, pending);
            }
        }

        // Process deposit
        if(_amount > 0) {
            require(pool.lpToken.transferFrom(msg.sender, address(this), _amount));
            user.amountStaked = user.amountStaked.add(_amount);
        }

        // Update user reward debt
        user.rewardDebt = user.amountStaked.mul(pool.accRewardPerShare).div(1e12);

        emit Deposit(block.timestamp, msg.sender, _pid, _amount);
	}

	// Withdraw LP tokens from liquidity pool
	function withdraw(uint256 _pid, uint256 _amount) public {
		LPInfo storage pool = liquidityPools[_pid];
        Staker storage user = stakers[_pid][msg.sender];

        require(user.amountStaked >= _amount, "Amount to withdraw more than amount staked");

        updatePoolRewards(_pid);

        // Issue accrued rewards to user
        if (user.amountStaked > 0) {
            uint256 pending = user.amountStaked.mul(pool.accRewardPerShare).div(1e12).sub(user.rewardDebt);
            if(pending > 0) {
            	_issueRewards(msg.sender, pending);
            }
        }

        // Process withdraw
        if(_amount > 0) {
            user.amountStaked = user.amountStaked.sub(_amount);
            require(pool.lpToken.transfer(msg.sender, _amount));
        }

        // Update user reward debt
        user.rewardDebt = user.amountStaked.mul(pool.accRewardPerShare).div(1e12);

        emit Withdraw(block.timestamp, msg.sender, _pid, _amount);
	}

	// Withdraw without caring about rewards. EMERGENCY ONLY.
    function emergencyWithdraw(uint256 _pid) public {
        LPInfo storage pool = liquidityPools[_pid];
        Staker storage user = stakers[_pid][msg.sender];

        uint256 amount = user.amountStaked;
        user.amountStaked = 0;
        user.rewardDebt = 0;

        require(pool.lpToken.transfer(msg.sender, amount));

        emit EmergencyWithdraw(block.timestamp, msg.sender, _pid, amount);
    }

    // Function to issue rewards from funding address to user
	function _issueRewards(address _to, uint256 _amount) internal {
		// For transparency, rewards are transfered from funding address to contract then to user

    	// Transfer rewards from funding address to contract
        require(PNODE.transferFrom(fundingAddress, address(this), _amount));

        // Transfer rewards from contract to user
        require(PNODE.transfer(_to, _amount));
	}

	// View function to see pending rewards on frontend.
    function pendingRewards(uint256 _pid, address _user) external view returns (uint256) {
        LPInfo storage pool = liquidityPools[_pid];
        Staker storage user = stakers[_pid][_user];

        uint256 accRewardPerShare = pool.accRewardPerShare;
        uint256 lpSupply = pool.lpToken.balanceOf(address(this));

        if (block.number > pool.lastRewardBlock && lpSupply != 0) {

            uint256 blockElapsed = 0;
            if (block.number < endBlock || endBlock == 0) {
                blockElapsed = (block.number).sub(pool.lastRewardBlock);
            } else if (endBlock >= pool.lastRewardBlock) {
                blockElapsed = endBlock.sub(pool.lastRewardBlock);
            }

            uint256 totalReward = blockElapsed.mul(pool.rewardPerBlock);
            accRewardPerShare = accRewardPerShare.add(totalReward.mul(1e12).div(lpSupply));
        }

        return user.amountStaked.mul(accRewardPerShare).div(1e12).sub(user.rewardDebt);
    }
}