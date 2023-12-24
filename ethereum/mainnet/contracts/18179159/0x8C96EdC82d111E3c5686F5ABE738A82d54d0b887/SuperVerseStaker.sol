// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity ^0.8.19;

import "./ReentrancyGuard.sol";
import "./SafeERC20.sol";

import "./IFee1155.sol";
import "./ISuperVerseStaker.sol";
import "./StakerConfig.sol";
import "./TypesAndConstants.sol";

/**
	@custom:benediction DEVS BENEDICAT ET PROTEGAT CONTRACTVS MEAM
	@title SuperVerseDAO staking contract.
	@author throw; <@0xthrpw>
	@author Tim Clancy <tim-clancy.eth>
	@author Rostislav Khlebnikov <@catpic5buck>

	This contract allows callers to stake SUPER tokens and items from the 
	EllioTrades and Superfarm NFT Collections and earn rewards in ETH.  It uses 
	a point based system and has a mechanism for 'rebasing' the reward emission 
	rate to distribute the contract's reward balance over a specified reward 
	period.

	@custom:date May 15th, 2023.
*/
contract SuperVerseStaker is 
	ISuperVerseStaker, StakerConfig, ReentrancyGuard
{
	using SafeERC20 for IERC20;

	/** 
		This struct defines a user's staked position
	*/
	struct Staker {
		uint256 stakerPower;
		uint256 missedReward;
		uint256 claimedReward;
		uint256 stakedTokens;
		ItemsById ETs;
		ItemsById SFs;
	}

	/// user address > position
	mapping ( address => Staker ) internal _stakers;

	/// rewards distributed over reward period.
	uint256 public reward;

  /// rewards for previous reward windows.
	uint256 public allProduced;
	
  /// total produced reward.
	uint256 public producedReward;
	
  /// reward round beginning timestamp.
	uint256 public producedTimestamp;
	
  /// rewards per power point.
	uint256 public rpp;
	
  /// total power points.
	uint256 public totalPower;

	/**
		Construct a new instance of a SuperVerse staking contract with the 
		following parameters.

		@param _etCollection The address of the Elliotrades NFT collection
		@param _sfCollection The address of the SuperFarm NFT collection
		@param _token The address of the staking erc20 token
		@param _rewardPeriod The length of time rewards are emitted
	*/
	constructor(
		address _etCollection,
		address _sfCollection,
		address _token,
		uint256 _rewardPeriod
	) StakerConfig (
		_etCollection,
		_sfCollection,
		_token,
		_rewardPeriod
	) { }

	/**
		Handle ETH reward deposits.
	*/
	receive () external payable{
		emit Fund(
			msg.sender, 
			msg.value
		);
	}

	/**
		Helper function for calculating the total amount of reward emissions.
	*/
	function _produced () private view returns (uint256) {
		return allProduced + 
			reward * (block.timestamp - producedTimestamp) / REWARD_PERIOD;
	}

	/**
		Helper function that handles updating rewards per point and total 
		producedReward.
	*/
	function _update () private {
		uint256 current = _produced();
		if (current > producedReward) {
			uint256 difference = current - producedReward;
			if (totalPower > 0) {
				rpp += difference * PRECISION / totalPower;
			}
			producedReward += difference;
		}
	}

	/**
		Calculate pending reward for a given address

		@param _recipient the user querying their rewards
		@param _rpp current rewards per point

		@return reward the amount of rewards the user is due
	*/
	function _calcReward (
		address _recipient,
		uint256 _rpp
	) private view returns(uint256) {
		Staker storage staker = _stakers[_recipient];
		return staker.stakerPower * _rpp/ PRECISION - 
			staker.claimedReward - staker.missedReward;
	}

	/**
		A helper function for locking ERC20 and ERC1155 assets and
		calculating staker's gained power.

		@param _erc20Amount Amount of ERC20 staking tokens.
		@param _items An array of ERC1155 items being staked.
		@param _staker A storage pointer to staker.

		@return power A sum of all assets power.
	*/
	function _addAssets (
		uint256 _erc20Amount,
		InputItem[] calldata _items,
		Staker storage _staker
	) private returns (uint256 power) {

		/// Handle ERC20 tokens
		IERC20(TOKEN).safeTransferFrom(
			msg.sender,
			address(this),
			_erc20Amount
		);

		power = _erc20Amount;
		
		for (uint256 i; i < _items.length; ){
			
			if (_items[i].origin == ItemOrigin.SF1155) {

				if (_staker.SFs.exists(_items[i].itemId)) {
					revert ItemAlreadyStaked();
				}

				IFee1155(SF_COLLECTION).safeTransferFrom(
					msg.sender,
					address(this),
					_items[i].itemId,
					SINGLE_ITEM,
					""
				);

				_staker.SFs.add(_items[i].itemId);
			} 

			if (_items[i].origin == ItemOrigin.ET1155) {
				
				if (_staker.ETs.exists(_items[i].itemId)) {
					revert ItemAlreadyStaked();
				}

				IFee1155(ET_COLLECTION).safeTransferFrom(
					msg.sender,
					address(this),
					_items[i].itemId,
					SINGLE_ITEM,
					""
				);

				_staker.ETs.add(_items[i].itemId);
			}

			//get item id and parse group id
			uint256 grpId = _items[i].itemId >> 128;

			unchecked {
				//add value from group id in item reward mapping
				power += itemValues[_items[i].origin][grpId];
				++i;
			}
		}
	}

	/**
	   A helper function for retrieving ERC20 and ERC1155 assets and
		calculating staker's lost power.

		@param _erc20Amount Amount of ERC20 staking tokens.
		@param _items An array of ERC1155 items being staked.
		@param _staker A storage pointer to staker.

		@return power A sum of all assets power.
	*/
	function _removeAssets (
		uint256 _erc20Amount,
		InputItem[] calldata _items,
		Staker storage _staker
	) private returns (uint256 power) {

		if (_erc20Amount > _staker.stakedTokens) {
			revert AmountExceedsStakedAmount();
		}

		/// Handle ERC20 tokens
		IERC20(TOKEN).safeTransfer(
			msg.sender,
			_erc20Amount
		);

		power = _erc20Amount;
		
		for (uint256 i; i < _items.length; ){
			
			if (_items[i].origin == ItemOrigin.SF1155) {

				if (!_staker.SFs.exists(_items[i].itemId)) {
					revert ItemNotFound();
				}

				IFee1155(SF_COLLECTION).safeTransferFrom(
					address(this),
					msg.sender,
					_items[i].itemId,
					SINGLE_ITEM,
					""
				);

				_staker.SFs.remove(_items[i].itemId);
			} 

			if (_items[i].origin == ItemOrigin.ET1155) {
				
				if (!_staker.ETs.exists(_items[i].itemId)) {
					revert ItemNotFound();
				}

				IFee1155(ET_COLLECTION).safeTransferFrom(
					address(this),
					msg.sender,
					_items[i].itemId,
					SINGLE_ITEM,
					""
				);

				_staker.ETs.remove(_items[i].itemId);
			}

			//get item id and parse group id
			uint256 grpId = _items[i].itemId >> 128;

			unchecked {
				//add value from group id in item reward mapping
				power += itemValues[_items[i].origin][grpId];
				++i;
			}
		}
	}

	/**
		Helper function that handles updating reward ratio and distributes 
		rewards to the user
	*/
	function _claim () private {
		_update();

		uint256 rewardAmount = _calcReward(msg.sender, rpp);
		if (rewardAmount == 0) {
			return;
		}

		(bool success,) = msg.sender.call{value: rewardAmount}("");
		if (!success) {
			revert RewardPayoutFailed();
		}

		unchecked {
			_stakers[msg.sender].claimedReward += rewardAmount;
		}
		
		emit Claim(msg.sender, rewardAmount);
	}

	/**
		Stake ERC20 tokens and items from specified collections.  The amount of 
		ERC20 tokens can be zero as long as at least one item is staked.  
		Similarly, the amount of items being staked can be zero as long as the 
		user is staking ERC20 tokens.  Tokens can be staked on a user's behalf,
		provided the caller has the necessary approvals for transfers by the user

		@param _amount The amount of ERC20 tokens being staked
		@param _user The address of the user staking tokens
		@param _items The array of items being staked
	*/
	function stake (
		uint256 _amount,
		address _user,
		InputItem[] calldata _items
	) external nonReentrant {

		if(_amount == 0 && _items.length == 0){
			revert BadArguments();
		}

		Staker storage staker = _stakers[_user];

		stakeTimestamps[_user] = block.timestamp;

		uint256 power = _addAssets(_amount, _items, staker);

		_update();

		/// Update balance and positions
		unchecked {
			staker.stakedTokens += _amount;
			staker.stakerPower += power;
			staker.missedReward += power * rpp / PRECISION;
			totalPower += power;
		}

		emit Stake(
			_user,
			_amount,
			power,
			_items
		);
	}

	/**
		Withdraw ERC20 tokens and items from specified collections and 
		distribute rewards to the caller.  

		@param _amount The amount of ERC20 tokens to withdraw
		@param _items The array of items to withdraw
	*/
	function withdraw (
		uint256 _amount,
		InputItem[] calldata _items
	) external nonReentrant {

		if(_amount == 0 && _items.length == 0){
			revert BadArguments();
		}

		if( block.timestamp - WITHDRAW_BUFFER < stakeTimestamps[msg.sender]){
			revert WithdrawBufferNotFinished();
		}

		Staker storage staker = _stakers[msg.sender];

		uint256 lostPower = _removeAssets(_amount, _items, staker);

		_claim();

		uint256 difference = staker.stakerPower - lostPower;

		unchecked {
			staker.stakedTokens -= _amount;
			staker.stakerPower = difference;
			staker.missedReward = difference * rpp / PRECISION;
			totalPower -= lostPower;
		}
		delete staker.claimedReward;

		emit Withdraw(
			msg.sender,
			_amount,
			lostPower,
			_items
		);
	}

	/**
		Helper function that handles updating reward ratio and distributes 
		rewards to the user
	*/
	function claim () external nonReentrant {
		_claim();
	}

	/**
		Update produced reward amounts and adjust the reward rate to emit 
		rewards for the entirety of the REWARD_PERIOD. This function has a cool 
		down period and can only be called at a minimum frequency of 
		rebaseCooldown seconds.
	*/
	function rebase () external {
		if( block.timestamp < nextRebaseTimestamp ){
			revert RebaseWindowClosed();
		}

		allProduced = _produced();
		reward = address(this).balance;
		producedTimestamp = block.timestamp;
		nextRebaseTimestamp = block.timestamp + rebaseCooldown;
	}

	function availableReward (address _staker) public view returns (uint256) {
		uint256 rpp_virtual = rpp;
		uint256 current = _produced();
		uint256 difference = current - producedReward;
		if (totalPower > 0) {
			rpp_virtual += difference * PRECISION / totalPower;
		}
		return _calcReward(_staker, rpp_virtual);
	}

	/**
		View function for retrieving a user's staking position data

		@param _staker the address of the user 

		@return stakerPower the total power of all staking postions
		@return stakedTokens the amount of ERC20 tokens the user has staked
		@return claimedReward the amount of ERC20 tokens the user had claimed
		@return missedReward the amount of ERC20 tokens the user missed
		@return availableToClaim the amount of the rewards the user can claim
		@return idsET the user's staked items from the ET Collection
		@return idsSFs the user's staked items from the SF Collection
	*/
	function stakerInfo (
		address _staker
	) external view returns (
		uint256 stakerPower,
		uint256 stakedTokens,
		uint256 claimedReward,
		uint256 missedReward,
		uint256 availableToClaim,
		uint256[] memory idsET,
		uint256[] memory idsSFs
	) {
		Staker storage staker = _stakers[_staker];
		availableToClaim = availableReward(_staker);
		stakerPower = staker.stakerPower;
		stakedTokens = staker.stakedTokens;
		claimedReward = staker.claimedReward;
		missedReward = staker.missedReward;
		idsET = staker.ETs.array;
		idsSFs = staker.SFs.array;
	}
}

