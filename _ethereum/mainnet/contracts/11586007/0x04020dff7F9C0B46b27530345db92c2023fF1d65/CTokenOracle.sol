// SPDX-License-Identifier: MIT

pragma solidity ^0.5.16;
pragma experimental ABIEncoderV2;

import "./Decimal.sol";
import "./SafeMath.sol";

import "./IOracle.sol";
import "./ICToken.sol";
import "./IChainLinkAggregator.sol";

contract CTokenOracle is IOracle {

    using SafeMath for uint256;
    using SafeMath for uint8;

    uint8 public precisionScalar;
    uint8 public chainlinkDecimals;

    ICToken public cToken;
    IChainLinkAggregator public chainLinkAggregator;

    constructor (
        address _cTokenAddress,
        address _chainLinkAggregator
    )
        public
    {
        cToken = ICToken(_cTokenAddress);
        chainLinkAggregator = IChainLinkAggregator(_chainLinkAggregator);

        // For CUSDC, this is 8
        uint8 cTokenDecimals = cToken.decimals();

        // For USDC, this is 6
        uint8 underlyingDecimals = ICToken(cToken.underlying()).decimals();

        // The result, in the case of cUSDC, will be 16
        precisionScalar = 18 + underlyingDecimals - cTokenDecimals;

        chainlinkDecimals = chainLinkAggregator.decimals();
    }

    function fetchCurrentPrice()
        external
        view
        returns (Decimal.D256 memory)
    {
        uint256 exchangeRate = cToken.exchangeRateStored(); // 213927934173700 (16 dp)

        // Scaled exchange amount
        uint256 cTokenAmount = exchangeRate.mul(uint256(10 ** precisionScalar));

        // Some result in x decimal places
        uint256 priceInUSD = uint256(chainLinkAggregator.latestAnswer());

        // Scale price to be expressed in 18 d.p
        uint256 scaledPriceInUSD = priceInUSD.mul(uint256(10 ** (18 - chainlinkDecimals)));

        // Multiply the two together to get the value of 1 cToken
        uint256 result = scaledPriceInUSD.mul(cTokenAmount).div(uint256(10 ** 18));

        require(
            result > 0,
            "CTokenOracle: cannot report a price of 0"
        );

        return Decimal.D256({
            value: result
        });

    }

}
