// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

import "./OrderTypes.sol";
import "./TheExecutionStrategy.sol";

/**
 * @title StrategyStandardSaleForFixedPrice
 * @notice Strategy that executes an order at a fixed price that
 * can be taken either by a bid or an ask.
 */
contract StrategyFixedPrice is TheExStrategy {
    uint256 public immutable PROTOCOL_FEE;

    /**
     * @notice Constructor
     * @param _protocolFee protocol fee (200 --> 2%, 400 --> 4%)
     */
    constructor(uint256 _protocolFee) {
        PROTOCOL_FEE = _protocolFee;
    }

    //
    // tion canExecuteTakerAsk
    //  @Description: Check price information
    //  @param OrderTypes.TakerOrder
    //  @param OrderTypes.MakerOrder
    //  @return external
    //
    function canExecuteBuy(OrderTypes.TakerOrder calldata takerAsk, OrderTypes.MakerOrder calldata makerBid)
        external
        view
        override
        returns (
            bool,
            uint256,
            uint256
        )
    {
        // Confirm all information are matched and valid within the time period for fixed price    return (
            return (((makerBid.price == takerAsk.price) &&
                (makerBid.tokenId == takerAsk.tokenId) &&
                (makerBid.startTime <= block.timestamp) &&
                (makerBid.endTime >= block.timestamp)),
            makerBid.tokenId,
            makerBid.amount
        );
    }

    //
    // tion canExecuteTakerBid
    //  @Description: Check strategy
    //  @param OrderTypes.TakerOrder
    //  @param OrderTypes.MakerOrder
    //  @return external
    //
    function canExecuteSell(OrderTypes.TakerOrder calldata takerBid, OrderTypes.MakerOrder calldata makerAsk)
        external
        view
        override
        returns (
            bool,
            uint256,
            uint256
        )
    {
        //Confirm all information are matched and valid within the time period for fixed price
        return (
            ((makerAsk.price == takerBid.price) &&
                (makerAsk.tokenId == takerBid.tokenId) &&
                (makerAsk.startTime <= block.timestamp) &&
                (makerAsk.endTime >= block.timestamp)),
            makerAsk.tokenId,
            makerAsk.amount
        );
    }

    //
    // function viewProtocolFee
    //  @Description: Return platform transaction fee
    //  @return external
    //
    function viewProtocolFee() external view override returns (uint256) {
        return PROTOCOL_FEE;
    }
}
