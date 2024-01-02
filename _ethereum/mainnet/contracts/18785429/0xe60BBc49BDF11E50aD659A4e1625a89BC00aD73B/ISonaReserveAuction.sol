// SPDX-License-Identifier: GPL-3.0

pragma solidity ^0.8.16;

//  ___  _____  _  _    __      ___  ____  ____  ____    __    __  __
// / __)(  _  )( \( )  /__\    / __)(_  _)(  _ \( ___)  /__\  (  \/  )
// \__ \ )(_)(  )  (  /(__)\   \__ \  )(   )   / )__)  /(__)\  )    (
// (___/(_____)(_)\_)(__)(__)  (___/ (__) (_)\_)(____)(__)(__)(_/\/\_)

import "./SonaTokenAuthorizor.sol";
import "./ISonaRewardToken.sol";

interface ISonaReserveAuction is ISonaTokenAuthorizor {
	/*//////////////////////////////////////////////////////////////
	/                       ERRORS
	//////////////////////////////////////////////////////////////*/

	error SonaReserveAuction_AlreadyCanceled();
	error SonaReserveAuction_AlreadyListed();
	error SonaReserveAuction_NotAuthorized();
	error SonaReserveAuction_TransferFailed();
	error SonaReserveAuction_BidTooLow();
	error SonaReserveAuction_AlreadySettled();
	error SonaReserveAuction_Duplicate();
	error SonaReserveAuction_ReservePriceCannotBeZero();
	error SonaReserveAuction_DurationOutOfBounds();
	error SonaReserveAuction_InvalidAddress();
	error SonaReserveAuction_InvalidCurrency();
	error SonaReserveAuction_InvalidTokenIds();
	error SonaReserveAuction_InvalidAuction();
	error SonaReserveAuction_AuctionEnded();
	error SonaReserveAuction_AuctionIsLive();
	error SonaReserveAuction_NoMetadata();

	/*//////////////////////////////////////////////////////////////
	/                       EVENTS
	//////////////////////////////////////////////////////////////*/

	/// @dev Emitted when a new auction is created
	/// @param tokenId The id of the token
	event ReserveAuctionCreated(uint256 indexed tokenId);

	/// @dev Emitted when a new auction is canceled
	/// @param tokenId The id of the token
	event ReserveAuctionCanceled(uint256 indexed tokenId);

	/// @dev Emitted when a new auction is settled
	/// @param tokenId The id of the token
	event ReserveAuctionSettled(uint256 indexed tokenId);

	/// @dev Emitted when the reserve price of an auction is updated
	/// @param tokenId The id of the token
	/// @param auction The auction attributes
	event ReserveAuctionPriceUpdated(uint256 indexed tokenId, Auction auction);

	/// @dev Emitted when a new bid is placed
	/// @param tokenId The id of the token
	event ReserveAuctionBidPlaced(
		uint256 indexed tokenId,
		uint256 indexed amount
	);

	/// @dev Emitted when the currency of an auction is updated
	/// @param tokenId The id of the token
	/// @param auction The auction attributes
	event ReserveAuctionPriceAndCurrencyUpdated(
		uint256 indexed tokenId,
		Auction auction
	);

	/// @dev Emitted when the payout address is updated. The address can be set to zero to payout the token holder
	/// @param tokenId The id of the token updated
	/// @param payout The payout address change
	event PayoutAddressUpdated(uint256 indexed tokenId, address payout);

	/*//////////////////////////////////////////////////////////////
	/                        STRUCTS
	//////////////////////////////////////////////////////////////*/

	struct Auction {
		// @dev The minimum reserve price to be met
		uint256 reservePrice;
		// @dev The ending time of the auction (_AUCTION_DURATION after the first bid)
		uint256 endingTime;
		// @dev The current bid
		uint256 currentBidAmount;
		// @dev The address of the seller
		address payable trackSeller;
		// @dev The current highest bidder
		address payable currentBidder;
		// @dev Currency for the auction
		address currency;
		// @dev the length the auction is set to run for
		uint32 duration;
		// @dev Arweave Bundle info containing collector token metadata and auction payout address
		ISonaRewardToken.TokenMetadata tokenMetadata;
	}

	/*//////////////////////////////////////////////////////////////
	/                         FUNCTIONS
	//////////////////////////////////////////////////////////////*/

	function createReserveAuction(
		ISonaRewardToken.TokenMetadata[] calldata _metadatas,
		Signature calldata _signature,
		address _currencyAddress,
		uint256 _reservePrice,
		uint32 _duration
	) external;

	function cancelReserveAuction(uint256 _tokenId) external;

	function settleReserveAuction(uint256 _tokenId) external;

	function updateReserveAuctionPrice(
		uint256 _tokenId,
		uint256 _reservePrice
	) external;

	function createBid(uint256 _tokenId, uint256 _bidAmount) external payable;

	function getAuction(uint256 _tokenId) external view returns (Auction memory);
}
