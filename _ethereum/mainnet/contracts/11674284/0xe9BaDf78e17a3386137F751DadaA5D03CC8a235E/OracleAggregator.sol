// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.6.10;

import "./Ownable.sol";
import "./SafeMath.sol";
import "./ERC20.sol";
import "./IGasPriceOracle.sol";

// solhint-disable max-states-count
contract OracleAggregator is Ownable {
    using SafeMath for uint256;

    // solhint-disable private-vars-leading-underscore
    address private constant ETH = 0xEeeeeEeeeEeEeeEeEeEeeEEEeeeeEeeeeeeeEEeE;
    // solhint-disable private-vars-leading-underscore
    address private constant USD = 0x7354C81fbCb229187480c4f497F945C6A312d5C3;
    // solhint-disable var-name-mixedcase
    address public immutable WETH;

    mapping(address => mapping(address => address)) private _tokenPairAddress;
    mapping(address => uint256) private _nrOfDecimalsUSD;

    // solhint-disable function-max-lines
    constructor(
        address _weth,
        address[] memory _inTokens,
        address[] memory _outTokens,
        address[] memory _oracles,
        address[] memory _stablecoins,
        uint256[] memory _decimals
    ) public {
        WETH = _weth;
        addTokens(_inTokens, _outTokens, _oracles);
        addStablecoins(_stablecoins, _decimals);
        // required token pairs
        require(_tokenPairAddress[ETH][USD] != address(0));
        require(_tokenPairAddress[USD][ETH] != address(0));
    }

    function addTokens(
        address[] memory _inTokens,
        address[] memory _outTokens,
        address[] memory _oracles
    ) public onlyOwner {
        require(
            _inTokens.length == _outTokens.length &&
                _inTokens.length == _oracles.length
        );
        for (uint256 i = 0; i < _inTokens.length; i++) {
            _tokenPairAddress[_inTokens[i]][_outTokens[i]] = _oracles[i];
        }
    }

    function addStablecoins(
        address[] memory _stablecoins,
        uint256[] memory _decimals
    ) public onlyOwner {
        require(_stablecoins.length == _decimals.length);
        for (uint256 i = 0; i < _stablecoins.length; i++) {
            _nrOfDecimalsUSD[_stablecoins[i]] = _decimals[i];
        }
    }

    // solhint-disable function-max-lines
    // solhint-disable code-complexity
    /// @dev expected return amount of outToken from amountIn of inToken
    function getExpectedReturnAmount(
        uint256 amountIn,
        address inToken,
        address outToken
    ) public view returns (uint256 returnAmount, uint256 outTokenDecimals) {
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

        // decimals of inToken
        uint256 inTokenDecimals;
        (inTokenDecimals, outTokenDecimals) = _getDecimals(inToken, outToken);

        // store outToken address if it is a stablecoin
        address stableCoinAddress =
            _nrOfDecimalsUSD[outToken] > 0 ? outToken : address(0);

        // convert any stablecoin addresses to USD address
        (inToken, outToken) = _convertUSD(inToken, outToken);

        if (outToken == ETH || outToken == USD) {
            // when outToken is ETH or USD
            returnAmount = _handleConvertToEthOrUsd(
                amountIn,
                inToken,
                outToken,
                inTokenDecimals,
                stableCoinAddress
            );
        } else {
            // when outToken is not ETH or USD
            returnAmount = _handleConvertToToken(
                amountIn,
                inToken,
                outToken,
                inTokenDecimals
            );
        }

        return (returnAmount, outTokenDecimals);
    }

    function _handleConvertToEthOrUsd(
        uint256 amountIn,
        address inToken,
        address outToken,
        uint256 inTokenDecimals,
        address stableCoinAddress
    ) private view returns (uint256 returnAmount) {
        // oracle of inToken vs outToken exists
        // e.g. calculating KNC/ETH
        // and KNC/ETH oracle exists
        if (_tokenPairAddress[inToken][outToken] != address(0)) {
            (uint256 price, uint256 nrOfDecimals) = _getRate(inToken, outToken);
            returnAmount = stableCoinAddress != address(0)
                ? _matchStableCoinDecimal(
                    stableCoinAddress,
                    amountIn,
                    nrOfDecimals,
                    0,
                    price,
                    1
                )
                : amountIn.mul(price);

            return returnAmount.div(10**inTokenDecimals);
        } else {
            // direct oracle of inToken vs outToken does not exist
            // e.g. calculating UNI/USD
            // UNI/ETH and USD/ETH oracles available
            (address pairA, address pairB) =
                _checkAvailablePair(inToken, outToken);
            if (pairA == address(0) && pairB == address(0)) return (0);
            (uint256 priceA, ) = _getRate(inToken, pairA);
            (uint256 priceB, uint256 nrOfDecimals) = _getRate(outToken, pairB);

            nrOfDecimals = stableCoinAddress != address(0)
                ? _nrOfDecimalsUSD[stableCoinAddress]
                : nrOfDecimals;

            returnAmount = amountIn.mul(priceA.mul(10**nrOfDecimals)).div(
                priceB
            );
            if (outToken != ETH) {
                return returnAmount.div(10**inTokenDecimals);
            } else {
                return returnAmount.div(10**_nrOfDecimalsUSD[USD]);
            }
        }
    }

    function _handleConvertToToken(
        uint256 amountIn,
        address inToken,
        address outToken,
        uint256 inTokenDecimals
    ) private view returns (uint256 returnAmount) {
        (address pairA, address pairB) = _checkAvailablePair(inToken, outToken);
        if (pairA == address(0) && pairB == address(0)) return (0);
        // oracle of inToken/ETH, outToken/ETH || inToken/USD, outToken/USD exists
        // e.g. calculating KNC/UNI where
        // KNC/ETH and UNI/ETH oracles available
        if (pairA == pairB) {
            (uint256 priceA, uint256 nrOfDecimals) = _getRate(inToken, pairA);

            (uint256 priceB, ) = _getRate(outToken, pairB);

            returnAmount = amountIn.mul(priceA.mul(10**nrOfDecimals)).div(
                priceB
            );
            if (pairA == ETH) {
                return returnAmount.div(10**inTokenDecimals);
            } else {
                return returnAmount.div(10**_nrOfDecimalsUSD[USD]);
            }
        } else if (pairA == ETH && pairB == USD) {
            // oracle of inToken/ETH and outToken/USD exists
            // e.g. calculating UNI/SXP where
            // UNI/ETH and SXP/USD oracles available
            (uint256 priceA, ) = _getRate(inToken, pairA);
            (uint256 priceETHUSD, ) = _getRate(ETH, USD);
            (uint256 priceB, ) = _getRate(outToken, pairB);

            returnAmount = amountIn.mul(priceA.mul(priceETHUSD)).div(priceB);
            return returnAmount.div(10**inTokenDecimals);
        } else if (pairA == USD && pairB == ETH) {
            // oracle of inToken/USD and outToken/ETH exists
            // e.g. calculating SXP/UNI where
            // SXP/USD and UNI/ETH oracles available
            uint256 numerator;
            {
                (uint256 priceA, uint256 nrOfDecimals) =
                    _getRate(inToken, pairA);

                (uint256 priceUSDETH, uint256 nrOfDecimalsUSDETH) =
                    _getRate(USD, ETH);

                numerator = priceUSDETH
                    .mul(10**(nrOfDecimalsUSDETH.sub(nrOfDecimals)))
                    .mul(priceA)
                    .div(10**nrOfDecimalsUSDETH);
            }
            (uint256 priceB, ) = _getRate(outToken, pairB);
            returnAmount = amountIn.mul(numerator).div(priceB);
            return returnAmount;
        }
    }

    /// @dev check the available oracles for token a & b
    /// and choose which oracles to use
    function _checkAvailablePair(address inToken, address outToken)
        private
        view
        returns (address, address)
    {
        if (
            _tokenPairAddress[inToken][USD] != address(0) &&
            _tokenPairAddress[outToken][USD] != address(0)
        ) {
            return (USD, USD);
        } else if (
            _tokenPairAddress[inToken][ETH] != address(0) &&
            _tokenPairAddress[outToken][ETH] != address(0)
        ) {
            return (ETH, ETH);
        } else if (
            _tokenPairAddress[inToken][ETH] != address(0) &&
            _tokenPairAddress[outToken][USD] != address(0)
        ) {
            return (ETH, USD);
        } else if (
            _tokenPairAddress[inToken][USD] != address(0) &&
            _tokenPairAddress[outToken][ETH] != address(0)
        ) {
            return (USD, ETH);
        } else {
            return (address(0), address(0));
        }
    }

    function _getDecimals(address inToken, address _outToken)
        private
        view
        returns (uint256 inTokenDecimals, uint256 outTokenDecimals)
    {
        // decimals of inToken
        if (inToken != ETH && inToken != USD) {
            try ERC20(inToken).decimals() returns (uint8 _inputDecimals) {
                inTokenDecimals = uint256(_inputDecimals);
            } catch {
                revert("OracleAggregator: ERC20.decimals() revert");
            }
        } else {
            if (inToken != ETH) {
                inTokenDecimals = _nrOfDecimalsUSD[USD];
            } else {
                inTokenDecimals = 18;
            }
        }

        // decimals of outToken
        if (_outToken != ETH && _outToken != USD) {
            try ERC20(_outToken).decimals() returns (uint8 _outputDecimals) {
                outTokenDecimals = uint256(_outputDecimals);
            } catch {
                revert("OracleAggregator: ERC20.decimals() revert");
            }
        } else {
            if (_outToken != ETH) {
                outTokenDecimals = _nrOfDecimalsUSD[USD];
            } else {
                outTokenDecimals = 18;
            }
        }
    }

    function _getRate(address inToken, address outToken)
        private
        view
        returns (uint256 tokenPrice, uint256 nrOfDecimals)
    {
        if (inToken == outToken) {
            return (1, 0);
        } else {
            IGasPriceOracle priceFeed =
                IGasPriceOracle(_tokenPairAddress[inToken][outToken]);
            tokenPrice = uint256(priceFeed.latestAnswer());
            nrOfDecimals = priceFeed.decimals();
        }
    }

    /// @dev converting all usd pegged stablecoins to single USD address
    function _convertUSD(address inToken, address outToken)
        private
        view
        returns (address, address)
    {
        if (_nrOfDecimalsUSD[inToken] > 0 && _nrOfDecimalsUSD[outToken] > 0) {
            return (USD, USD);
        } else if (_nrOfDecimalsUSD[inToken] > 0) {
            return (USD, outToken);
        } else if (_nrOfDecimalsUSD[outToken] > 0) {
            return (inToken, USD);
        } else {
            return (inToken, outToken);
        }
    }

    /// @dev modify nrOfDecimlas and amount to follow stableCoin's nrOfDecimals
    function _matchStableCoinDecimal(
        address stableCoinAddress,
        uint256 amount,
        uint256 nrOfDecimals,
        uint256 padding,
        uint256 returnRateA,
        uint256 returnRateB
    ) private view returns (uint256 returnAmount) {
        uint256 div =
            _nrOfDecimalsUSD[stableCoinAddress] > nrOfDecimals
                ? 10**(_nrOfDecimalsUSD[stableCoinAddress].sub(nrOfDecimals))
                : 10**(nrOfDecimals.sub(_nrOfDecimalsUSD[stableCoinAddress]));
        returnAmount = _nrOfDecimalsUSD[stableCoinAddress] > nrOfDecimals
            ? amount.mul(returnRateA.mul(10**padding)).div(returnRateB).mul(div)
            : amount.mul(returnRateA.mul(10**padding)).div(returnRateB).div(
                div
            );
    }
}
