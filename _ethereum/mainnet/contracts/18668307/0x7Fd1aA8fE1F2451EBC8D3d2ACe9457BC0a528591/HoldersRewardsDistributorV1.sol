// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "./HoldersRewardsDistributor.sol";
import "./Transfers.sol";
import "./InitializableAccessControl.sol";

/**
 * @title Bonding Curve Holder Reward Distributor
 *
 * @notice Holder reward distributor keeps track of every trade event happening in the curve,
 *      and based on the amount of shares the holder has, alters the holders' reward weight,
 *      which directly affects the amount of the distributed rewards between the holders
 *
 * @notice Holder reward distributor accepts the fees from the curve and distributes these fees
 *      across shares holders proportionally to their weights
 *
 * @dev Apart from the `accept(uint256,address)` function designed to accept the fees from the
 *      curve contract, the implementation must implement receive(), fallback(), and onTransferReceived()
 *      functions to accept direct payments in both ETH and/or ERC20 payment token
 *
 * @dev receive() and onTransferReceived() with an empty data field must accept the fee in the same way
 *      as an accept() function would do, but in a passive way (without ERC20 transfer)
 *
 * @dev The fallback() and onTransferReceived() with non-empty data field must accept the fee and the trading event;
 *      trading event encoded in the bytes data field contains the information
 *      on the trade which resulted in the fee being sent:
 *
 *      - address trader - shares holder/trader
 *      - bool isBuy - true if shares were bought, false if shares were sold
 *      - uint256 sharesAmount - amount of shares bought or sold
 *
 *      the values above are packed as data = abi.encode(trader, isBuy, sharesAmount)
 *      and can be unpacked as (trader, isBuy, sharesAmount) = abi.decode(data, (address, bool, uint256))
 *
 *      if specified, the data field must be parsed by the implementation and its containing data applied;
 *      standard logic applies, if the data is malformed implementation should throw
 *
 */
contract HoldersRewardsDistributorV1 is HoldersRewardsDistributor, InitializableAccessControl {
	// Info of each user.
	struct UserInfo {
		uint256 shares;
		uint256 rewardDebt;
		uint256 claimedAmount;
		uint256 unclaimedAmount;
	}

	// ERC20 payment token address
	address private /*immutable*/ paymentToken;
	/// bonding curve contract address
	address public sharesContractAddress;
	/// Last block number that reward distribution occurs.
	uint256 public lastRewardBlock;
	/// accumulated reward per share, times 1e18 (with 18 decimal precision)
	uint256 public accRewardPerShare;
	/// total number of share registered
	uint256 public totalShares;
	// Info of each user that stakes LP tokens.
	mapping(address => UserInfo) public userInfo;

	/**
	 * @dev Deploys the distributor contract
	 *
	 * @param _owner contract, optional (can be zero address), since there are no admin functions
	 * @param _sharesContractAddress TradeableShares contract to bind the distributor to,
	 *      optional (can be zero address), this can be set up later with the
	 *      `initializeSharesContractAddressIfRequired` function
	 * @param _paymentToken ERC1363 payment token to bind to, optional (can be zero address),
	 *      zero address means distributor works with the plain ETH
	 */
	constructor(address _owner, address _sharesContractAddress, address _paymentToken) initializer {
		// initialize the deployed instance
		postConstruct(_owner, _sharesContractAddress, _paymentToken);
	}

	/**
	 * @dev "Constructor replacement" for initializable, must be execute during or immediately after deployment
	 *      see https://docs.openzeppelin.com/upgrades-plugins/1.x/writing-upgradeable#initializers
	 *
	 * @param _owner contract, optional (can be zero address), since there are no admin functions
	 * @param _sharesContractAddress TradeableShares contract to bind the distributor to,
	 *      optional (can be zero address), this can be set up later with the
	 *      `initializeSharesContractAddressIfRequired` function
	 * @param _paymentToken ERC1363 payment token to bind to, optional (can be zero address),
	 *      zero address means distributor works with the plain ETH
	 */
	function postConstruct(address _owner, address _sharesContractAddress, address _paymentToken) public initializer {
		// execute parent initializer(s)
		_postConstruct(_owner);

		sharesContractAddress = _sharesContractAddress;
		paymentToken = _paymentToken;
		lastRewardBlock = block.timestamp;
	}

	/**
	 * @notice Sets the TradeableShares contract to bind the distributor to
	 *
	 * @dev TradeableShares contract can be set only once; fails if it is already set
	 * @param _sharesContractAddress TradeableShares contract to bind the distributor to
	 */
	function initializeSharesContractAddressIfRequired(address _sharesContractAddress) public {
		// check the address is not yet set
		require(sharesContractAddress == address(0) && _sharesContractAddress != address(0), "already initialized");

		// set the TradeableShares contract address
		sharesContractAddress = _sharesContractAddress;
	}

	/**
	 * @inheritdoc HoldersRewardsDistributor
	 */
	function getPaymentToken() public view returns (address) {
		return paymentToken;
	}

	/**
	 * @dev Executed when TradeableShares contract notifies about shares bought event
	 */
	function __sharesBought(address _buyer, uint256 _amountBought) private {
		UserInfo storage userDetail = userInfo[_buyer];
		if(userDetail.shares > 0) {
			// calculated pending reward if any
			uint256 pending = ((userDetail.shares * accRewardPerShare) / 1e18) - userDetail.rewardDebt;
			if(pending > 0) {
				// update unclaimed amount
				userDetail.unclaimedAmount += pending;
			}
		}

		// update state variables
		userDetail.shares += _amountBought;
		totalShares += _amountBought;
		userDetail.rewardDebt = (userDetail.shares * accRewardPerShare) / 1e18;
	}

	/**
	 * @dev Executed when TradeableShares contract notifies about shares sold event
	 */
	function __sharesSold(address _seller, uint256 _amountSold) private {
		require(_amountSold <= userInfo[_seller].shares, "amount must be <= registered amount");

		UserInfo storage userDetail = userInfo[_seller];
		// calculated pending reward if any
		uint256 pending = ((userDetail.shares * accRewardPerShare) / 1e18) - userDetail.rewardDebt;
		if(pending > 0) {
			// update unclaimed amount
			userDetail.unclaimedAmount += pending;
		}

		// update state variables
		userDetail.shares = userDetail.shares - _amountSold;
		totalShares = totalShares - _amountSold;
		userDetail.rewardDebt = (userDetail.shares * accRewardPerShare) / 1e18;
	}

	/**
	 * @dev Executed when TradeableShares contract send the fees;
	 * @dev The very first tranche of the fees might be ignored if it is done by the issuer
	 */
	function __accept(uint256 _feeAmount) private {
		// check the state can accept the changes
		if(_feeAmount == 0 || totalShares == 0 || block.timestamp <= lastRewardBlock) {
			return;
		}

		// update state variables
		accRewardPerShare += (_feeAmount * 1e18) / totalShares;
		lastRewardBlock = block.timestamp;

		// emit an event
		emit FeeReceived(_feeAmount);
	}


	/**
	 * @dev Processes the fee, and the sync message
	 *
	 * @dev Takes care about the encoded bytes data containing trader address, trade operation type,
	 *      and amount of the shares bought
	 *
	 * @dev Format: address | bool | uint256
	 */
	function __parseTrade(uint256 _feeAmount, bytes memory data) private {
		if(totalShares == 0) {
			__parseFirstTrade(_feeAmount, data);
		}
		else {
			__parseNextTrade(_feeAmount, data);
		}
	}

	/**
	 * @dev Processes the very first fee, and the sync message
	 */
	function __parseFirstTrade(uint256 _feeAmount, bytes memory data) private {
		// the very first sync message must not be empty
		require(data.length != 0, "sync message expected");

		// decode the sync message
		(address trader, bool isBuy, uint256 sharesAmount) = abi.decode(data, (address, bool, uint256));
		// the very first operation can be buy only, and cannot be zero
		require(isBuy && sharesAmount >= 1, "invalid state");

		// init: notify about the first share
		__sharesBought(trader, 1);
		// to save the gas execute the rest of the functions only if there is a need
		if(sharesAmount > 1) {
			// process the fee
			__accept(_feeAmount);
			// notify about the remaining shares
			__sharesBought(trader, sharesAmount - 1);
		}

		// emit an event
		emit SharesTraded(trader, true, sharesAmount);
	}

	/**
	 * @dev Processes not the very first fee, and the sync message
	 */
	function __parseNextTrade(uint256 _feeAmount, bytes memory data) private {
		// process the fee
		__accept(_feeAmount);

		// if the sync message is empty, we're done
		if(data.length == 0) {
			return;
		}

		// decode the sync message
		(address trader, bool isBuy, uint256 sharesAmount) = abi.decode(data, (address, bool, uint256));
		if(isBuy) {
			// notify buy
			__sharesBought(trader, sharesAmount);
		}
		else {
			// notify sell
			__sharesSold(trader, sharesAmount);
		}

		// emit an event
		emit SharesTraded(trader, isBuy, sharesAmount);
	}

	/**
	 * @inheritdoc HoldersRewardsDistributor
	 */
	function claimTheReward() public {
		uint256 claimableAmount = pendingReward(msg.sender);
		require(claimableAmount > 0, "Nothing to claim");

		UserInfo storage userDetail = userInfo[msg.sender];
		// update state variable
		userDetail.unclaimedAmount = 0;
		userDetail.claimedAmount += claimableAmount;
		userDetail.rewardDebt = (userDetail.shares * accRewardPerShare) / 1e18;

		// transfer reward
		if(paymentToken == address(0)) {
			Transfers.transfer(payable(msg.sender), claimableAmount);
		}
		else {
			require(ERC20(paymentToken).transfer(msg.sender, claimableAmount));
		}

		// emit an event
		emit RewardClaimed(msg.sender, claimableAmount);
	}

	/**
	 * @inheritdoc HoldersRewardsDistributor
	 */
	function pendingReward(address holder) public view returns (uint256) {
		UserInfo memory userDetail = userInfo[holder];
		uint256 pending = ((userDetail.shares * accRewardPerShare) / 1e18) - userDetail.rewardDebt;

		return userDetail.unclaimedAmount + pending;
	}

	/**
	 * @inheritdoc ERC1363Receiver
	 *
	 * @notice Anyone can send some additional rewards – just use empty `data` for a callback
	 *
	 * @dev Non-empty `data` executes trade updates and therefore is restricted to be sent only
	 *      by `sharesContractAddress`
	 */
	function onTransferReceived(address operator, address, uint256 value, bytes memory data) public returns (bytes4) {
		require(msg.sender == paymentToken, "received event from wrong token");
		require(operator == sharesContractAddress, "not allowed");

		__parseTrade(value, data);
		return ERC1363Receiver(this).onTransferReceived.selector;
	}

	/**
	 * @notice Receive is public. Anyone can send some additional rewards ;)
	 */
	receive() external payable {
		require(paymentToken == address(0), "not allowed");
		__parseTrade(msg.value, bytes(""));
	}

	/**
	 * @dev Fallback executes trade updates and therefore is restricted to be executed only by `sharesContractAddress`
	 *
	 * @notice If you want do donate some rewards - use `receive()`
	 */
	fallback() external payable {
		require(paymentToken == address(0), "not an erc20 reward reward distributor");

		require(msg.sender == sharesContractAddress, "not allowed");
		__parseTrade(msg.value, msg.data);
	}
}
