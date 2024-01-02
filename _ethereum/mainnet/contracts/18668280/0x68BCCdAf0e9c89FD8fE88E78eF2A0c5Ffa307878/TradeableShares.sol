// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "./BondingCurve.sol";
import "./HoldersRewardsDistributor.sol";

/**
 * @title Tradeable Shares
 *
 * @notice Tradeable shares is a non-transferable, but buyable/sellable fungible token-like asset,
 *      which is sold/bought solely by the shares contract at the predefined by
 *      the bonding curve function price
 *
 * @notice The shares is bound to its "subject" – an NFT; the NFT owner gets the subject fee
 *      emerging in every buy/sell operation
 *
 * @dev Based on the friend.tech FriendtechSharesV1.sol
 */
interface TradeableShares is BondingCurve {
	/**
	 * @notice Shares subject is an NFT defined by its ERC721 contract address and NFT ID
	 *       Note: this is different from the original FriendTech implementation where
	 *       shares subject is always equal to the issuer address
	 */
	struct SharesSubject {
		/// @dev ERC721 contract address
		address tokenAddress;

		/// @dev NFT ID
		uint256 tokenId;
	}

	/**
	 * @dev Fired in `buyShares` and `sellShares` functions, this event logs
	 *      the entire trading activity happening on the curve
	 *
	 * @dev Trader, that is the buyer or seller, depending on the operation type is the transaction sender
	 *
	 * @param beneficiary the address which receives shares or funds, usually this is the trader itself
	 * @param issuer subject issuer, usually an owner of the NFT defined by the subject
	 * @param isBuy true if the event comes from the `buyShares` and represents the buy operation,
	 *      false if the event comes from the `sellShares` and represents the sell operation
	 * @param sharesAmount amount of the shares bought or sold (see `isBuy`)
	 * @param paidAmount amount of ETH spent or gained by the buyer or seller;
	 *      this is implementation dependent and can represent an amount of ERC20 payment token
	 * @param protocolFeeAmount amount of fees paid to the protocol
	 * @param holdersFeeAmount amount of fees paid to the shares holders
	 * @param subjectFeeAmount amount of fees paid to the subject (issuer)
	 * @param supply total shares supply after the operation
	 */
	event Trade(
		address indexed beneficiary,
		address indexed issuer,
		bool indexed isBuy,
		uint256 sharesAmount,
		uint256 paidAmount,
		uint256 protocolFeeAmount,
		uint256 holdersFeeAmount,
		uint256 subjectFeeAmount,
		uint256 supply
	);

	/**
	 * @notice Shares subject, usually defined as NFT (ERC721 contract address + NFT ID)
	 *
	 * @dev Immutable, client applications may cache this value
	 *
	 * @return Shares subject as a SharesSubject struct, this is an NFT if all currently known implementations
	 */
	function getSharesSubject() external view returns(SharesSubject calldata);

	/**
	 * @notice Protocol fee destination, the address protocol fee is sent to
	 *
	 * @dev Mutable, can be changed by the protocol fee manager
	 *
	 * @return the address where the protocol fee is sent to
	 */
	function getProtocolFeeDestination() external view returns(address);

	/**
	 * @notice Protocol fee percent, applied to all the buy and sell operations;
	 *      the fee percent is defined with the 18 decimals, 10^18 corresponds to 100%
	 *
	 * @notice Protocol fee is sent to the protocol fee destination (see `getProtocolFeeDestination`)
	 *
	 * @dev Immutable, client applications may cache this value
	 *
	 * @return protocol fee percent with the 18 decimals (10^18 is 100%)
	 */
	function getProtocolFeePercent() external view returns(uint256);

	/**
	 * @notice Protocol fee destination and protocol fee percent as a tuple;
	 *      the fee percent is defined with the 18 decimals, 10^18 corresponds to 100%
	 *
	 * @dev Implementation must always return zero fee percent if fee destination is zero address
	 *
	 * @return feeDestination protocol fee destination
	 * @return feePercent protocol fee percent, zero if protocol fee destination is zero
	 */
	function getProtocolFeeInfo() external view returns(address feeDestination, uint256 feePercent);

	/**
	 * @notice Shares holders reward distributor contract attached to the shares contract
	 *      in order to receive its portion of the fees to be distributed among the shares holders
	 *
	 * @dev Immutable, client applications may cache this value; holders fee destination is not
	 *      an arbitrary address capable of receiving ETH or ERC20, but a HoldersRewardsDistributor
	 *      smart contract, which not only receives the fees but also receives updated on the
	 *      trading activity in the shares contract
	 *
	 * @return the contract where the holders fee is sent to
	 */
	function getHoldersFeeDestination() external view returns(HoldersRewardsDistributor);

	/**
	 * @notice Shares holders fee percent, applied to all the buy and sell operations;
	 *      the fee percent is defined with the 18 decimals, 10^18 corresponds to 100%
	 *
	 * @notice Shares holders fee is sent to the holders fee destination (see `getHoldersFeeDestination`)
	 *
	 * @dev Immutable, client applications may cache this value
	 *
	 * @return shares holders fee percent with the 18 decimals (10^18 is 100%)
	 */
	function getHoldersFeePercent() external view returns(uint256);

	/**
	 * @notice Shares holders fee destination and shares holders fee percent as a tuple;
	 *      the fee percent is defined with the 18 decimals, 10^18 corresponds to 100%
	 *
	 * @dev Implementation must always return zero fee percent if fee destination is zero
	 *
	 * @return feeDestination shares holders fee destination
	 * @return feePercent shares holders fee percent, zero if holders fee destination is zero
	 */
	function getHoldersFeeInfo() external view returns(HoldersRewardsDistributor feeDestination, uint256 feePercent);

	/**
	 * @notice Subject fee destination and subject fee percent as a tuple;
	 *      subject fee destination is shares issuer address;
	 *      the fee percent is defined with the 18 decimals, 10^18 corresponds to 100%;
	 *
	 * @dev Implementation must always return zero fee percent if fee destination is zero address
	 *
	 * @return feeDestination protocol fee destination
	 * @return feePercent protocol fee percent, zero if subject fee destination is zero
	 */
	function getSubjectFeeInfo() external view returns(address feeDestination, uint256 feePercent);

	/**
	 * @notice Subject fee percent, applied to all the buy and sell operations,
	 *      the fee percent is defined with the 18 decimals, 10^18 corresponds to 100%
	 *
	 * @notice Subject fee is sent to the subject fee issuer (see `getSharesIssuer`)
	 *
	 * @dev Immutable, client applications may cache this value
	 *
	 * @return subject fee percent with the 18 decimals (10^18 is 100%)
	 */
	function getSubjectFeePercent() external view returns(uint256);

	/**
	 * @notice Shares issuer, the receiver of the shares fees
	 *
	 * @dev Mutable, changes (potentially frequently and unpredictably) when the NFT owner changes;
	 *      subject to the front-run attacks, off-chain client applications must not rely on this address
	 *      in anyway
	 *
	 * @return nftOwner subject issuer, the owner of the NFT
	 */
	function getSharesIssuer() external view returns(address nftOwner);

	/**
	 * @notice Shares balance of the given holder; this function is similar to ERC20.balanceOf()
	 *
	 * @param holder the address to check the balance for
	 *
	 * @return balance number of shares the holder has
	 */
	function getSharesBalance(address holder) external view returns(uint256 balance);

	/**
	 * @notice Total amount of the shares in existence, the sum of all individual shares balances;
	 *      this function is similar to ERC20.totalSupply()
	 *
	 * @return supply total shares supply
	 */
	function getSharesSupply() external view returns(uint256 supply);

	/**
	 * @notice The price of the `amount` of shares to buy calculated based on
	 *      the specified total shares supply
	 *
	 * @param supply total shares supply
	 * @param amount number of shares to buy
	 * @return the price of the shares to buy
	 */
	function getBuyPrice(uint256 supply, uint256 amount) external pure returns(uint256);

	/**
	 * @notice The price of the `amount` of shares to sell calculated based on
	 *      the specified total shares supply
	 *
	 * @param supply total shares supply
	 * @param amount number of shares to sell
	 * @return the price of the shares to sell
	 */
	function getSellPrice(uint256 supply, uint256 amount) external pure returns(uint256);

	/**
	 * @notice The price of the `amount` of shares to buy, including all fees;
	 *      calculated based on the specified total shares supply and fees percentages
	 *
	 * @param supply total shares supply
	 * @param amount number of shares to buy
	 * @param protocolFeePercent protocol fee percent
	 * @param holdersFeePercent shares holders fee percent
	 * @param subjectFeePercent protocol fee percent
	 * @return the price of the shares to buy
	 */
	function getBuyPriceAfterFee(
		uint256 supply,
		uint256 amount,
		uint256 protocolFeePercent,
		uint256 holdersFeePercent,
		uint256 subjectFeePercent
	) external pure returns(uint256);

	/**
	 * @notice The price of the `amount` of shares to sell, including all fees;
	 *      calculated based on the specified total shares supply and fees percentages
	 *
	 * @param supply total shares supply
	 * @param amount number of shares to sell
	 * @param protocolFeePercent protocol fee percent
	 * @param holdersFeePercent shares holders fee percent
	 * @param subjectFeePercent protocol fee percent
	 * @return the price of the shares to sell
	 */
	function getSellPriceAfterFee(
		uint256 supply,
		uint256 amount,
		uint256 protocolFeePercent,
		uint256 holdersFeePercent,
		uint256 subjectFeePercent
	) external pure returns(uint256);

	/**
	 * @notice Current price of the `amount` of shares to buy; calculated based on
	 *      the current total shares supply
	 *
	 * @param amount number of shares to buy
	 * @return the price of the shares to buy
	 */
	function getBuyPrice(uint256 amount) external view returns(uint256);

	/**
	 * @notice Current price of the `amount` of shares to sell; calculated based on
	 *      the current total shares supply
	 *
	 * @param amount number of shares to sell
	 * @return the price of the shares to sell
	 */
	function getSellPrice(uint256 amount) external view returns(uint256);

	/**
	 * @notice Current price of the `amount` of shares to buy, including all fees;
	 *      calculated based on the current total shares supply and fees percentages
	 *
	 * @param amount number of shares to buy
	 * @return the price of the shares to buy
	 */
	function getBuyPriceAfterFee(uint256 amount) external view returns(uint256);

	/**
	 * @notice Current price of the `amount` of shares to sell, including all fees;
	 *      calculated based on the current total shares supply and fees percentages
	 *
	 * @param amount number of shares to sell
	 * @return the price of the shares to sell
	 */
	function getSellPriceAfterFee(uint256 amount) external view returns(uint256);

	/**
	 * @notice Buy `amount` of shares. Sender has to supply `getBuyPriceAfterFee(amount)` ETH.
	 *      First share can be bought only by current subject issuer.
	 *
	 * @dev Depending on the implementation, ERC20 token payment may be required instead of ETH.
	 *      In such a case, implementation must through if ETH is sent, effectively overriding
	 *      the function definition as non-payable
	 *
	 * @param amount amount of the shares to buy
	 */
	function buyShares(uint256 amount) external payable;

	/**
	 * @notice Buy `amount` of shares in the favor of the address specified (beneficiary).
	 *      Sender has to supply `getBuyPriceAfterFee(amount)` ETH.
	 *      First share can be bought only by current subject issuer.
	 *
	 * @dev Depending on the implementation, ERC20 token payment may be required instead of ETH.
	 *      In such a case, implementation must through if ETH is sent, effectively overriding
	 *      the function definition as non-payable
	 *
	 * @param amount amount of the shares to buy
	 * @param beneficiary an address receiving the shares
	 */
	function buySharesTo(uint256 amount, address beneficiary) external payable;

	/**
	 * @notice Sell `amount` of shares. Sender gets `getSellPriceAfterFee(amount)` of ETH.
	 *      Last share cannot be sold.
	 *
	 * @dev Depending on the implementation, ERC20 token may be payed instead of ETH.
	 *
	 * @param amount amount of the shares to sell
	 */
	function sellShares(uint256 amount) external;

	/**
	 * @notice Sell `amount` of shares in the favor of the address specified (beneficiary).
	 *      The beneficiary gets `getSellPriceAfterFee(amount)` of ETH.
	 *      Last share cannot be sold.
	 *
	 * @dev Depending on the implementation, ERC20 token may be payed instead of ETH.
	 *
	 * @param amount amount of the shares to sell
	 * @param beneficiary an address receiving the funds from the sale
	 */
	function sellSharesTo(uint256 amount, address payable beneficiary) external;
}
