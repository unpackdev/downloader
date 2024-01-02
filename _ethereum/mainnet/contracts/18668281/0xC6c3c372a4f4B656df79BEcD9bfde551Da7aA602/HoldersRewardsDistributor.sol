// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "./ERC1363Spec.sol";

/**
 * @title Bonding Curve Holders Rewards Distributor
 *
 * @notice Holders rewards distributor keeps track of every trade event happening in the curve,
 *      and based on the amount of shares the holder has, alters the holders' reward weight,
 *      which directly affects the amount of the distributed rewards between the holders
 *
 * @notice Holders rewards distributor accepts the fees from the curve and distributes these fees
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
 *      - int256 sharesAmount - amount of shares [positive] bought or [negative] sold
 *
 *      the values above are packed as
 *            data = abi.encode(trader, sharesAmount)
 *      and can be unpacked as
 *            (trader, sharesAmount) = abi.decode(data, (address, int256))
 *            isBuy = sharesAmount > 0
 *
 *      if specified, the data field must be parsed by the implementation and its containing data applied;
 *      standard logic applies, if the data is malformed implementation should throw
 *
 */
interface HoldersRewardsDistributor is ERC1363Receiver {
	/**
	 * @dev Fired in `sharesBought` and `sharesSold`
	 *
	 * @param trader is a buyer or a seller, depending on the operation type
	 * @param isBuy true if the event comes from the `sharesBought` and represents the buy operation,
	 *      false if the event comes from the `sharesSold` and represents the sell operation
	 * @param sharesAmount amount of the shares bought or sold (see `isBuy`)
	 */
	event SharesTraded(address indexed trader, bool indexed isBuy, uint256 sharesAmount);

	/**
	 * @dev Fired when the fee for the distribution is received
	 *
	 * @param feeAmount amount of the fee to distribute between the holders
	 */
	event FeeReceived(uint256 feeAmount);

	/**
	 * @dev Fired in `claimReward`
	 *
	 * @param holder address of the trader (and shares holder) who received the reward
	 * @param rewardAmount amount of the reward sent
	 */
	event RewardClaimed(address indexed holder, uint256 rewardAmount);

	/**
	 * @notice ERC20 payment token distributor is bound to
	 *
	 * @return paymentToken ERC20 payment token address the contract is bound to,
	 *      or zero zero address if it operates with the plain ETH
	 */
	function getPaymentToken() external view returns(address paymentToken);

/*
	*/
/**
	 * @notice Notifies the distributor about the trade event
	 *
	 * @dev Trade amount specified affects holder's (buyer's) weight when calculating the reward
	 *
	 * @param buyer shares buyer (becomes shares holder if not yet), a.k.a trader
	 * @param amountBought amount of the shares bought
	 *//*

	function sharesBought(address buyer, uint256 amountBought) external;

	*/
/**
	 * @notice Notifies the distributor about the trade event
	 *
	 * @dev Trade amount specified affects holder's (seller's) weight when calculating the reward
	 *
	 * @param seller shares seller (shares holder), a.k.a trader
	 * @param amountSold amount of the shares sold
	 *//*

	function sharesSold(address seller, uint256 amountSold) external;

	*/
/**
	 * @notice Executed by the fee sender to send the fee; in case of the ERC20 payment,
	 *      this is the ask to take the specified amount of the ERC20 token of the specified type;
	 *      in case of the ETH payment, the amount must be supplied with the transaction itself
	 *
	 * @dev When paying with an ERC20 payment token, sender must approve the contract for
	 *      at least the amount specified before executing this function
	 *
	 * @dev Updates the accumulated reward per share
	 *
	 * @param feeAmount amount of the fee sent,
	 *      in the case of ETH payment must be equal to msg.value
	 *//*

	function accept(uint256 feeAmount) external payable;
*/

	/**
	 * @notice Executed by the holder to claim entire pending reward
	 *
	 * @dev Holder can verify pending reward amount with the `pendingReward` function
	 */
	// TODO: do we want to specify where to send the reward?
	function claimTheReward() external;

	/**
	 * @notice Pending (claimable) reward. This is the amount which can be claimed using `claimTheReward`
	 *
	 * @param holder the holder address to query the reward for
	 * @return rewardAmount pending reward amount\
	 */
	function pendingReward(address holder) external view returns(uint256 rewardAmount);
}
