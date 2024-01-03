// SPDX-License-Identifier: MIT

pragma solidity ^0.5.16;
pragma experimental ABIEncoderV2;

import "./Decimal.sol";
import "./SafeMath.sol";

import "./IOracle.sol";
import "./IChainLinkAggregator.sol";

contract ChainLinkOracle is IOracle {

    using SafeMath for uint256;

    IChainLinkAggregator public chainLinkAggregator;

    uint256 constant public CHAIN_LINK_DECIMALS = 10**8;

    constructor(address _chainLinkAggregator) public {
        chainLinkAggregator = IChainLinkAggregator(_chainLinkAggregator);
    }

    function fetchCurrentPrice()
        external
        view
        returns (Decimal.D256 memory)
    {
        uint256 latestAnswer = uint256(chainLinkAggregator.latestAnswer());

        require(
            latestAnswer > 0,
            "ChainLinkOracle: cannot report a price of 0"
        );

        return Decimal.D256({
            value: latestAnswer.mul(uint256(10**10))
        });
    }

}
