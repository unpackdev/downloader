pragma solidity >=0.8.0 <0.9.0;

import "./MarsBaseCommon.sol";

interface IMarsbaseExchange {

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