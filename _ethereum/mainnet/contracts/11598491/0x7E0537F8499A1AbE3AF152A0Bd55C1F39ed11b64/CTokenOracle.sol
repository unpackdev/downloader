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

    uint256 public precisionScalar;

    uint256 public chainlinkTokenScalar;
    uint256 public chainlinkEthScalar;

    uint256 constant BASE = 10 ** 18;

    ICToken public cToken;

    IChainLinkAggregator public chainLinkTokenAggregator;
    IChainLinkAggregator public chainLinkEthAggregator;

    constructor (
        address _cTokenAddress,
        address _chainLinkTokenAggregator,
        address _chainLinkEthAggregator
    )
        public
    {
        cToken = ICToken(_cTokenAddress);
        chainLinkTokenAggregator = IChainLinkAggregator(_chainLinkTokenAggregator);
        chainLinkEthAggregator = IChainLinkAggregator(_chainLinkEthAggregator);

        // For CUSDC, this is 8
        uint8 cTokenDecimals = cToken.decimals();

        // For USDC, this is 6
        uint8 underlyingDecimals = ICToken(cToken.underlying()).decimals();

        // The result, in the case of cUSDC, will be 16
        precisionScalar = uint256(18 + underlyingDecimals - cTokenDecimals);

        chainlinkTokenScalar = uint256(18 - chainLinkTokenAggregator.decimals());
        chainlinkEthScalar = uint256(18 - chainLinkEthAggregator.decimals());
    }

    function fetchCurrentPrice()
        external
        view
        returns (Decimal.D256 memory)
    {
        uint256 exchangeRate = cToken.exchangeRateStored(); // 213927934173700 (16 dp)

        // Scaled exchange amount
        uint256 cTokenAmount = exchangeRate.mul(BASE).div(uint256(10 ** precisionScalar));

        // Some result in x decimal places
        uint256 priceInEth = uint256(chainLinkTokenAggregator.latestAnswer()).mul(10 ** chainlinkTokenScalar);

        uint256 priceOfEth = uint256(chainLinkEthAggregator.latestAnswer()).mul(10 ** chainlinkEthScalar);

        // Multiply the two together to get the value of 1 cToken
        uint256 result = cTokenAmount.mul(priceInEth).div(BASE);
        result = result.mul(priceOfEth).div(BASE);

        require(
            result > 0,
            "CTokenOracle: cannot report a price of 0"
        );

        return Decimal.D256({
            value: result
        });

    }

}
