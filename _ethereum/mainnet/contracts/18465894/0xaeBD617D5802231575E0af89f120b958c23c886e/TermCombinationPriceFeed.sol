// SPDX-License-Identifier: MIT
pragma solidity ^0.8.18;

import "./AggregatorV3Interface.sol";

contract TermCombinationPriceFeed is AggregatorV3Interface {
    AggregatorV3Interface immutable assetToPegAggregator;
    AggregatorV3Interface immutable pegToBaseAggregator;

    uint8 immutable feedDecimals;
    int256 immutable denominator;

    constructor(
        AggregatorV3Interface assetToPegAggregator_,
        AggregatorV3Interface pegToBaseAggregator_,
        uint8 decimals_
    ) {
        assetToPegAggregator = assetToPegAggregator_;
        pegToBaseAggregator = pegToBaseAggregator_;
        feedDecimals = decimals_;
        denominator = int256(
            10 **
                (assetToPegAggregator_.decimals() +
                    pegToBaseAggregator_.decimals())
        );
    }

    function decimals() external view returns (uint8) {
        return feedDecimals;
    }

    function description() external pure returns (string memory) {
        return "Term Finance price feed";
    }

    function version() external pure returns (uint256) {
        return 0;
    }

    function getRoundData(
        uint80 /* _roundId */
    )
        external
        pure
        returns (
            uint80 roundId,
            int256 answer,
            uint256 startedAt,
            uint256 updatedAt,
            uint80 answeredInRound
        )
    {
        return (0, 0, 0, 0, 0);
    }

    function latestRoundData()
        external
        view
        returns (
            uint80 roundId,
            int256 answer,
            uint256 startedAt,
            uint256 updatedAt,
            uint80 answeredInRound
        )
    {
        // slither-disable-next-line unused-return
        (, int256 assetToPegAggregatorPrice, , , ) = assetToPegAggregator
            .latestRoundData();

        // slither-disable-next-line unused-return
        (, int256 pegToBaseAggregatorPrice, , , ) = pegToBaseAggregator
            .latestRoundData();

        if (assetToPegAggregatorPrice <= 0 || pegToBaseAggregatorPrice <= 0) {
            return (0, 0, 0, 0, 0);
        }

        int256 assetToBasePrice = (assetToPegAggregatorPrice *
            pegToBaseAggregatorPrice *
            int256(10 ** feedDecimals)) / (denominator);

        return (0, assetToBasePrice, 0, 0, 0);
    }
}
