// SPDX-License-Identifier: GPL-3.0

pragma solidity ^0.8.16;

//  ___  _____  _  _    __      ___  ____  ____  ____    __    __  __
// / __)(  _  )( \( )  /__\    / __)(_  _)(  _ \( ___)  /__\  (  \/  )
// \__ \ )(_)(  )  (  /(__)\   \__ \  )(   )   / )__)  /(__)\  )    (
// (___/(_____)(_)\_)(__)(__)  (___/ (__) (_)\_)(____)(__)(__)(_/\/\_)

import "./ISonaReserveAuction.sol";
import "./SonaTokenAuthorizor.sol";
import "./ISplitMain.sol";
import "./Initializable.sol";
import "./SonaAdmin.sol";
import "./IERC721Upgradeable.sol";
import "./IERC20Upgradeable.sol";
import "./ISonaRewardToken.sol";
import "./AddressableTokenId.sol";
import "./IWETH.sol";
import "./ZeroCheck.sol";

/// @title SonaReserveAuction
/// @author @SonaEngineering
/// @notice The primary auction logic for SonaRewardTokens
contract SonaReserveAuction is
	ISonaReserveAuction,
	Initializable,
	SonaAdmin,
	SonaTokenAuthorizor
{
	using AddressableTokenId for uint256;
	using ZeroCheck for address;
	using ZeroCheck for address payable;

	/*//////////////////////////////////////////////////////////////
	/                         IMMUTABLES
	//////////////////////////////////////////////////////////////*/

	// @dev The minimum duration an auction can run
	uint256 public immutable AUCTION_DURATION_MINIMUM;

	/*//////////////////////////////////////////////////////////////
	/                         CONSTANTS
	//////////////////////////////////////////////////////////////*/

	// @dev The duration you may extend an auction by if you meet the price threshold. (15 minutes)
	uint256 private constant _AUCTION_EXTENSION_DURATION = 15 minutes;
	// @dev The minimum price threshold you must meet to extend an auction. (5%)
	uint256 private constant _AUCTION_EXTENSION_BPS = 500;
	// @dev The redistribution fee charged to the seller (5%)
	uint256 private constant _AUCTION_REDISTRIBUTION_FEE_BPS = 500;
	// @dev The treasury fee charged to the seller (2%)
	uint256 private constant _AUCTION_TREASURY_FEE_BPS = 200;

	/*//////////////////////////////////////////////////////////////
	/                         STATE
	//////////////////////////////////////////////////////////////*/

	// @dev The recipient of the treasury fee
	address private _treasuryFeeRecipient;
	// @dev The recipient of the redistribution fee
	address private _redistributionFeeRecipient;
	// @dev The instance of the rewardToken contract
	ISonaRewardToken public rewardToken;
	/// @dev splits contract to execute distributions on
	ISplitMain public splitMain;
	// @dev Weth
	IWETH private _weth;

	/*//////////////////////////////////////////////////////////////
	/                          MAPPINGS
	//////////////////////////////////////////////////////////////*/

	mapping(uint256 => Auction) public auctions;
	mapping(bytes32 => bool) private _uriExists;

	/*//////////////////////////////////////////////////////////////
	/                         MODIFIERS
	//////////////////////////////////////////////////////////////*/

	/// @dev Modifier that ensures the calling wallet has the admin role or is the specified owner
	modifier onlySonaAdminOrApprovedTokenOperator(uint256 _tokenId) {
		if (_tokenId.getAddress() != msg.sender && !isSonaAdmin(msg.sender))
			revert SonaReserveAuction_NotAuthorized();
		_;
	}

	/// @dev recover signature and ensure it matches `_authorizor`
	modifier bundlesAuthorized(
		ISonaRewardToken.TokenMetadata[] calldata _metadatas,
		Signature calldata _signature
	) {
		if (!_verify(_metadatas, _signature.v, _signature.r, _signature.s))
			revert SonaAuthorizor_InvalidSignature();
		_;
	}

	/*//////////////////////////////////////////////////////////////
								Constructor
	//////////////////////////////////////////////////////////////*/
	constructor(uint256 _base_duration) {
		AUCTION_DURATION_MINIMUM = _base_duration;
		_disableInitializers();
	}

	/*//////////////////////////////////////////////////////////////
	/                     PUBLIC FUNCTIONS
	//////////////////////////////////////////////////////////////*/

	/// @notice initialize state variables
	/// @dev invoked in contructor for proxy contracts
	/// @param treasuryFeeRecipient_ the location of protocol funds
	/// @param redistributionFeeRecipient_ the location of the funds
	/// 				distributed back to artists
	/// @param authorizor_ the address that signs off that a tracks has met all licensing agreements
	/// @param _rewardToken The NFTs minted by this contract
	/// @param _splitMain The splits fork that shares auction proceeds with collaborators
	/// @param _eoaAdmin The AccessControl admin
	/// @param weth_ address of the WETH9 implementation
	function initialize(
		address treasuryFeeRecipient_,
		address redistributionFeeRecipient_,
		address authorizor_,
		ISonaRewardToken _rewardToken,
		ISplitMain _splitMain,
		address _eoaAdmin,
		IWETH weth_
	) public initializer {
		// Setup role for contract creator, otherwise subsequent checks will not work
		_setupRole(_ADMIN_ROLE, _eoaAdmin);
		_setRoleAdmin(_ADMIN_ROLE, _ADMIN_ROLE);

		_setConfig(
			treasuryFeeRecipient_,
			redistributionFeeRecipient_,
			authorizor_,
			_rewardToken,
			_splitMain,
			weth_
		);

		_DOMAIN_SEPARATOR = keccak256(
			abi.encode(
				_EIP712DOMAIN_TYPEHASH,
				keccak256("SonaReserveAuction"), // name
				keccak256(abi.encodePacked(_getInitializedVersion() + uint8(48))), // version
				block.chainid, // chain ID
				address(this) // verifying contract
			)
		);
	}

	/// @notice Creates a new auction.
	/// @dev Creating a reserve auction does not start it.
	/// Auctions are started once a bid of the reserve price or higher is placed.
	/// @param _currencyAddress The address of the currency bids will be in.
	/// @param _reservePrice The reserve price of the auction.
	/// @param _additionalDuration The duration of the auction, in seconds in addition to the minmimum duration of 1 day
	function createReserveAuction(
		ISonaRewardToken.TokenMetadata[] calldata _metadatas,
		Signature calldata _signature,
		address _currencyAddress,
		uint256 _reservePrice,
		uint32 _additionalDuration
	) external bundlesAuthorized(_metadatas, _signature) {
		// Check that the reserve price is not zero. No free auctions
		if (_reservePrice == 0) {
			revert SonaReserveAuction_ReservePriceCannotBeZero();
		}
		if (_metadatas.length == 2) {
			if (
				_metadatas[0].tokenId % 2 != 0 ||
				_metadatas[0].tokenId + 1 != _metadatas[1].tokenId
			) revert SonaReserveAuction_InvalidTokenIds();

			_createReserveAuction(
				_metadatas[1],
				_currencyAddress,
				_reservePrice,
				_additionalDuration
			);

			if (!rewardToken.tokenIdExists(_metadatas[0].tokenId))
				rewardToken.mint(
					_metadatas[0].tokenId.getAddress(),
					_metadatas[0].tokenId,
					_metadatas[0].metadataId,
					_metadatas[0].payout
				);
		} else if (_metadatas.length == 1) {
			if (_metadatas[0].tokenId % 2 != 1)
				revert SonaReserveAuction_InvalidTokenIds();
			_createReserveAuction(
				_metadatas[0],
				_currencyAddress,
				_reservePrice,
				_additionalDuration
			);
		} else {
			revert SonaReserveAuction_NoMetadata();
		}
	}

	/// @dev Public function to settle the reseerve auction
	/// @param _tokenId The ID of the token.
	function settleReserveAuction(uint256 _tokenId) external {
		_settleReserveAuction(_tokenId);
	}

	/// @notice Settle the reserve auction and distribute a split
	/// @dev This function is secured on the Splits-side and will revert if the
	/// 			payout address is not a registered split
	/// @param _tokenId The ID of the token.
	/// @param _accounts The list of accounts in the configured split
	/// @param _percentAllocations The list of proportional amounts in the configured split
	function settleReserveAuctionAndDistributePayout(
		uint256 _tokenId,
		address[] calldata _accounts,
		uint32[] calldata _percentAllocations
	) external {
		address payout = auctions[_tokenId].tokenMetadata.payout;
		address currency = auctions[_tokenId].currency;
		_settleReserveAuction(_tokenId);
		if (currency.isZero()) {
			splitMain.distributeETH(payout, _accounts, _percentAllocations);
		} else {
			splitMain.distributeERC20(
				payout,
				IERC20(currency),
				_accounts,
				_percentAllocations
			);
		}
	}

	/// @notice Public function to cancel the reserve auction. It can only be
	///					invoked before a bid is placed
	/// @param _tokenId The ID of the token.
	function cancelReserveAuction(
		uint256 _tokenId
	) external onlySonaAdminOrApprovedTokenOperator(_tokenId) {
		Auction storage auction = auctions[_tokenId];

		if (auction.reservePrice == 0) {
			revert SonaReserveAuction_InvalidAuction();
		}

		// Can't settle an auction that can still be bidded on
		if (auction.endingTime > block.timestamp) {
			revert SonaReserveAuction_AuctionIsLive();
		}

		// Can't cancel an auction that is finished but hasn't been settled
		if (auction.endingTime != 0 && auction.endingTime <= block.timestamp) {
			revert SonaReserveAuction_AuctionEnded();
		}

		delete auctions[_tokenId];

		emit ReserveAuctionCanceled({ tokenId: _tokenId });
	}

	/// @notice Public function to update the reserve price of the auction.
	///					It can only be invoked before a bid is placed
	/// @param _tokenId The ID of the token.
	/// @param _reservePrice The reserve price to be updated to
	function updateReserveAuctionPrice(
		uint256 _tokenId,
		uint256 _reservePrice
	) external onlySonaAdminOrApprovedTokenOperator(_tokenId) {
		Auction storage auction = auctions[_tokenId];

		if (_reservePrice == 0 || auction.reservePrice == 0) {
			revert SonaReserveAuction_ReservePriceCannotBeZero();
		}

		// Can't settle an auction that can still be bidded on
		if (auction.endingTime > block.timestamp) {
			revert SonaReserveAuction_AuctionIsLive();
		}

		auction.reservePrice = uint256(_reservePrice);

		emit ReserveAuctionPriceUpdated({ tokenId: _tokenId, auction: auction });
	}

	/// @notice set the payout address to `_payout` for auction with id `_tokenId`
	/// @dev setting the address to address(0) resets the payout address to the seller's address
	/// @param _tokenId The artist tokenId used as the identifier for the auction
	/// @param _payout The address to receive NFT sale proceeds and future reward claims
	function updateArtistPayoutAddress(
		uint256 _tokenId,
		address payable _payout
	) external onlySonaAdminOrApprovedTokenOperator(_tokenId) {
		Auction storage auction = auctions[_tokenId];

		if (auction.reservePrice == 0) {
			revert SonaReserveAuction_InvalidAuction();
		}

		auction.tokenMetadata.payout = _payout;

		emit PayoutAddressUpdated(_tokenId, _payout);
	}

	/// @dev Public function to bid on a reserve auction
	/// @param _tokenId The ID of the token.
	/// @param _bidAmount The amount of the bid if the currency is not ETH
	// solhint-disable-next-line code-complexity
	function createBid(uint256 _tokenId, uint256 _bidAmount) external payable {
		uint256 attemptedBid;

		// If the currency ETH, the bid amount is the msg.value
		// Else, the bid amount is the _bidAmount
		if (msg.value > 0) {
			attemptedBid = msg.value;
		} else {
			if (_bidAmount == 0) {
				revert SonaReserveAuction_BidTooLow();
			}

			attemptedBid = _bidAmount;
		}

		Auction storage auction = auctions[_tokenId];

		if (
			(msg.value > 0 && auction.currency.isNotZero()) ||
			(auction.currency.isZero() && msg.value == 0)
		) {
			revert SonaReserveAuction_InvalidCurrency();
		}

		// if reserve price is 0, auction has not been created
		if (auction.reservePrice == 0) {
			revert SonaReserveAuction_InvalidAuction();
		}

		// if attempted bid is less than the reserve price, revert
		if (attemptedBid < auction.reservePrice) {
			revert SonaReserveAuction_BidTooLow();
		}

		// get current ending time
		uint256 currentEndingTime = auction.endingTime;

		// if current ending time is 0, a bid has not been placed yet
		if (currentEndingTime == 0) {
			// save ending time immediately to prevent unintended re-entrancy
			unchecked {
				currentEndingTime =
					block.timestamp +
					auction.duration +
					AUCTION_DURATION_MINIMUM;
			}
			auction.endingTime = currentEndingTime;
			auction.currentBidder = payable(msg.sender);
			auction.currentBidAmount = attemptedBid;

			// transfer ERC20 bid amount to this contract
			if (auction.currency.isNotZero()) {
				if (
					!IERC20(auction.currency).transferFrom(
						msg.sender,
						address(this),
						attemptedBid
					)
				) revert SonaReserveAuction_TransferFailed();
			}

			//  else, a bid has been placed
		} else {
			// if the ending time has passed, revert
			if (currentEndingTime < block.timestamp) {
				revert SonaReserveAuction_AuctionEnded();
				// if the ending time has not passed, continue with bid logic
			} else {
				// if the bid is 5% higher than the current bid, extend the duration
				// and refund the bidder; otherwise revert
				if (attemptedBid >= ((auction.currentBidAmount * 105) / 100)) {
					address payable previousBidder = auction.currentBidder;
					uint256 previousBidAmount = auction.currentBidAmount;

					auction.currentBidder = payable(msg.sender);
					auction.currentBidAmount = attemptedBid;

					// extend the auction 15 minutes from the current timestamp
					// if fewer than 15 minutes remain before the endingTime
					if (
						(currentEndingTime - block.timestamp) < _AUCTION_EXTENSION_DURATION
					) {
						auction.endingTime = block.timestamp + _AUCTION_EXTENSION_DURATION;
					}

					// Refund previous bidder
					_sendCurrencyToParticipant(
						previousBidder,
						previousBidAmount,
						auction.currency
					);

					// transfer bid amount to this contract
					if (auction.currency.isNotZero()) {
						if (
							!IERC20(auction.currency).transferFrom(
								msg.sender,
								address(this),
								auction.currentBidAmount
							)
						) revert SonaReserveAuction_TransferFailed();
					}

					// if the bid is lower than the current bid, revert
				} else {
					revert SonaReserveAuction_BidTooLow();
				}
			}
		}

		emit ReserveAuctionBidPlaced({ tokenId: _tokenId, amount: attemptedBid });
	}

	/// @dev Public function to fetch an auction
	/// @param _tokenId The ID of the token.
	function getAuction(uint256 _tokenId) external view returns (Auction memory) {
		return auctions[_tokenId];
	}

	/// @dev set state used by the auction process
	/// @param treasuryFeeRecipient_ the destination for Sona Treasury funds
	/// @param redistributionFeeRecipient_  the destination for artist pool funds
	/// @param authorizor_ the address of the auction validator
	/// @param _rewardToken the SonaRewardToken instance
	/// @param _splitMain the SonaSplits instance
	/// @param weth_ the weth instance
	function setConfig(
		address treasuryFeeRecipient_,
		address redistributionFeeRecipient_,
		address authorizor_,
		ISonaRewardToken _rewardToken,
		ISplitMain _splitMain,
		IWETH weth_
	) public onlySonaAdmin {
		_setConfig(
			treasuryFeeRecipient_,
			redistributionFeeRecipient_,
			authorizor_,
			_rewardToken,
			_splitMain,
			weth_
		);
	}

	/*//////////////////////////////////////////////////////////////
	/                    PRIVATE FUNCTIONS
	//////////////////////////////////////////////////////////////*/

	function _createReserveAuction(
		ISonaRewardToken.TokenMetadata calldata _bundle,
		address _currencyAddress,
		uint256 _reservePrice,
		uint32 _additionalDuration
	) internal {
		if (auctions[_bundle.tokenId].reservePrice > 0)
			revert SonaReserveAuction_AlreadyListed();

		_ensureBundleIsUnique(_bundle);

		auctions[_bundle.tokenId].reservePrice = _reservePrice;
		auctions[_bundle.tokenId].duration = _additionalDuration;
		auctions[_bundle.tokenId].trackSeller = payable(
			_bundle.tokenId.getAddress()
		);

		// Note: If the currency address is 0x0/address(0), bids are made in ETH
		auctions[_bundle.tokenId].currency = _currencyAddress;
		auctions[_bundle.tokenId].tokenMetadata = _bundle;

		emit ReserveAuctionCreated({ tokenId: _bundle.tokenId });
	}

	/// @dev Internal function to settle the reserve auction
	/// @param _tokenId The ID of the token.
	function _settleReserveAuction(uint256 _tokenId) private {
		Auction storage auction = auctions[_tokenId];

		if (auction.reservePrice == 0) {
			revert SonaReserveAuction_InvalidAuction();
		}

		// Can't settle an auction that can still be bidded on
		if (auction.endingTime > block.timestamp) {
			revert SonaReserveAuction_AuctionIsLive();
		}

		// reduce sloads
		address currency = auction.currency;

		// Mint reward token to buyer
		rewardToken.mint(
			auction.currentBidder,
			_tokenId,
			auction.tokenMetadata.metadataId,
			// the tokenMetadata payout address is set for auction proceeds, not for the collector.
			// Therefore, this address is set as zero.
			payable(address(0))
		);

		// Send redistribution fee to the redistribution fee recipient

		uint256 redistributionFeeAmount;
		uint256 treasuryFeeAmount;
		uint256 sellerProceedsAmount;
		uint256 totalFeesAmount;
		// solhint-disable-next-line no-inline-assembly
		assembly {
			// currentBidAmount needs an offset as it's the 3rd variable in the struct
			let currentBidAmountPointer := add(auction.slot, 2)

			// Load the currentBidAmount
			let currentBidAmount := sload(currentBidAmountPointer)

			// prevent div by 0
			if gt(currentBidAmount, 0) {
				// Calculate the redistribution fee amount
				redistributionFeeAmount := div(
					mul(currentBidAmount, _AUCTION_REDISTRIBUTION_FEE_BPS),
					10000
				)

				// Calculate the treasury fee amount
				treasuryFeeAmount := div(
					mul(currentBidAmount, _AUCTION_TREASURY_FEE_BPS),
					10000
				)

				// Total fees
				totalFeesAmount := add(redistributionFeeAmount, treasuryFeeAmount)

				// Calculate the seller proceeds amount
				sellerProceedsAmount := sub(currentBidAmount, totalFeesAmount)
			}
		}

		// Send the currency to the seller or the seller's delegated address
		address payable payoutAddress = _getPayoutAddress(auction.tokenMetadata);

		// Remove from map and prevent reentrancy here
		delete auctions[_tokenId];

		// Send the currency to the treasury fee recipient
		_handleTokenTransfer(_treasuryFeeRecipient, treasuryFeeAmount, currency);

		// Send the currency to the redistribution fee recipient
		_handleTokenTransfer(
			_redistributionFeeRecipient,
			redistributionFeeAmount,
			currency
		);

		_sendCurrencyToParticipant(payoutAddress, sellerProceedsAmount, currency);

		emit ReserveAuctionSettled({ tokenId: _tokenId });
	}

	function _ensureBundleIsUnique(
		ISonaRewardToken.TokenMetadata calldata _bundle
	) internal {
		if (
			_uriExists[keccak256(bytes(_bundle.metadataId))] ||
			rewardToken.tokenIdExists(_bundle.tokenId)
		) revert SonaReserveAuction_Duplicate();
		_uriExists[keccak256(bytes(_bundle.metadataId))] = true;
	}

	function _handleTokenTransfer(
		address _to,
		uint256 _amount,
		address _currency
	) internal {
		if (_currency.isZero()) {
			_wrapAndSendEth(_to, _amount);
		} else {
			// Send currency
			_transferTokenOut(_to, _amount, _currency);
		}
	}

	function _sendCurrencyToParticipant(
		address payable _to,
		uint256 _amount,
		address _currency
	) internal {
		if (_currency.isZero()) {
			if (!_to.send(_amount)) {
				_wrapAndSendEth(_to, _amount);
			}
		} else {
			// Send currency
			_transferTokenOut(_to, _amount, _currency);
		}
	}

	function _wrapAndSendEth(address _to, uint256 _amount) internal {
		// Wrap refund in weth
		_weth.deposit{ value: _amount }();
		// Send weth
		_transferTokenOut(_to, _amount, address(_weth));
	}

	function _transferTokenOut(
		address _to,
		uint256 _amount,
		address _currency
	) internal {
		if (!IERC20(_currency).transfer(_to, _amount))
			revert SonaReserveAuction_TransferFailed();
	}

	function _getPayoutAddress(
		ISonaRewardToken.TokenMetadata storage _bundle
	) internal view returns (address payable payoutAddress) {
		address payable payout = _bundle.payout;
		return payout.isNotZero() ? payout : payable(_bundle.tokenId.getAddress());
	}

	function _setConfig(
		address treasuryFeeRecipient_,
		address redistributionFeeRecipient_,
		address authorizor_,
		ISonaRewardToken _rewardToken,
		ISplitMain _splitMain,
		IWETH weth_
	) internal {
		treasuryFeeRecipient_.revertIfZero(
			SonaReserveAuction_InvalidAddress.selector
		);
		_treasuryFeeRecipient = treasuryFeeRecipient_;

		redistributionFeeRecipient_.revertIfZero(
			SonaReserveAuction_InvalidAddress.selector
		);
		_redistributionFeeRecipient = redistributionFeeRecipient_;

		authorizor_.revertIfZero(SonaReserveAuction_InvalidAddress.selector);
		_authorizor = authorizor_;

		_weth = weth_;

		splitMain = _splitMain;

		address(_rewardToken).revertIfZero(
			SonaReserveAuction_InvalidAddress.selector
		);
		rewardToken = _rewardToken;
	}
}
