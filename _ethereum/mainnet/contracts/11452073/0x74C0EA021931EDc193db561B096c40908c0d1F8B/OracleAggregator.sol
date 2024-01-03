// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.6.10;

import "./Ownable.sol";
import "./SafeMath.sol";
import "./IGasPriceOracle.sol";
import "./ERC20.sol";

// solhint-disable max-states-count
contract OracleAggregator is Ownable {
    using SafeMath for uint256;
    // solhint-disable var-name-mixedcase
    address private _ETH_ADDRESS;
    // solhint-disable var-name-mixedcase
    address private _USD_ADDRESS;

    mapping(address => mapping(address => address)) private _tokenPairAddress;
    mapping(address => uint256) private _nrOfDecimalsUSD;

    // solhint-disable function-max-lines
    constructor() public {
        _nrOfDecimalsUSD[0x7354C81fbCb229187480c4f497F945C6A312d5C3] = 8; // USD
        _nrOfDecimalsUSD[0xdAC17F958D2ee523a2206206994597C13D831ec7] = 6; // USDT
        _nrOfDecimalsUSD[0xA0b86991c6218b36c1d19D4a2e9Eb0cE3606eB48] = 6; // USDC
        _nrOfDecimalsUSD[0x6B175474E89094C44Da98b954EedeAC495271d0F] = 18; // DAI
        _nrOfDecimalsUSD[0x4Fabb145d64652a948d72533023f6E7A623C7C53] = 18; // BUSD
        _nrOfDecimalsUSD[0x57Ab1ec28D129707052df4dF418D58a2D46d5f51] = 18; // SUSD
        _nrOfDecimalsUSD[0x0000000000085d4780B73119b644AE5ecd22b376] = 18; // TUSD

        _ETH_ADDRESS = 0xEeeeeEeeeEeEeeEeEeEeeEEEeeeeEeeeeeeeEEeE;
        _USD_ADDRESS = 0x7354C81fbCb229187480c4f497F945C6A312d5C3; // Random address

        _tokenPairAddress[0x7Fc66500c84A76Ad7e9c93437bFc5Ac33E2DDaE9][
            _ETH_ADDRESS
        ] = 0x6Df09E975c830ECae5bd4eD9d90f3A95a4f88012; // AAVE/ETH
        _tokenPairAddress[0xADE00C28244d5CE17D72E40330B1c318cD12B7c3][
            _USD_ADDRESS
        ] = 0x231e764B44b2C1b7Ca171fa8021A24ed520Cde10; // ADX/USD

        _tokenPairAddress[0x0D8775F648430679A709E98d2b0Cb6250d2887EF][
            _ETH_ADDRESS
        ] = 0x0d16d4528239e9ee52fa531af613AcdB23D88c94; // BAT/ETH
        _tokenPairAddress[0xB8c77482e45F1F44dE1745F52C74426C631bDD52][
            _USD_ADDRESS
        ] = 0x14e613AC84a31f709eadbdF89C6CC390fDc9540A; // BNB/USD
        _tokenPairAddress[0x1F573D6Fb3F13d689FF844B4cE37794d79a7FF1C][
            _ETH_ADDRESS
        ] = 0xCf61d1841B178fe82C8895fe60c2EDDa08314416; // BNT/ETH
        _tokenPairAddress[0x56d811088235F11C8920698a204A5010a788f4b3][
            _ETH_ADDRESS
        ] = 0x8f7C7181Ed1a2BA41cfC3f5d064eF91b67daef66; // BZRX/ETH

        _tokenPairAddress[0xc00e94Cb662C3520282E6f5717214004A7f26888][
            _ETH_ADDRESS
        ] = 0x1B39Ee86Ec5979ba5C322b826B3ECb8C79991699; // COMP/ETH
        _tokenPairAddress[0xc00e94Cb662C3520282E6f5717214004A7f26888][
            _USD_ADDRESS
        ] = 0xdbd020CAeF83eFd542f4De03e3cF0C28A4428bd5; // COMP/USD
        _tokenPairAddress[0xA0b73E1Ff0B80914AB6fe0444E65848C4C34450b][
            _ETH_ADDRESS
        ] = 0xcA696a9Eb93b81ADFE6435759A29aB4cf2991A96; // CRO/ETH

        _tokenPairAddress[0xEd91879919B71bB6905f23af0A68d231EcF87b14][
            _ETH_ADDRESS
        ] = 0xD010e899f7ab723AC93f825cDC5Aa057669557c2; // DMG/ETH

        _tokenPairAddress[0xF629cBd94d3791C9250152BD8dfBDF380E2a3B9c][
            _ETH_ADDRESS
        ] = 0x24D9aB51950F3d62E9144fdC2f3135DAA6Ce8D1B; // ENJ/ETH
        _tokenPairAddress[_ETH_ADDRESS][
            _USD_ADDRESS
        ] = 0x5f4eC3Df9cbd43714FE2740f5E3616155c5b8419; // ETH/USD

        _tokenPairAddress[0xdd974D5C2e2928deA5F71b9825b8b646686BD200][
            _ETH_ADDRESS
        ] = 0x656c0544eF4C98A6a98491833A89204Abb045d6b; // KNC/ETH
        _tokenPairAddress[0xdd974D5C2e2928deA5F71b9825b8b646686BD200][
            _USD_ADDRESS
        ] = 0xf8fF43E991A81e6eC886a3D281A2C6cC19aE70Fc; // KNC/USD

        _tokenPairAddress[0x514910771AF9Ca656af840dff83E8264EcF986CA][
            _USD_ADDRESS
        ] = 0x2c1d072e956AFFC0D435Cb7AC38EF18d24d9127c; // LINK/USD
        _tokenPairAddress[0x514910771AF9Ca656af840dff83E8264EcF986CA][
            _ETH_ADDRESS
        ] = 0xDC530D9457755926550b59e8ECcdaE7624181557; // LINK/ETH
        _tokenPairAddress[0xBBbbCA6A901c926F240b89EacB641d8Aec7AEafD][
            _ETH_ADDRESS
        ] = 0x160AC928A16C93eD4895C2De6f81ECcE9a7eB7b4; // LRC/ETH
        _tokenPairAddress[0xBBbbCA6A901c926F240b89EacB641d8Aec7AEafD][
            _USD_ADDRESS
        ] = 0x231e764B44b2C1b7Ca171fa8021A24ed520Cde10; // LRC/USD

        _tokenPairAddress[0x0F5D2fB29fb7d3CFeE444a200298f468908cC942][
            _ETH_ADDRESS
        ] = 0x82A44D92D6c329826dc557c5E1Be6ebeC5D5FeB9; // MANA/ETH
        _tokenPairAddress[0x9f8F72aA9304c8B593d555F12eF6589cC3A579A2][
            _ETH_ADDRESS
        ] = 0x24551a8Fb2A7211A25a17B1481f043A8a8adC7f2; // MKR/ETH

        _tokenPairAddress[0x1776e1F26f98b1A5dF9cD347953a26dd3Cb46671][
            _ETH_ADDRESS
        ] = 0x9cB2A01A7E64992d32A34db7cEea4c919C391f6A; // NMR/ETH

        _tokenPairAddress[0x408e41876cCCDC0F92210600ef50372656052a38][
            _ETH_ADDRESS
        ] = 0x3147D7203354Dc06D9fd350c7a2437bcA92387a4; // REN/ETH
        _tokenPairAddress[0x408e41876cCCDC0F92210600ef50372656052a38][
            _USD_ADDRESS
        ] = 0x0f59666EDE214281e956cb3b2D0d69415AfF4A01; // REN/USD
        _tokenPairAddress[0x221657776846890989a759BA2973e427DfF5C9bB][
            _ETH_ADDRESS
        ] = 0xD4CE430C3b67b3E2F7026D86E7128588629e2455; // REP/ETH

        _tokenPairAddress[0xC011a73ee8576Fb46F5E1c5751cA3B9Fe0af2a6F][
            _ETH_ADDRESS
        ] = 0x79291A9d692Df95334B1a0B3B4AE6bC606782f8c; // SNX/ETH
        _tokenPairAddress[0xC011a73ee8576Fb46F5E1c5751cA3B9Fe0af2a6F][
            _USD_ADDRESS
        ] = 0xDC3EA94CD0AC27d9A86C180091e7f78C683d3699; // SNX/USD
        _tokenPairAddress[0x8CE9137d39326AD0cD6491fb5CC0CbA0e089b6A9][
            _USD_ADDRESS
        ] = 0xFb0CfD6c19e25DB4a08D8a204a387cEa48Cc138f; // SXP/USD

        _tokenPairAddress[0x1f9840a85d5aF5bf1D1762F925BDADdC4201F984][
            _ETH_ADDRESS
        ] = 0xD6aA3D25116d8dA79Ea0246c4826EB951872e02e; // UNI/ETH
        _tokenPairAddress[_USD_ADDRESS][
            _ETH_ADDRESS
        ] = 0x986b5E1e1755e3C2440e960477f25201B0a8bbD4; // USDC/ETH

        _tokenPairAddress[0xa982B2e19e90b2D9F7948e9C1b65D119F1CE88D6][
            _ETH_ADDRESS
        ] = 0xcEBD2026d3C99F2a7CE028acf372C154aB4638a9; // WOM/ETH

        _tokenPairAddress[0x0bc529c00C6401aEF6D220BE8C6Ea1667F6Ad93e][
            _ETH_ADDRESS
        ] = 0x7c5d4F8345e66f68099581Db340cd65B078C41f4; // YFI/ETH

        _tokenPairAddress[0xE41d2489571d322189246DaFA5ebDe1F4699F498][
            _ETH_ADDRESS
        ] = 0x2Da4983a622a8498bb1a21FaE9D8F6C664939962; // ZRX/ETH
    }

    function addToken(
        address tokenAddressA,
        address tokenAddressB,
        address __tokenPairAddress
    ) public onlyOwner {
        _tokenPairAddress[tokenAddressA][tokenAddressB] = __tokenPairAddress;
    }

    // solhint-disable function-max-lines
    // solhint-disable code-complexity
    /// @dev Get expected return amount for tokenA / tokenB
    function getExpectedReturnAmount(
        uint256 amount,
        address tokenAddressA,
        address tokenAddressB
    ) public view returns (uint256 returnAmount) {
        require(amount > 0, "OracleAggregator: Amount is Zero");
        require(
            tokenAddressA != address(0),
            "OracleAggregator: tokenAddressA is Zero"
        );
        require(
            tokenAddressB != address(0),
            "OracleAggregator: tokenAddressB is Zero"
        );

        uint256 nrOfDecimalsIn;
        if (tokenAddressA != _ETH_ADDRESS) {
            try ERC20(tokenAddressA).decimals() returns (uint8 _inputDecimals) {
                nrOfDecimalsIn = uint256(_inputDecimals);
            } catch {
                revert("OracleAggregator: ERC20.decimals() revert");
            }
        } else {
            nrOfDecimalsIn = 18;
        }

        address stableCoinAddress =
            _nrOfDecimalsUSD[tokenAddressB] > 0 ? tokenAddressB : address(0);

        (tokenAddressA, tokenAddressB) = _convertUSD(
            tokenAddressA,
            tokenAddressB
        );

        // when token_b is ETH or USD
        if (tokenAddressB == _ETH_ADDRESS || tokenAddressB == _USD_ADDRESS) {
            // oracle of token_a / token_b exists
            // e.g. calculating KNC/ETH
            // KNC/ETH oracle available
            if (_tokenPairAddress[tokenAddressA][tokenAddressB] != address(0)) {
                (uint256 returnRateA, uint256 nrOfDecimals) =
                    _getRate(tokenAddressA, tokenAddressB);

                returnAmount = stableCoinAddress != address(0)
                    ? _matchStableCoinDecimal(
                        stableCoinAddress,
                        amount,
                        nrOfDecimals,
                        0,
                        returnRateA,
                        1
                    )
                    : amount.mul(returnRateA);

                nrOfDecimals = stableCoinAddress != address(0)
                    ? _nrOfDecimalsUSD[stableCoinAddress]
                    : nrOfDecimals;

                return (returnAmount.div(10**nrOfDecimalsIn));
            } else {
                // oracle of token_a / token_b does not exist
                // e.g. calculating UNI/USD
                // UNI/ETH and USD/ETH oracles available
                (address pairA, address pairB) =
                    _checkAvailablePair(tokenAddressA, tokenAddressB);
                if (pairA == address(0) && pairB == address(0)) return (0);

                (uint256 returnRateA, ) = _getRate(tokenAddressA, pairA);

                (uint256 returnRateB, uint256 nrOfDecimals) =
                    _getRate(tokenAddressB, pairB);

                returnAmount = stableCoinAddress != address(0)
                    ? _matchStableCoinDecimal(
                        stableCoinAddress,
                        amount,
                        nrOfDecimals,
                        nrOfDecimals,
                        returnRateA,
                        returnRateB
                    )
                    : amount.mul(returnRateA.mul(10**nrOfDecimals)).div(
                        returnRateB
                    );

                nrOfDecimals = stableCoinAddress != address(0)
                    ? _nrOfDecimalsUSD[stableCoinAddress]
                    : nrOfDecimals;

                returnAmount = amount
                    .mul(returnRateA.mul(10**nrOfDecimals))
                    .div(returnRateB);
                if (tokenAddressB != _ETH_ADDRESS) {
                    return (returnAmount.div(10**nrOfDecimalsIn));
                } else {
                    return returnAmount.div(10**_nrOfDecimalsUSD[_USD_ADDRESS]);
                }
            }
        } else {
            // when token_b is not ETH or USD
            (address pairA, address pairB) =
                _checkAvailablePair(tokenAddressA, tokenAddressB);

            if (pairA == address(0) && pairB == address(0)) return (0);
            // oracle of token_a/ETH, token_b/ETH || token_a/USD, token_b/USD exists
            // e.g. calculating KNC/UNI where
            // KNC/ETH and UNI/ETH oracles available
            if (pairA == pairB) {
                (uint256 returnRateA, uint256 nrOfDecimals) =
                    _getRate(tokenAddressA, pairA);

                (uint256 returnRateB, ) = _getRate(tokenAddressB, pairB);

                returnAmount = amount
                    .mul(returnRateA.mul(10**nrOfDecimals))
                    .div(returnRateB);
                if (pairA == _ETH_ADDRESS) {
                    return returnAmount.div(10**nrOfDecimalsIn);
                } else {
                    return returnAmount.div(10**_nrOfDecimalsUSD[_USD_ADDRESS]);
                }
            } else if (pairA == _ETH_ADDRESS && pairB == _USD_ADDRESS) {
                // oracle of token_a/ETH and token_b/USD exists
                // e.g. calculating UNI/SXP where
                // UNI/ETH and SXP/USD oracles available
                {
                    (uint256 returnRateA, ) = _getRate(tokenAddressA, pairA);
                    (uint256 returnRate_ETHUSD, ) =
                        _getRate(_ETH_ADDRESS, _USD_ADDRESS);
                    (uint256 returnRateB, ) = _getRate(tokenAddressB, pairB);

                    uint256 returnRateAUSD = returnRateA.mul(returnRate_ETHUSD);
                    returnAmount = amount.mul(returnRateAUSD).div(returnRateB);
                }
                return returnAmount.div(10**nrOfDecimalsIn);
            } else if (pairA == _USD_ADDRESS && pairB == _ETH_ADDRESS) {
                // oracle of token_a/USD and token_b/ETH exists
                // e.g. calculating SXP/UNI where
                // SXP/USD and UNI/ETH oracles available
                uint256 numerator;
                {
                    (uint256 returnRateA, uint256 nrOfDecimals) =
                        _getRate(tokenAddressA, pairA);

                    (uint256 returnRate_USDETH, uint256 nrOfDecimals_USDETH) =
                        _getRate(_USD_ADDRESS, _ETH_ADDRESS);

                    numerator = returnRate_USDETH
                        .mul(10**(nrOfDecimals_USDETH.sub(nrOfDecimals)))
                        .mul(returnRateA)
                        .div(10**nrOfDecimals_USDETH);
                }
                (uint256 returnRateB, ) = _getRate(tokenAddressB, pairB);
                returnAmount = amount.mul(numerator).div(returnRateB);
                return returnAmount;
            }
        }
    }

    /// @dev check the available oracles for token a & b
    /// and choose which oracles to use
    function _checkAvailablePair(address tokenAddressA, address tokenAddressB)
        private
        view
        returns (address, address)
    {
        if (
            _tokenPairAddress[tokenAddressA][_USD_ADDRESS] != address(0) &&
            _tokenPairAddress[tokenAddressB][_USD_ADDRESS] != address(0)
        ) {
            return (_USD_ADDRESS, _USD_ADDRESS);
        } else if (
            _tokenPairAddress[tokenAddressA][_ETH_ADDRESS] != address(0) &&
            _tokenPairAddress[tokenAddressB][_ETH_ADDRESS] != address(0)
        ) {
            return (_ETH_ADDRESS, _ETH_ADDRESS);
        } else if (
            _tokenPairAddress[tokenAddressA][_ETH_ADDRESS] != address(0) &&
            _tokenPairAddress[tokenAddressB][_USD_ADDRESS] != address(0)
        ) {
            return (_ETH_ADDRESS, _USD_ADDRESS);
        } else if (
            _tokenPairAddress[tokenAddressA][_USD_ADDRESS] != address(0) &&
            _tokenPairAddress[tokenAddressB][_ETH_ADDRESS] != address(0)
        ) {
            return (_USD_ADDRESS, _ETH_ADDRESS);
        } else {
            return (address(0), address(0));
        }
    }

    function _getRate(address tokenAddressA, address tokenAddressB)
        private
        view
        returns (uint256 tokenPrice, uint256 nrOfDecimals)
    {
        if (tokenAddressA == tokenAddressB) {
            return (1, 0);
        } else {
            IGasPriceOracle priceFeed =
                IGasPriceOracle(
                    _tokenPairAddress[tokenAddressA][tokenAddressB]
                );
            tokenPrice = uint256(priceFeed.latestAnswer());
            nrOfDecimals = priceFeed.decimals();
        }
    }

    /// @dev converting all usd pegged stablecoins to single USD address
    function _convertUSD(address tokenAddressA, address tokenAddressB)
        private
        view
        returns (address, address)
    {
        if (
            _nrOfDecimalsUSD[tokenAddressA] > 0 &&
            _nrOfDecimalsUSD[tokenAddressB] > 0
        ) {
            return (_USD_ADDRESS, _USD_ADDRESS);
        } else if (_nrOfDecimalsUSD[tokenAddressA] > 0) {
            return (_USD_ADDRESS, tokenAddressB);
        } else if (_nrOfDecimalsUSD[tokenAddressB] > 0) {
            return (tokenAddressA, _USD_ADDRESS);
        } else {
            return (tokenAddressA, tokenAddressB);
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
                ? 10**(_nrOfDecimalsUSD[stableCoinAddress] - nrOfDecimals)
                : 10**(nrOfDecimals - _nrOfDecimalsUSD[stableCoinAddress]);
        returnAmount = _nrOfDecimalsUSD[stableCoinAddress] > nrOfDecimals
            ? amount.mul(returnRateA.mul(10**padding)).div(returnRateB).mul(div)
            : amount.mul(returnRateA.mul(10**padding)).div(returnRateB).div(
                div
            );
    }
}
