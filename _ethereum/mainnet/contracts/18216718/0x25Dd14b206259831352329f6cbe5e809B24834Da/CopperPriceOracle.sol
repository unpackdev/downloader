// SPDX-License-Identifier: MIT
pragma solidity ^0.8.7;

import "./Ownable.sol";
import "./Pausable.sol";
import "./AggregatorV3Interface.sol";

contract CopperPriceOracle is Ownable, Pausable, AggregatorV3Interface {
    uint8 public override decimals = 8;
    uint256 public override version = 0;
    string public override description = "Copper Price Oracle";
    uint80 public currentRound;
    int256 private copperPrice = 24000000; //24 cents; 8 decimal position

    struct RoundData {
        uint80 roundId;
        int256 answer;
        uint256 startedAt;
        uint256 updatedAt;
        uint80 answeredInRound;
    }

    mapping(uint80 => RoundData) public roundData;

    constructor() {
        updateRound();
    }

    function updateRound() internal {
        currentRound++;
        roundData[currentRound] = RoundData({
            roundId: currentRound,
            answer: copperPrice,
            startedAt: block.timestamp,
            updatedAt: block.timestamp,
            answeredInRound: currentRound
        });
    }

    function updatePrice(int256 _price) public onlyOwner {
        copperPrice = _price;
        updateRound();
    }

    function getRoundData(uint80 _roundId)
        public
        view
        override
        returns (
            uint80 roundId,
            int256 answer,
            uint256 startedAt,
            uint256 updatedAt,
            uint80 answeredInRound
        )
    {
        RoundData memory rd = roundData[_roundId];

        return (
            rd.roundId,
            rd.answer,
            rd.startedAt,
            rd.updatedAt,
            rd.answeredInRound
        );
    }

    function latestRoundData()
        public
        view
        override
        returns (
            uint80 roundId,
            int256 answer,
            uint256 startedAt,
            uint256 updatedAt,
            uint80 answeredInRound
        )
    {
        RoundData memory rd = roundData[currentRound];

        return (
            rd.roundId,
            rd.answer,
            rd.startedAt,
            rd.updatedAt,
            rd.answeredInRound
        );
    }

    function latestRound() public view returns (uint256) {
        return currentRound;
    }

    function getAnswer(uint256 _roundId) public view returns (int256) {
        return roundData[uint80(_roundId)].answer;
    }

    function getTimestamp(uint256 _roundId) public view returns (uint256) {
        return roundData[uint80(_roundId)].updatedAt;
    }

    function pause() public onlyOwner {
        _pause();
    }

    function unpause() public onlyOwner {
        _unpause();
    }
}
