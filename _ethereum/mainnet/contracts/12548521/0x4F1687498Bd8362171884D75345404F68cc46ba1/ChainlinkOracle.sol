// SPDX-License-Identifier: MIT

pragma solidity >=0.6.2 <0.8.0;

import "./MixedSafeMathWithUnit.sol";

contract ChainlinkOracle {

    using MixedSafeMathWithUnit for uint256;
    using MixedSafeMathWithUnit for int256;

    string  public symbol;
    address public immutable oracle;
    uint256 public immutable decimals;

    constructor (string memory symbol_, address oracle_) {
        symbol = symbol_;
        oracle = oracle_;
        decimals = IChainlink(oracle_).decimals();
    }

    function getPrice() external view returns (uint256) {
        uint256 price = IChainlink(oracle).latestAnswer().itou().mul(uint256(10**18)).div(uint256(10**decimals));
        return price;
    }

}

interface IChainlink {
    function decimals() external view returns (uint8);
    function latestAnswer() external view returns (int256);
}
