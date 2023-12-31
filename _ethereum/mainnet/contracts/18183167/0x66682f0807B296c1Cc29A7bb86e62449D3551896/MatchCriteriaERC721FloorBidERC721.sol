// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.17;

import "./MarkExchangeDataTypes.sol";
import "./IMatchingCriteria.sol";

error CannotMatch();
/**
 * @title MatchCriteriaERC721FloorBidERC721
 * @dev Criteria for matching orders where buyer will purchase token from a collection
 */
contract MatchCriteriaERC721FloorBidERC721 is IMatchingCriteria {
    function matchMakerAsk(Order calldata makerAsk, Order calldata takerBid)
        external
        pure
        override
        returns (
            bool,
            uint256,
            uint256,
            uint256,
            AssetType
        )
    {
        revert CannotMatch();
    }

    function matchMakerBid(Order calldata makerBid, Order calldata takerAsk)
        external
        pure
        override
        returns (
            bool,
            uint256,
            uint256,
            uint256,
            AssetType
        )
    {
        return (
            (makerBid.side != takerAsk.side) &&
            (makerBid.paymentToken == takerAsk.paymentToken) &&
            (makerBid.collection == takerAsk.collection) &&
            (makerBid.extraParams.length > 0 && makerBid.extraParams[0] == "\x01") &&
            (takerAsk.extraParams.length > 0 && takerAsk.extraParams[0] == "\x01") &&
            (makerBid.amount == 1) &&
            (takerAsk.amount == 1) &&
            (makerBid.matchingCriteria == takerAsk.matchingCriteria) &&
            (makerBid.price == takerAsk.price),
            makerBid.price,
            takerAsk.tokenId,
            1,
            AssetType.ERC721
        );
    }
}
