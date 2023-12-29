// SPDX-License-Identifier: BUSL-1.1
pragma solidity 0.8.16;

import "./AggregatorV3Interface.sol";

interface IWstETH {
    function stEthPerToken() external view returns (uint256);
}

contract WstETHPriceFeed is AggregatorV3Interface {
    AggregatorV3Interface public stETHUSDPriceFeed = AggregatorV3Interface(0xCfE54B5cD566aB89272946F602D76Ea879CAb4a8);
    IWstETH public wstETH = IWstETH(0x7f39C581F595B53c5cb19bD0b3f8dA6c935E2Ca0);

    function decimals() external view returns (uint8) {
        return stETHUSDPriceFeed.decimals();
    }

    function description() external pure returns (string memory) {
        return "wstETH / USD";
    }

    function version() external pure returns (uint256) {
        return 4;
    }

    function getRoundData(uint80 _roundId)
        external
        view
        returns (uint80 roundId, int256 answer, uint256 startedAt, uint256 updatedAt, uint80 answeredInRound)
    {
        (roundId, answer, startedAt, updatedAt, answeredInRound) = stETHUSDPriceFeed.getRoundData(_roundId);
        // wstETH / USD = (stETH / USD) * (wstETH / stETH)
        answer = int256(wstETH.stEthPerToken()) * answer / 1 ether;
    }

    function latestRoundData()
        external
        view
        returns (uint80 roundId, int256 answer, uint256 startedAt, uint256 updatedAt, uint80 answeredInRound)
    {
        (roundId, answer, startedAt, updatedAt, answeredInRound) = stETHUSDPriceFeed.latestRoundData();
        answer = int256(wstETH.stEthPerToken()) * answer / 1 ether;
    }
}
