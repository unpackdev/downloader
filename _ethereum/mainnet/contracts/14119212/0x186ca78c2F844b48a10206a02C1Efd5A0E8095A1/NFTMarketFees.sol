// SPDX-License-Identifier: MIT OR Apache-2.0

pragma solidity ^0.7.0;

import "./SafeMathUpgradeable.sol";
import "./Initializable.sol";
import "./IERC721Upgradeable.sol";

import "./FoundationTreasuryNode.sol";
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
FoundationTreasuryNode,
NFTMarketCore,
NFTMarketCreators,
SendValueWithFallbackWithdraw
{
    using SafeMathUpgradeable for uint256;

    uint256 private _primaryFoundationFeeBasisPoints;
    uint256 private _primaryCuratorFeeBasisPoints;
    uint256 private _secondaryFoundationFeeBasisPoints;
    uint256 private _secondaryCreatorFeeBasisPoints;

    mapping(address => mapping(uint256 => bool)) private nftContractToTokenIdToFirstSaleCompleted;

    event MarketFeesUpdated(
        uint256 primaryFoundationFeeBasisPoints,
        uint256 primaryCuratorFeeBasisPoints,
        uint256 secondaryFoundationFeeBasisPoints,
        uint256 secondaryCreatorFeeBasisPoints
    );

    /**
     * @notice Returns true if the given NFT has not been sold in this market previously and is being sold by the creator.
   */
    function getIsPrimary(address nftContract, uint256 tokenId) public view returns (bool isPrimary) {
        address payable seller = _getSellerFor(nftContract, tokenId);
        bool isCreator;
        (, , isCreator) = _getCreatorPaymentInfo(nftContract, tokenId, seller);
        isPrimary = isCreator && !nftContractToTokenIdToFirstSaleCompleted[nftContract][tokenId];
    }

    /**
     * @notice Returns the current fee configuration in basis points.
   */
    function getFeeConfig()
    public
    view
    returns (
        uint256 primaryCRNFTFeeBasisPoints,
        uint256 primaryCuratorFeeBasisPoints,
        uint256 secondaryCRNFTFeeBasisPoints,
        uint256 secondaryCreatorFeeBasisPoints
    )
    {
        return (_primaryFoundationFeeBasisPoints, _primaryCuratorFeeBasisPoints, _secondaryFoundationFeeBasisPoints, _secondaryCreatorFeeBasisPoints);
    }

    /**
     * @notice Returns how funds will be distributed for an Auction sale at the given price point.
   * @dev This is required for backwards compatibility with subgraph.
   */
    function getFees(
        address nftContract,
        uint256 tokenId,
        uint256 price
    )
    public
    view
    returns (
        uint256 CRNFTFee,
        uint256 creatorRev,
        uint256 ownerRev
    )
    {
        address payable seller = _getSellerFor(nftContract, tokenId);
        (CRNFTFee, , , creatorRev, , ownerRev) = _getFees(nftContract, tokenId, seller, price);
    }

    /**
     * @dev Calculates how funds should be distributed for the given sale details.
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
        uint256 foundationFee,
        address payable[] memory creatorRecipients,
        uint256[] memory creatorShares,
        uint256 creatorRev,
        address payable ownerRevTo,
        uint256 ownerRev
    )
    {
        bool isCreator;
        (creatorRecipients, creatorShares, isCreator) = _getCreatorPaymentInfo(nftContract, tokenId, seller);
        bool isPrimary = !nftContractToTokenIdToFirstSaleCompleted[nftContract][tokenId];

        // The SafeMath usage below should only be applicable if a huge (unrealistic) price is used
        // or fees are misconfigured.

        // Calculate the Foundation fee
        foundationFee =
        price.mul(isPrimary ? _primaryFoundationFeeBasisPoints : _secondaryFoundationFeeBasisPoints) /
        BASIS_POINTS;

        // Calculate the Creator revenue.
        if (isPrimary) {
            creatorRev = price.sub(foundationFee);

            // calculate fee for curator if it is a primary sale (the rest goes to artist who is creator and market)
            try ICRNFT721(nftContract).tokenCurator{ gas: READ_ONLY_GAS_LIMIT }(tokenId) returns (address payable _curator) {
                if (_curator != address(0)) {
                    //its curator, but used as owner for distribution in primary market as owner is artist and get the rest
                    ownerRevTo = _curator;
                    ownerRev = price.mul(_primaryCuratorFeeBasisPoints) / BASIS_POINTS;
                    creatorRev = price.sub(foundationFee).sub(ownerRev);
                }
            } catch // solhint-disable-next-line no-empty-blocks
            {
                // Fall through
            }
        } else {
            if (creatorRecipients.length > 0) {
                if (isCreator) {
                    // Non-primary sales by the creator should go to the payment address.
                    creatorRev = price.sub(foundationFee);
                } else {
                    creatorRev = price.mul(_secondaryCreatorFeeBasisPoints) / BASIS_POINTS;
                    // If a secondary sale, calculate the owner revenue.
                    ownerRevTo = seller;
                    ownerRev = price.sub(foundationFee).sub(creatorRev);
                }
            } else {
                // If a secondary sale, calculate the owner revenue.
                ownerRevTo = seller;
                ownerRev = price.sub(foundationFee);
            }
        }
    }

    /**
     * @dev Distributes funds to foundation, creator, and NFT owner after a sale.
   * This call will respect the creator's payment address if defined.
   */
    // solhint-disable-next-line code-complexity
    function _distributeFunds(
        address nftContract,
        uint256 tokenId,
        address payable seller,
        uint256 price
    )
    internal
    returns (
        uint256 foundationFee,
        uint256 creatorFee,
        uint256 ownerRev
    )
    {
        address payable[] memory creatorRecipients;
        uint256[] memory creatorShares;

        address payable ownerRevTo;
        (foundationFee, creatorRecipients, creatorShares, creatorFee, ownerRevTo, ownerRev) = _getFees(
            nftContract,
            tokenId,
            seller,
            price
        );

        // Anytime fees are distributed that indicates the first sale is complete,
        // which will not change state during a secondary sale.
        // This must come after the `_getFees` call above as this state is considered in the function.
        nftContractToTokenIdToFirstSaleCompleted[nftContract][tokenId] = true;

        _sendValueWithFallbackWithdrawWithLowGasLimit(getFoundationTreasury(), foundationFee);

        if (creatorFee > 0) {
            if (creatorRecipients.length > 1) {
                uint256 maxCreatorIndex = creatorRecipients.length - 1;
                if (maxCreatorIndex > MAX_CREATOR_INDEX) {
                    maxCreatorIndex = MAX_CREATOR_INDEX;
                }

                // Determine the total shares defined so it can be leveraged to distribute below
                uint256 totalShares;
                for (uint256 i = 0; i <= maxCreatorIndex; i++) {
                    if (creatorShares[i] > BASIS_POINTS) {
                        // If the numbers are >100% we ignore the fee recipients and pay just the first instead
                        maxCreatorIndex = 0;
                        break;
                    }
                    totalShares = totalShares.add(creatorShares[i]);
                }
                if (totalShares == 0) {
                    maxCreatorIndex = 0;
                }

                // Send payouts to each additional recipient if more than 1 was defined
                uint256 totalDistributed;
                for (uint256 i = 1; i <= maxCreatorIndex; i++) {
                    uint256 share = (creatorFee.mul(creatorShares[i])) / totalShares;
                    totalDistributed = totalDistributed.add(share);
                    _sendValueWithFallbackWithdrawWithMediumGasLimit(creatorRecipients[i], share);
                }

                // Send the remainder to the 1st creator, rounding in their favor
                _sendValueWithFallbackWithdrawWithMediumGasLimit(creatorRecipients[0], creatorFee.sub(totalDistributed));
            } else {
                _sendValueWithFallbackWithdrawWithMediumGasLimit(creatorRecipients[0], creatorFee);
            }
        }
        _sendValueWithFallbackWithdrawWithMediumGasLimit(ownerRevTo, ownerRev);
    }

    /**
     * @notice Allows Foundation to change the market fees.
   */
    function _updateMarketFees(
        uint256 primaryFoundationFeeBasisPoints,
        uint256 primaryCuratorFeeBasisPoints,
        uint256 secondaryFoundationFeeBasisPoints,
        uint256 secondaryCreatorFeeBasisPoints
    ) internal {
        require(primaryFoundationFeeBasisPoints.add(primaryCuratorFeeBasisPoints) < BASIS_POINTS, "NFTMarketFees: Fees >= 100%");
        require(
            secondaryFoundationFeeBasisPoints.add(secondaryCreatorFeeBasisPoints) < BASIS_POINTS,
            "NFTMarketFees: Fees >= 100%"
        );
        _primaryFoundationFeeBasisPoints = primaryFoundationFeeBasisPoints;
        _primaryCuratorFeeBasisPoints = primaryCuratorFeeBasisPoints;
        _secondaryFoundationFeeBasisPoints = secondaryFoundationFeeBasisPoints;
        _secondaryCreatorFeeBasisPoints = secondaryCreatorFeeBasisPoints;

        emit MarketFeesUpdated(
            primaryFoundationFeeBasisPoints,
            primaryCuratorFeeBasisPoints,
            secondaryFoundationFeeBasisPoints,
            secondaryCreatorFeeBasisPoints
        );
    }

    uint256[1000] private ______gap;
}