// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.6.10;

import "./Ownable.sol";
import "./SafeMath.sol";
import "./ERC20.sol";
import "./IOracle.sol";

// solhint-disable max-states-count
contract OracleAggregator is Ownable {
    using SafeMath for uint256;

    // solhint-disable var-name-mixedcase
    address public constant ETH = 0xEeeeeEeeeEeEeeEeEeEeeEEEeeeeEeeeeeeeEEeE;
    uint256 public constant ETH_DECIMALS = 18;

    // solhint-disable var-name-mixedcase
    address public constant USD = 0x7354C81fbCb229187480c4f497F945C6A312d5C3;
    uint256 public constant USD_DECIMALS = 8;

    // solhint-disable var-name-mixedcase
    string public constant VERSION = "v2.0.0";

    address public immutable WETH;

    mapping(address => mapping(address => address)) public tokenPairAddress;

    // solhint-disable function-max-lines
    constructor(
        address _weth,
        address[] memory _inTokens,
        address[] memory _outTokens,
        address[] memory _oracles
    ) public {
        WETH = _weth;
        addTokens(_inTokens, _outTokens, _oracles);
        require(tokenPairAddress[ETH][USD] != address(0));
    }

    function addTokens(
        address[] memory _inTokens,
        address[] memory _outTokens,
        address[] memory _oracles
    ) public onlyOwner {
        require(
            _inTokens.length == _outTokens.length &&
                _inTokens.length == _oracles.length,
            "OracleAggregator: Invalid input length"
        );

        for (uint256 i = 0; i < _inTokens.length; i++) {
            require(
                tokenPairAddress[_inTokens[i]][_outTokens[i]] == address(0),
                "OracleAggregator: Cannot update oracles"
            );
            tokenPairAddress[_inTokens[i]][_outTokens[i]] = _oracles[i];
        }
    }

    // solhint-disable function-max-lines
    // solhint-disable code-complexity
    /// @dev expected return amount of outToken from amountIn of inToken
    function getExpectedReturnAmount(
        uint256 amountIn,
        address inToken,
        address outToken
    ) public view returns (uint256 returnAmount, uint256 returnDecimals) {
        // sanity checks
        require(amountIn > 0, "OracleAggregator: amountIn is Zero");
        require(inToken != address(0), "OracleAggregator: inToken is Zero");
        require(outToken != address(0), "OracleAggregator: outToken is Zero");

        // convert WETH to ETH
        if (inToken == WETH) {
            inToken = ETH;
        }
        if (outToken == WETH) {
            outToken = ETH;
        }

        returnDecimals = _getDecimals(outToken);
        if (inToken == outToken) {
            returnAmount = amountIn;
        } else {
            uint256 inDecimals = _getDecimals(inToken);
            returnAmount = _getExpectedReturnAmount(
                amountIn,
                inToken,
                outToken,
                inDecimals,
                returnDecimals
            );
        }
    }

    function _getExpectedReturnAmount(
        uint256 amountIn,
        address inToken,
        address outToken,
        uint256 inDecimals,
        uint256 outDecimals
    ) private view returns (uint256) {
        // Simple Oracle exists for this token pair
        if (tokenPairAddress[inToken][outToken] != address(0)) {
            return
                _computeReturnAmount(
                    amountIn,
                    _getRate(inToken, outToken),
                    inDecimals,
                    outDecimals,
                    outDecimals
                );
        } else if (tokenPairAddress[outToken][inToken] != address(0)) {
            // Inverse of simple oracle exists for this token pair
            return
                _computeReturnAmount(
                    amountIn,
                    _div(
                        10**inDecimals,
                        _getRate(outToken, inToken),
                        inDecimals
                    ),
                    inDecimals,
                    inDecimals,
                    outDecimals
                );
        }

        // No simple Oracle exists for this token pair
        uint256 price;
        uint256 priceDecimals;
        (address pairA, address pairB) = _checkAvailablePair(inToken, outToken);

        if (pairA == address(0) || pairB == address(0)) {
            // No route to compute price
            return 0;
        } else if (pairA == pairB) {
            // Tokens in pair both have an Oracle vs same third token (USD or ETH)
            uint256 priceA = _getRate(inToken, pairA);
            uint256 priceB = _getRate(outToken, pairB);
            priceDecimals = pairA == ETH ? ETH_DECIMALS : USD_DECIMALS;
            price = _div(priceA, priceB, priceDecimals);
        } else if (pairA == ETH && pairB == USD) {
            // inToken has Oracle with ETH, outToken has Oracle with USD
            uint256 priceInEth = _getRate(inToken, pairA);
            uint256 priceEthUsd = _getRate(pairA, pairB);
            uint256 priceOutUsd = _getRate(outToken, pairB);
            uint256 priceOutEth =
                _div(priceOutUsd, priceEthUsd, USD_DECIMALS).mul(10**10);
            price = _div(priceInEth, priceOutEth, ETH_DECIMALS);
            priceDecimals = ETH_DECIMALS;
        } else if (pairA == USD && pairB == ETH) {
            // inToken has Oracle with USD, outToken has Oracle with ETH
            uint256 priceInUsd = _getRate(inToken, pairA);
            uint256 priceEthUsd = _getRate(pairB, pairA);
            uint256 priceOutEth = _getRate(outToken, pairB);
            uint256 priceInEth =
                _div(priceInUsd, priceEthUsd, USD_DECIMALS).mul(10**10);
            price = _div(priceInEth, priceOutEth, ETH_DECIMALS);
            priceDecimals = ETH_DECIMALS;
        } else {
            // wrong pairs
            return 0;
        }

        return
            _computeReturnAmount(
                amountIn,
                price,
                inDecimals,
                priceDecimals,
                outDecimals
            );
    }

    function _computeReturnAmount(
        uint256 amountIn,
        uint256 price,
        uint256 inDecimals,
        uint256 priceDecimals,
        uint256 outDecimals
    ) private pure returns (uint256) {
        uint256 rawReturnAmount;
        uint256 rawReturnDecimals;
        if (inDecimals == priceDecimals) {
            rawReturnAmount = _mul(amountIn, price, priceDecimals);
            rawReturnDecimals = priceDecimals;
        } else if (priceDecimals > inDecimals) {
            uint256 decimalDiff = priceDecimals.sub(inDecimals);
            rawReturnAmount = _mul(
                amountIn.mul(10**decimalDiff),
                price,
                priceDecimals
            );
            rawReturnDecimals = priceDecimals;
        } else {
            uint256 decimalDiff = inDecimals.sub(priceDecimals);
            rawReturnAmount = _mul(
                amountIn,
                price.mul(10**decimalDiff),
                inDecimals
            );
            rawReturnDecimals = inDecimals;
        }

        if (rawReturnDecimals == outDecimals) {
            return rawReturnAmount;
        } else if (outDecimals > rawReturnDecimals) {
            uint256 decimalDiff = outDecimals.sub(rawReturnDecimals);
            return rawReturnAmount.mul(10**decimalDiff);
        } else {
            uint256 decimalDiff = rawReturnDecimals.sub(outDecimals);
            return rawReturnAmount.div(10**decimalDiff);
        }
    }

    function _getRate(address inToken, address outToken)
        private
        view
        returns (uint256)
    {
        IOracle priceFeed = IOracle(tokenPairAddress[inToken][outToken]);
        int256 price = priceFeed.latestAnswer();
        require(price > 0, "OracleAggregator: Price negative");
        return uint256(price);
    }

    /// @dev check the available oracles for token a & b
    /// and choose which oracles to use
    function _checkAvailablePair(address inToken, address outToken)
        private
        view
        returns (address, address)
    {
        if (
            tokenPairAddress[inToken][ETH] != address(0) &&
            tokenPairAddress[outToken][ETH] != address(0)
        ) {
            return (ETH, ETH);
        } else if (
            tokenPairAddress[inToken][USD] != address(0) &&
            tokenPairAddress[outToken][USD] != address(0)
        ) {
            return (USD, USD);
        } else if (
            tokenPairAddress[inToken][ETH] != address(0) &&
            tokenPairAddress[outToken][USD] != address(0)
        ) {
            return (ETH, USD);
        } else if (
            tokenPairAddress[inToken][USD] != address(0) &&
            tokenPairAddress[outToken][ETH] != address(0)
        ) {
            return (USD, ETH);
        } else {
            return (address(0), address(0));
        }
    }

    function _getDecimals(address token) private view returns (uint256) {
        if (token != ETH && token != USD) {
            try ERC20(token).decimals() returns (uint8 _decimals) {
                return uint256(_decimals);
            } catch {
                revert("OracleAggregator: ERC20.decimals() revert");
            }
        }

        return token == ETH ? ETH_DECIMALS : USD_DECIMALS;
    }

    function _div(
        uint256 x,
        uint256 y,
        uint256 decimals
    ) private pure returns (uint256) {
        return x.mul(10**decimals).add(y.div(2)).div(y);
    }

    function _mul(
        uint256 x,
        uint256 y,
        uint256 decimals
    ) private pure returns (uint256) {
        uint256 factor = 10**decimals;
        return x.mul(y).add(factor.div(2)).div(factor);
    }
}
