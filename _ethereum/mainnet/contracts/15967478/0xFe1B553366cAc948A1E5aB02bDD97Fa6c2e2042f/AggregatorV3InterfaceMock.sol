// SPDX-License-Identifier: MIT

pragma solidity 0.8.2;
import "./Ownable.sol";

contract AggregatorV3InterfaceMock is Ownable {
    uint80 private roundIdValue = 1;
    int256 private price = 100000000;
    uint256 private startedAtValue = 2;
    uint256 private updatedAtValue = 3;
    uint80 private answeredInRoundValue = 4;
    uint8 private decimalValue = 8;

    function decimals() external view returns (uint8) {
        return decimalValue;
    }

    function setPriceValue(int256 _price) external onlyOwner {
        price = _price;
    }

    function getPriceValue() external view returns (int256) {
        return price;
    }

    function setDecimalValue(uint8 _decimalValue) external onlyOwner {
        decimalValue = _decimalValue;
    }

    function getDecimalValue() external view returns (uint8) {
        return decimalValue;
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
        return (
            roundIdValue,
            price,
            startedAtValue,
            updatedAtValue,
            answeredInRoundValue
        );
    }
}
