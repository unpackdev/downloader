// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "./ERC1363Spec.sol";
import "./AbstractShares.sol";

/**
 * @title ERC20 Shares
 *
 * @notice TradeableShares implementation using ERC20 token as a payment token
 *
 * @dev Doesn't have "payable" functions, that is the functions accepting ETH
 *
 * @dev Based on the friend.tech FriendtechSharesV1.sol
 */
contract ERC20Shares is AbstractShares {
	/// @dev ERC1363 payment token used for payments
	ERC1363 private /*immutable*/ paymentToken;

	/**
	 * @dev Deploys the ERC20Shares instance and initializes it
	 *
	 * @param _owner the address receiving all the RBAC permissions on the contract
	 * @param _sharesSubject shares subject, usually defined as NFT (ERC721 contract address + NFT ID)
	 * @param _protocolFeeDestination protocol fee destination, the address protocol fee is sent to
	 * @param _protocolFeePercent protocol fee percent, applied to all the buy and sell operations;
	 *      the fee percent is defined with the 18 decimals, 10^18 corresponds to 100%
	 * @param _holdersFeeDestination shares holders fee destination, the HoldersRewardsDistributor contract
	 *      the shares holders fee is sent to
	 * @param _holdersFeePercent shares holders fee percent, applied to all the buy and sell operations,
	 *      the fee percent is defined with the 18 decimals, 10^18 corresponds to 100%
	 * @param _subjectFeePercent subject fee percent, applied to all the buy and sell operations,
	 *      the fee percent is defined with the 18 decimals, 10^18 corresponds to 100%
	 * @param _amount how many shares to buy immediately upon "post-construction", can be zero
	 * @param _beneficiary the address receiving the shares bought immediately (must be set
	 *      if `_amount` is not zero)
	 * @param _paymentToken ERC1363 token used as a payment token instead of ETH
	 */
	constructor(
		address _owner,
		SharesSubject memory _sharesSubject,
		address _protocolFeeDestination,
		uint64 _protocolFeePercent,
		HoldersRewardsDistributor _holdersFeeDestination,
		uint64 _holdersFeePercent,
		uint64 _subjectFeePercent,
		uint256 _amount,
		address _beneficiary,
		ERC1363 _paymentToken
	) initializer {
		// initialize the deployed instance
		postConstruct(
			_owner,
			_sharesSubject,
			_protocolFeeDestination,
			_protocolFeePercent,
			_holdersFeeDestination,
			_holdersFeePercent,
			_subjectFeePercent,
			_amount,
			_beneficiary,
			_paymentToken
		);
	}

	/**
	 * @dev "Constructor replacement" for initializable, must be execute during or immediately after deployment
	 *      see https://docs.openzeppelin.com/upgrades-plugins/1.x/writing-upgradeable#initializers
	 *
	 * @param _owner the address receiving all the RBAC permissions on the contract
	 * @param _sharesSubject shares subject, usually defined as NFT (ERC721 contract address + NFT ID)
	 * @param _protocolFeeDestination protocol fee destination, the address protocol fee is sent to
	 * @param _protocolFeePercent protocol fee percent, applied to all the buy and sell operations;
	 *      the fee percent is defined with the 18 decimals, 10^18 corresponds to 100%
	 * @param _holdersFeeDestination shares holders fee destination, the HoldersRewardsDistributor contract
	 *      the shares holders fee is sent to
	 * @param _holdersFeePercent shares holders fee percent, applied to all the buy and sell operations,
	 *      the fee percent is defined with the 18 decimals, 10^18 corresponds to 100%
	 * @param _subjectFeePercent subject fee percent, applied to all the buy and sell operations,
	 *      the fee percent is defined with the 18 decimals, 10^18 corresponds to 100%
	 * @param _amount how many shares to buy immediately upon "post-construction", can be zero
	 * @param _beneficiary the address receiving the shares bought immediately (must be set
	 *      if `_amount` is not zero)
	 * @param _paymentToken ERC20 token used as a payment token instead of ETH
	 */
	function postConstruct(
		address _owner,
		SharesSubject memory _sharesSubject,
		address _protocolFeeDestination,
		uint64 _protocolFeePercent,
		HoldersRewardsDistributor _holdersFeeDestination,
		uint64 _holdersFeePercent,
		uint64 _subjectFeePercent,
		uint256 _amount,
		address _beneficiary,
		ERC1363 _paymentToken
	) public initializer {
		// execute parent initializer
		_postConstruct(
			_owner,
			_sharesSubject,
			_protocolFeeDestination,
			_protocolFeePercent,
			_holdersFeeDestination,
			_holdersFeePercent,
			_subjectFeePercent
		);
		// no need to check if payment token is zero since this is designed to be
		// deployed only from the factory where the ERC20 address in non-modifiable
		// and is defined on the deployment of the factory
		paymentToken = _paymentToken;

		// buy shares if requested
		if(_amount != 0) {
			__buySharesTo(_amount, _beneficiary);
		}
	}

	/**
	 * @notice ERC1363 payment token getter
	 *
	 * @return ERC1363 payment token, immutable
	 */
	function getPaymentToken() public view returns(ERC1363) {
		// read from the storage and return
		return paymentToken;
	}

	/**
	 * @inheritdoc TradeableShares
	 */
	function buyShares(uint256 amount) public payable {
		// delegate to `buySharesTo`
		buySharesTo(amount, msg.sender);
	}

	/**
	 * @inheritdoc TradeableShares
	 */
	function sellShares(uint256 amount) public {
		// delegate to `sellSharesTo`
		sellSharesTo(amount, payable(msg.sender));
	}

	/**
	 * @inheritdoc TradeableShares
	 */
	function buySharesTo(uint256 amount, address beneficiary) public payable {
		// verify the first share is not bought
		require(getSharesSupply() > 0 || getSharesIssuer() == msg.sender, "only the issuer can buy the first share");

		// delegate to unsafe `__buySharesTo`
		__buySharesTo(amount, beneficiary);
	}

	/**
	 * @dev Buys amount of shares for the beneficiary, without checking if the first share was bought
	 *
	 * @param amount amount of the shares to buy
	 * @param beneficiary an address receiving the shares
	 */
	function __buySharesTo(uint256 amount, address beneficiary) private {
		// ERC20 implementation doesn't expect Ether to be sent
		require(msg.value == 0, "only payment in ERC20 token is expected");

		// cache the supply value
		uint256 supply = getSharesSupply();

		// update the balances (note: security checks are below)
		sharesBalances[beneficiary] += amount;
		sharesSupply = supply + amount;

		// determine the price and process the fees
		uint256 price = getPrice(supply, amount);
		(, , uint256 protocolFee) = __processProtocolFee(msg.sender, price);
		(, , uint256 holdersFee) = __processHoldersFeeAndNotify(msg.sender, price, true, amount, beneficiary);
		(address issuer, , uint256 subjectFee) = __processSubjectFee(msg.sender, price);

		// do the required ERC20 payment token price transfer
		require(
			// do not try to transfer zero price
			price == 0 || paymentToken.transferFrom(msg.sender, address(this), price),
			"payment failed"
		);

		// emit an event
		emit Trade(beneficiary, issuer, true, amount, price, protocolFee, holdersFee, subjectFee, sharesSupply);
	}

	/**
	 * @inheritdoc TradeableShares
	 */
	function sellSharesTo(uint256 amount, address payable beneficiary) public {
		// verify the amount vs total supply
		uint256 supply = getSharesSupply();
		require(supply > amount, "cannot sell the last share");

		// verify the amount vs seller's balance
		uint256 balance = getSharesBalance(msg.sender);
		require(balance >= amount, "insufficient shares");

		// update the balances
		sharesBalances[msg.sender] = balance - amount;
		sharesSupply = supply - amount;

		// determine the price and process the fees
		uint256 price = getPrice(supply - amount, amount);
		(, , uint256 protocolFee) = __processProtocolFee(address(this), price);
		(, , uint256 holdersFee) = __processHoldersFeeAndNotify(address(this), price, false, amount, msg.sender);
		(address issuer, , uint256 subjectFee) = __processSubjectFee(address(this), price);

		// price cannot be zero since the last share cannot be sold
		// if the price transfer fails, we do fail
		// note: if any of the fees failed to transfer, they are sent to the seller
		require(
			paymentToken.transfer(beneficiary, price - protocolFee - holdersFee - subjectFee),
			"payment failed"
		);

		// emit an event
		emit Trade(beneficiary, issuer, false, amount, price, protocolFee, holdersFee, subjectFee, sharesSupply);
	}

	/**
	 * @dev Calculates the protocol fee and sends it to the protocol fee destination
	 *
	 * @param from the address where the tokens are being sent from, this can be either
	 *      the the shares buyer, or the contract itself (when selling)
	 * @param price already calculated price of the trade
	 */
	function __processProtocolFee(address from, uint256 price) private returns(
		address protocolFeeDestination,
		uint256 protocolFeePercent,
		uint256 protocolFee
	) {
		// read fee information in a consistent way
		(protocolFeeDestination, protocolFeePercent) = getProtocolFeeInfo();

		// calculate the fee
		protocolFee = price * protocolFeePercent / 1 ether;

		// do the required ERC20 payment token transfer
		require(
			// do not try to transfer zero protocol fee
			protocolFee == 0 || paymentToken.transferFrom(from, protocolFeeDestination, protocolFee),
			"protocol fee payment failed"
		);
	}

	/**
	 * @dev Calculates the shares holders fee and sends it to the holders fee destination;
	 *      notifies the destination (which is a HoldersRewardsDistributor contract) about
	 *      the trade, submits trader address, and trade amount
	 *
	 * @dev isBuy is true if the shares are bought
	 *      isBuy is false if the shares are sold
	 *
	 * @param from the address where the tokens are being sent from, this can be either
	 *      the the shares buyer, or the contract itself (when selling)
	 * @param price already calculated price of the trade
	 * @param isBuy operation type, [true] buying, [false] selling
	 * @param amount trade amount
	 * @param trader an account which makes a trade, whose shares balance changes by the `amount`
	 */
	function __processHoldersFeeAndNotify(address from, uint256 price, bool isBuy, uint256 amount, address trader) private returns(
		HoldersRewardsDistributor holdersFeeDestination,
		uint256 holdersFeePercent,
		uint256 holdersFee
	) {
		// read fee information in a consistent way
		(holdersFeeDestination, holdersFeePercent) = getHoldersFeeInfo();

		// calculate the fee
		holdersFee = price * holdersFeePercent / 1 ether;

		// do the required ERC1363 payment token transfer and HoldersRewardsDistributor sync
		if(address(holdersFeeDestination) != address(0) && amount != 0) {
			// construct the HoldersRewardsDistributor sync message
			bytes memory syncMessage = abi.encode(trader, isBuy, amount);

			// send the fee together with the sync message
			bool success = paymentToken.transferFromAndCall(from, address(holdersFeeDestination), holdersFee, syncMessage);

			// we require synchronization to succeed, otherwise we can't guarantee data consistency
			// on the HoldersRewardsDistributor contract's side
			require(success, "sync failed");
		}
	}

	/**
	 * @dev Calculates the subject fee and sends it to the issuer
	 *
	 * @param from the address where the tokens are being sent from, this can be either
	 *      the the shares buyer, or the contract itself (when selling)
	 * @param price already calculated price of the trade
	 */
	function __processSubjectFee(address from, uint256 price) private returns(
		address subjectFeeDestination,
		uint256 subjectFeePercent,
		uint256 subjectFee
	) {
		// read fee information in a consistent way
		(subjectFeeDestination, subjectFeePercent) = getSubjectFeeInfo();

		// calculate the fee
		subjectFee = price * subjectFeePercent / 1 ether;

		// do the required ERC20 payment token transfer
		require(
			// do not try to transfer zero subject fee
			subjectFee == 0 || paymentToken.transferFrom(from, subjectFeeDestination, subjectFee),
			"subject fee payment failed"
		);
	}
}
