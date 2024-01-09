// SPDX-License-Identifier: MIT OR Apache-2.0

pragma solidity ^0.8.0;

import "./SafeMathUpgradeableExchange.sol";
import "./Initializable.sol";
import "./IERC721Upgradeable.sol";

import "./BlocksportTreasuryNode.sol";
import "./Constants.sol";
import "./NFTMarketCore.sol";
import "./NFTMarketCreators.sol";
import "./SendValueWithFallbackWithdraw.sol";

/**
 * @notice A mixin to distribute funds when an NFT is sold.
 */
abstract contract NFTMarketFees is
    Constants,
    Initializable,
    BlocksportTreasuryNode,
    NFTMarketCore,
    NFTMarketCreators,
    SendValueWithFallbackWithdraw
{
    using SafeMathUpgradeableExchange for uint256;

    event MarketFeesUpdated(
        uint256 primaryBlocksportFeeBasisPoints,
        uint256 secondaryBlocksportFeeBasisPoints,
        uint256 secondaryCreatorFeeBasisPoints
    );

    uint256 private _primaryBlocksportFeeBasisPoints;
    uint256 private _secondaryBlocksportFeeBasisPoints;
    uint256 private _secondaryCreatorFeeBasisPoints;

    mapping(address => mapping(uint256 => bool))
        private nftContractToTokenIdToFirstSaleCompleted;

    /**
     * @notice Returns true if the given NFT has not been sold in this market previously and is being sold by the creator.
     */
    function getIsPrimary(address nftContract, uint256 tokenId)
        public
        view
        returns (bool)
    {
        return
            _getIsPrimary(
                nftContract,
                tokenId,
                _getCreator(nftContract, tokenId),
                _getSellerFor(nftContract, tokenId)
            );
    }

    /**
     * @dev A helper that determines if this is a primary sale given the current seller.
     * This is a minor optimization to use the seller if already known instead of making a redundant lookup call.
     */
    function _getIsPrimary(
        address nftContract,
        uint256 tokenId,
        address creator,
        address seller
    ) private view returns (bool) {
        return
            !nftContractToTokenIdToFirstSaleCompleted[nftContract][tokenId] &&
            creator == seller;
    }

    /**
     * @notice Returns the current fee configuration in basis points.
     */
    function getFeeConfig()
        public
        view
        returns (
            uint256 primaryBlocksportFeeBasisPoints,
            uint256 secondaryBlocksportFeeBasisPoints,
            uint256 secondaryCreatorFeeBasisPoints
        )
    {
        return (
            _primaryBlocksportFeeBasisPoints,
            _secondaryBlocksportFeeBasisPoints,
            _secondaryCreatorFeeBasisPoints
        );
    }

    /**
     * @notice Returns how funds will be distributed for a sale at the given price point.
     * @dev This could be used to present exact fee distributing on listing or before a bid is placed.
     */
    function getFees(
        address nftContract,
        uint256 tokenId,
        uint256 price
    )
        public
        view
        returns (
            uint256 blocksportFee,
            uint256 creatorSecondaryFee,
            uint256 ownerRev
        )
    {
        (blocksportFee, , creatorSecondaryFee, , ownerRev) = _getFees(
            nftContract,
            tokenId,
            _getSellerFor(nftContract, tokenId),
            price
        );
    }

    /**
     * @dev Calculates how funds should be distributed for the given sale details.
     * If this is a primary sale, the creator revenue will appear as `ownerRev`.
     */
    function _getFees(
        address nftContract,
        uint256 tokenId,
        address payable seller,
        uint256 price
    )
        private
        view
        returns (
            uint256 blocksportFee,
            address payable creatorSecondaryFeeTo,
            uint256 creatorSecondaryFee,
            address payable ownerRevTo,
            uint256 ownerRev
        )
    {
        // The tokenCreatorPaymentAddress replaces the creator as the fee recipient.
        (
            address payable creator,
            address payable tokenCreatorPaymentAddress
        ) = _getCreatorAndPaymentAddress(nftContract, tokenId);
        uint256 blocksportFeeBasisPoints;
        if (_getIsPrimary(nftContract, tokenId, creator, seller)) {
            blocksportFeeBasisPoints = _primaryBlocksportFeeBasisPoints;
            // On a primary sale, the creator is paid the remainder via `ownerRev`.
            ownerRevTo = tokenCreatorPaymentAddress;
        } else {
            blocksportFeeBasisPoints = _secondaryBlocksportFeeBasisPoints;

            // If there is no creator then funds go to the seller instead.
            if (tokenCreatorPaymentAddress != address(0)) {
                // SafeMath is not required when dividing by a constant value > 0.
                creatorSecondaryFee =
                    price.mul(_secondaryCreatorFeeBasisPoints) /
                    BASIS_POINTS;
                creatorSecondaryFeeTo = tokenCreatorPaymentAddress;
            }

            if (seller == creator) {
                ownerRevTo = tokenCreatorPaymentAddress;
            } else {
                ownerRevTo = seller;
            }
        }
        // SafeMath is not required when dividing by a constant value > 0.
        blocksportFee = price.mul(blocksportFeeBasisPoints) / BASIS_POINTS;
        ownerRev = price.sub(blocksportFee).sub(creatorSecondaryFee);
    }

    /**
     * @dev Distributes funds to blocksport, creator, and NFT owner after a sale.
     */
    function _distributeFunds(
        address nftContract,
        uint256 tokenId,
        address payable seller,
        uint256 price
    )
        internal
        returns (
            uint256 blocksportFee,
            uint256 creatorFee,
            uint256 ownerRev
        )
    {
        address payable creatorFeeTo;
        address payable ownerRevTo;
        (
            blocksportFee,
            creatorFeeTo,
            creatorFee,
            ownerRevTo,
            ownerRev
        ) = _getFees(nftContract, tokenId, seller, price);

        // Anytime fees are distributed that indicates the first sale is complete,
        // which will not change state during a secondary sale.
        // This must come after the `_getFees` call above as this state is considered in the function.
        nftContractToTokenIdToFirstSaleCompleted[nftContract][tokenId] = true;

        _sendValueWithFallbackWithdrawWithLowGasLimit(
            getBlocksportTreasury(),
            blocksportFee
        );
        _sendValueWithFallbackWithdrawWithMediumGasLimit(
            creatorFeeTo,
            creatorFee
        );
        _sendValueWithFallbackWithdrawWithMediumGasLimit(ownerRevTo, ownerRev);
    }

    /**
     * @notice Allows blocksport to change the market fees.
     */
    function _updateMarketFees(
        uint256 primaryBlocksportFeeBasisPoints,
        uint256 secondaryBlocksportFeeBasisPoints,
        uint256 secondaryCreatorFeeBasisPoints
    ) internal {
        require(
            primaryBlocksportFeeBasisPoints < BASIS_POINTS,
            "NFTMarketFees: Fees >= 100%"
        );
        require(
            secondaryBlocksportFeeBasisPoints.add(
                secondaryCreatorFeeBasisPoints
            ) < BASIS_POINTS,
            "NFTMarketFees: Fees >= 100%"
        );
        _primaryBlocksportFeeBasisPoints = primaryBlocksportFeeBasisPoints;
        _secondaryBlocksportFeeBasisPoints = secondaryBlocksportFeeBasisPoints;
        _secondaryCreatorFeeBasisPoints = secondaryCreatorFeeBasisPoints;

        emit MarketFeesUpdated(
            primaryBlocksportFeeBasisPoints,
            secondaryBlocksportFeeBasisPoints,
            secondaryCreatorFeeBasisPoints
        );
    }

    uint256[1000] private ______gap;
}
