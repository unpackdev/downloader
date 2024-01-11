pragma solidity >=0.8.0 <0.9.0;

import "./MarsBaseCommon.sol";

interface IMarsbaseExchange {
	/// Emitted when an offer is created
    event OfferCreated(
        uint256 offerId,
        address sender,
        uint256 blockTimestamp,
        MarsBaseCommon.MBOffer offer
    );
	
	/// Emitted when an offer has it's parameters or capabilities modified
    event OfferModified(
        uint256 offerId,
        address sender,
        uint256 blockTimestamp,
        MarsBaseCommon.OfferParams offerParameters
    );

    /// Emitted when an offer is accepted.
    /// This includes partial transactions, where the whole offer is not bought out and those where the exchange is not finallized immediatley.
    event OfferAccepted(
        uint256 offerId,
        address sender,
        uint256 blockTimestamp,
        uint256 amountAliceReceived,
        uint256 amountBobReceived,
        address tokenAddressAlice,
        address tokenAddressBob,
        MarsBaseCommon.OfferType offerType,
        uint256 feeAlice,
        uint256 feeBob
    );

    /// Emitted when the offer is cancelled either by the creator or because of an unsuccessful auction
    event OfferCancelled(
        uint256 offerId,
        address sender,
        uint256 blockTimestamp
    );

    event OfferClosed(
        uint256 offerId,
        MarsBaseCommon.OfferCloseReason reason,
        uint256 blockTimestamp
    );

    event ContractMigrated();

    /// Emitted when a buyer cancels their bid for a offer were tokens have not been exchanged yet and are still held by the contract.
    event BidCancelled(uint256 offerId, address sender, uint256 blockTimestamp);

    /// Emitted only for testing usage
    event Log(uint256 log);
	
    struct MBAddresses {
        address offersContract;
        address minimumOffersContract;
    }

	function setCommissionAddress(address wallet) external;
	function setExchangerAddress(address exchangeContract) external;
	function setMinimumFee(uint256 _minimumFee) external;
	function getMinimumFee() external view returns (uint256);
	function setNextOfferId(uint256 _nextOfferId) external;
	function getOffer(uint256 offerId) external view returns (MarsBaseCommon.MBOffer memory);
	function getNextOfferId() external view returns (uint256);
	function getOwner() external view returns (address);
	function changeOwner(address newOwner) external;
	function getAllOffers() external view returns (MarsBaseCommon.MBOffer[] memory);
	function createOffer(
        address tokenAlice,
        address[] calldata tokenBob,
        uint256 amountAlice,
        uint256[] calldata amountBob,
        MarsBaseCommon.OfferParams calldata offerParameters
    ) external payable;
	function cancelOffer(uint256 offerId) external payable;
	function price(
        uint256 amountAlice,
        uint256 offerAmountAlice,
        uint256 offerAmountBob
    ) external pure returns (uint256);
	function acceptOffer(
        uint256 offerId,
        address tokenBob,
        uint256 amountBob
    ) external payable;
	function changeOfferParams(
        uint256 offerId,
        address[] calldata tokenBob,
        uint256[] calldata amountBob,
        MarsBaseCommon.OfferParams calldata offerParameters
    ) external;
	function cancelBid(uint256 offerId) external;
	function cancelExpiredOffers() external payable;
	function migrateContract() external payable;
	function lockContract() external;
	function cancelOffers(uint256 from, uint256 to) external payable;
}