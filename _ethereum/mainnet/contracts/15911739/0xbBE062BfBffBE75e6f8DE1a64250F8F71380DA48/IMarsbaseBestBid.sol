pragma solidity >=0.8.0 <0.9.0;

interface IMarsbaseBestBid
{
	struct BBBid
	{
		uint256 offerId;
		uint256 bidIdx;

		address bobAddress;

		address tokenBob;
		uint256 amountBob;
		// uint256 depositedBob;
	}
	struct BBOffer
	{
		bool active;
		uint256 id;

		address aliceAddress;

		BBOfferParams params;

		uint256 totalBidsCount;
		uint256 activeBidsCount;
	}
	struct BBOfferParams
	{
		address tokenAlice;
		uint256 amountAlice;
		// uint256 depositedAlice;

		address[] tokensBob;

		uint256 feeAlice;
		uint256 feeBob;

		// uint256 deadline;
	}

	event OfferCreated(
		uint256 indexed id,
        address indexed aliceAddress,
		address indexed tokenAlice,
        BBOfferParams params
	);
	event BidCreated(
		uint256 indexed offerId,
		address indexed bobAddress,
		address indexed tokenBob,
		uint256 bidIdx,
		bytes32 bidId,
		BBBid bid
	);
	enum OfferCloseReason {
		Success,
		CancelledBySeller,
		ContractMigrated
	}
	enum BidCancelReason {
		OfferClosed,
		CancelledByBidder,
		ContractMigrated
	}
	event OfferClosed(
		uint256 indexed id,
		address indexed aliceAddress,
		OfferCloseReason indexed reason,
		BBOffer offer
	);
	event BidAccepted(
		uint256 indexed id,
		address indexed aliceAddress,
		uint256 aliceReceivedTotal,
		uint256 aliceFeeTotal,
		uint256 bobReceivedTotal,
		uint256 bobFeeTotal,
		BBOffer offer,
		BBBid bid
	);
	event BidCancelled(
		uint256 indexed offerId,
		address indexed bobAddress,
		address indexed tokenBob,
		BidCancelReason reason,
		uint256 bidIdx,
		bytes32 bidId,
		BBBid bid
	);

	function createOffer(BBOfferParams calldata offer) external payable;
	function createBid(uint256 offerId, address tokenBob, uint256 amountBob) external payable;
	function acceptBid(uint256 offerId, uint256 bidIdx) external;
	function cancelBid(uint256 offerId, uint256 bidIdx) external;
	function cancelOffer(uint256 offerId) external;

	function getActiveOffers() external returns (BBOffer[] memory);
}
