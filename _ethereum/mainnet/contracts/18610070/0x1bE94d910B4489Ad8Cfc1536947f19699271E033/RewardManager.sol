// SPDX-License-Identifier: MIT

pragma solidity ^0.8.19;

import "./Initializable.sol";
import "./OwnableUpgradeable.sol";
import "./IERC20.sol";

import "./LybraInterfaces.sol";
import "./IMatchPool.sol";

interface IERC20Mintable {
	function mint(address _to, uint256 _amount) external;
}

error UnpaidInterest(uint256 unpaidAmount);
error RewardNotOpen();

contract RewardManager is Initializable, OwnableUpgradeable {
	IMatchPool public matchPool;

	// reward pool => amount
	// 1. dlp reward pool (dlp + 20% mining incentive) 
	// 2. lsd reward pool (80% mining incentive)
	// 3. eUSD (rebase)
	mapping(address => uint256) public rewardPerTokenStored;
	// Last update timestamp in reward pool may not be now
	// Maintain own version of token paid for calculating most updated reward amount
	mapping(address => uint256) public rewardPerTokenPaid;
	// reward pool => account => amount
	mapping(address => mapping(address => uint256)) public userRewardsPerTokenPaid;
	mapping(address => mapping(address => uint256)) public userRewards;

	// Total amount of eUSD claimed from Match Pool
	// Get actual claim amount after/if eUSD has rebased within this contract
	uint256 totalEUSD;

	address public dlpRewardPool; // stake reward pool
	address public miningIncentive; // eUSD mining incentive
	address public eUSD; // eUSD rebase
	// Receive eUSD rebase and esLBR from mining incentive;
	address public treasury;

	// Mining reward share, out of 100
	uint128 treasuryShare;
	uint128 stakerShare;

	IERC20Mintable public mesLBR;

	event RewardShareChanged(uint128 newTreasuryShare, uint128 newStakerShare);
	event DLPRewardClaimed(address account, uint256 rewardAmount);
	event LSDRewardClaimed(address account, uint256 rewardAmount);
	event eUSDRewardClaimed(address account, uint256 rewardAmount);

	function initialize(address _matchPool) public initializer {
		__Ownable_init();

        matchPool = IMatchPool(_matchPool);
        setMiningRewardShares(0, 20);
    }

	/**
	 * @notice Rewards earned by Match Pool since last update, get most updated value by directly calculating
	 */
	function earnedSinceLastUpdate(address _rewardPool) public view returns (uint256, uint256) {
		IRewardPool rewardPool = IRewardPool(_rewardPool);
		address _matchPool = address(matchPool);
		uint256 share;
		if (_rewardPool == dlpRewardPool) share = rewardPool.balanceOf(_matchPool);
		else if (_rewardPool == miningIncentive) share = rewardPool.stakedOf(_matchPool);

		uint256 rpt = rewardPool.rewardPerToken();
		return (share * rewardPool.getBoost(_matchPool) * (rpt - rewardPerTokenPaid[_rewardPool]) / 1e38, rpt);
	}

	function rewardPerToken(address _rewardPool) public view returns (uint256) {
		(uint256 dlpEarned,) = earnedSinceLastUpdate(dlpRewardPool);
		(uint256 lsdEarned,) = earnedSinceLastUpdate(miningIncentive);
		uint256 rewardAmount;
		if (_rewardPool == dlpRewardPool) rewardAmount = dlpEarned + lsdEarned * stakerShare / 100;
		else if (_rewardPool == miningIncentive) rewardAmount = lsdEarned * (100 - stakerShare - treasuryShare) / 100;

		return _rewardPerToken(_rewardPool, rewardAmount);
	}

	function earned(address _account, address _rewardPool) public view returns (uint256) {
		(uint256 dlpEarned,) = earnedSinceLastUpdate(dlpRewardPool);
		(uint256 lsdEarned,) = earnedSinceLastUpdate(miningIncentive);
		uint256 rewardAmount;
		if (_rewardPool == dlpRewardPool) rewardAmount = dlpEarned + lsdEarned * stakerShare / 100;
		else if (_rewardPool == miningIncentive) rewardAmount = lsdEarned * (100 - stakerShare - treasuryShare) / 100;

		return _earned(_account, _rewardPool, rewardAmount);
	}

	function setDlpRewardPool(address _dlp) external onlyOwner {
		dlpRewardPool = _dlp;
	}

	function setMiningRewardPools(address _mining, address _eUSD) external onlyOwner {
		miningIncentive = _mining;
		eUSD = _eUSD;
	}

	function setMiningRewardShares(uint128 _treasuryShare, uint128 _stakerShare) public onlyOwner {
		treasuryShare = _treasuryShare;
		stakerShare = _stakerShare;

		emit RewardShareChanged(_treasuryShare, _stakerShare);
	}

	function setTreasury(address _treasury) external onlyOwner {
		treasury = _treasury;
	}

	function setMesLBR(address _mesLBR) external onlyOwner {
		mesLBR = IERC20Mintable(_mesLBR);
	}
	
	// Update rewards for dlp stakers, includes esLBR from dlp and eUSD
	function dlpUpdateReward(address _account) public {
		address _dlpRewardPool = dlpRewardPool;
		address _miningIncentive = miningIncentive;

		// esLBR earned from Lybra ETH-LBR LP stake reward pool
		(uint256 dlpEarned, uint256 dlpRpt) = earnedSinceLastUpdate(_dlpRewardPool);
		rewardPerTokenPaid[_dlpRewardPool] = dlpRpt;

		uint256 toStaker;
		if (_miningIncentive != address(0)) {
			// esLBR earned from Lybra eUSD mining incentive
			(uint256 lsdEarned, uint256 lsdRpt) = earnedSinceLastUpdate(_miningIncentive);
			rewardPerTokenPaid[_miningIncentive] = lsdRpt;

			uint256 toTreasury = lsdEarned * treasuryShare / 100;
			if (toTreasury > 0) userRewards[_miningIncentive][treasury] += toTreasury;
			// esLBR reward from mining incentive given to dlp stakers
			toStaker = lsdEarned * stakerShare / 100;
			// esLBR reward from mining incentive given to stETH suppliers
			uint256 toSupplier = lsdEarned - toTreasury - toStaker;

			rewardPerTokenStored[_miningIncentive] = _rewardPerToken(_miningIncentive, toSupplier);
		}

		rewardPerTokenStored[_dlpRewardPool] = _rewardPerToken(_dlpRewardPool, dlpEarned + toStaker);

		if (_account == address(0)) return;

		userRewards[_dlpRewardPool][_account] = _earned(_account, _dlpRewardPool, 0);
		userRewardsPerTokenPaid[_dlpRewardPool][_account] = rewardPerTokenStored[_dlpRewardPool];
	}

	function lsdUpdateReward(address _account) public {
		address _dlpRewardPool = dlpRewardPool;
		address _miningIncentive = miningIncentive;

		// esLBR earned from Lybra eUSD mining incentive
		(uint256 lsdEarned, uint256 rpt) = earnedSinceLastUpdate(_miningIncentive);
		rewardPerTokenPaid[_miningIncentive] = rpt;

		uint256 toTreasury = lsdEarned * treasuryShare / 100;
		if (toTreasury > 0) userRewards[_miningIncentive][treasury] += toTreasury;
		// esLBR reward from mining incentive given to dlp stakers
		uint256 toStaker = lsdEarned * stakerShare / 100;
		// esLBR reward from mining incentive given to stETH suppliers
		uint256 toSupplier = lsdEarned - toTreasury - toStaker;

		rewardPerTokenStored[_dlpRewardPool] = _rewardPerToken(_dlpRewardPool, toStaker);
		rewardPerTokenStored[_miningIncentive] = _rewardPerToken(_miningIncentive, toSupplier);

		address _eUSD = eUSD;
		uint256 eusdEarned = matchPool.claimRebase();
		if (eusdEarned > 0) {
			totalEUSD += eusdEarned;
			rewardPerTokenStored[_eUSD] = _rewardPerToken(_eUSD, eusdEarned);
		}

		if (_account == address(0)) return;

		userRewards[_miningIncentive][_account] = _earned(_account, _miningIncentive, 0);
		userRewardsPerTokenPaid[_miningIncentive][_account] = rewardPerTokenStored[_miningIncentive];

		if (eusdEarned > 0) {
			(uint256 borrowedAmount,,,) = matchPool.borrowed(address(matchPool.getMintPool()), _account);
			if (borrowedAmount == 0) userRewards[_eUSD][_account] = _earned(_account, _eUSD, 0);
			// Users who borrowed eUSD will not share rebase reward
			else userRewards[_eUSD][treasury] += (_earned(_account, _eUSD, 0) - userRewards[_eUSD][_account]);

			userRewardsPerTokenPaid[_eUSD][_account] = rewardPerTokenStored[_eUSD];
		}
	}

	function getReward(address _rewardPool) public {
		if (address(mesLBR) == address(0)) revert RewardNotOpen();

		// Cannot claim rewards if has not fully repaid eUSD interest
		// due to borrowing when above { globalBorrowRatioThreshold }
		(,, uint256 unpaidInterest,) = matchPool.borrowed(address(matchPool.getMintPool()), msg.sender);
		if (unpaidInterest > 0) revert UnpaidInterest(unpaidInterest);

		address _dlpRewardPool = dlpRewardPool;
		address _miningIncentive = miningIncentive;
		uint256 rewardAmount;

		if (_rewardPool == _dlpRewardPool) {
			dlpUpdateReward(msg.sender);

			rewardAmount = userRewards[_dlpRewardPool][msg.sender];
			if (rewardAmount > 0) {
				userRewards[_dlpRewardPool][msg.sender] = 0;
				mesLBR.mint(msg.sender, rewardAmount);
				emit DLPRewardClaimed(msg.sender, rewardAmount);
			}

			return;
		}

		if (_rewardPool == _miningIncentive) {
			lsdUpdateReward(msg.sender);

			rewardAmount = userRewards[_miningIncentive][msg.sender];
			if (rewardAmount > 0) {
				userRewards[_miningIncentive][msg.sender] = 0;
				mesLBR.mint(msg.sender, rewardAmount);
				emit LSDRewardClaimed(msg.sender, rewardAmount);
			}

			rewardAmount = userRewards[eUSD][msg.sender];
			if (rewardAmount > 0) {
				IERC20 _eUSD = IERC20(eUSD);
				// Get actual claim amount, including newly rebased eUSD in this contract
				uint256 actualAmount = _eUSD.balanceOf(address(this)) * userRewards[eUSD][msg.sender] / totalEUSD;
				userRewards[eUSD][msg.sender] = 0;
				totalEUSD -= rewardAmount;

				_eUSD.transfer(msg.sender, actualAmount);
				emit eUSDRewardClaimed(msg.sender, rewardAmount);
			}

			return;
		}
	}

	function getAllRewards() external {
		getReward(dlpRewardPool);
		getReward(miningIncentive);
	}

	function _rewardPerToken(address _rewardPool, uint256 _rewardAmount) private view returns (uint256) {
		uint256 rptStored = rewardPerTokenStored[_rewardPool];
		uint256 totalToken;
		if (_rewardPool == dlpRewardPool) totalToken = matchPool.totalStaked();
		// Support only stETH for version 1
		if (_rewardPool == miningIncentive || _rewardPool == eUSD) totalToken = matchPool.totalSupplied(address(matchPool.getMintPool()));

		return totalToken > 0 ? rptStored + _rewardAmount * 1e18 / totalToken : rptStored;
	}

	function _earned(address _account, address _rewardPool, uint256 _rewardAmount) private view returns (uint256) {
		uint256 share;
		if (_rewardPool == dlpRewardPool) share = matchPool.staked(_account);
		// Support only stETH for version 1
		if (_rewardPool == miningIncentive || _rewardPool == eUSD) share = matchPool.supplied(address(matchPool.getMintPool()), _account);

		return share * (_rewardPerToken(_rewardPool, _rewardAmount) - 
			userRewardsPerTokenPaid[_rewardPool][_account]) / 1e18 + userRewards[_rewardPool][_account];
	}
}
