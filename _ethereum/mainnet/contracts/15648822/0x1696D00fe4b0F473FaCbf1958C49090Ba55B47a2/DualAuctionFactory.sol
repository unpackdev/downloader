// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.10;

import "./ClonesWithImmutableArgs.sol";
import "./DualAuction.sol";
import "./IDualAuction.sol";
import "./IAuctionFactory.sol";

contract DualAuctionFactory is IAuctionFactory {
    using ClonesWithImmutableArgs for address;

    address public immutable implementation;

    constructor(address _implementation) {
        if (_implementation == address(0)) revert InvalidParams();
        implementation = _implementation;
    }

    /**
     * @inheritdoc IAuctionFactory
     */
    function createAuction(
        address bidAsset,
        address askAsset,
        uint256 minPrice,
        uint256 maxPrice,
        uint256 tickWidth,
        uint256 priceDenominator,
        uint256 endDate
    ) public returns (IDualAuction) {
        bytes memory data = abi.encodePacked(
            bidAsset,
            askAsset,
            minPrice,
            maxPrice,
            tickWidth,
            priceDenominator,
            endDate
        );
        DualAuction clone = DualAuction(implementation.clone(data));

        clone.initialize();

        emit AuctionCreated(bidAsset, askAsset, endDate, msg.sender, address(clone));
        return clone;
    }
}
