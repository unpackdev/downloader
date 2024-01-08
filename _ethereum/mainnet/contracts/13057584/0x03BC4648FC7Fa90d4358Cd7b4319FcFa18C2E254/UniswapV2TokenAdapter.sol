// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "./UniswapV2Library.sol";
import "./ICSSRRouter.sol";
import "./ICSSRAdapter.sol";
import "./IUniswapV2CSSR.sol";
import "./IGovernanceOwned.sol";

contract UniswapV2TokenAdapter is ICSSRAdapter {
    IGovernanceOwned public immutable owned;
    ICSSRRouter public immutable cssrRouter;
    IUniswapV2CSSR public immutable uniswapCSSR;

    address[] public keyCurrency;
    mapping(address => bool) public isKeyCurrency;
    mapping(address => uint256) public minimumLiquidity;

    modifier onlyGov() {
        require(msg.sender == owned.governance(), "!gov");
        _;
    }

    constructor(
        address _owned,
        address _router,
        address _uniCSSR
    ) {
        owned = IGovernanceOwned(_owned);
        cssrRouter = ICSSRRouter(_router);
        uniswapCSSR = IUniswapV2CSSR(_uniCSSR);
    }

    function addKeyCurrency(address _currency) external onlyGov {
        keyCurrency.push(_currency);
        isKeyCurrency[_currency] = true;
    }

    function removeKeyCurrency(uint256 _idx, address _currency)
        external
        onlyGov
    {
        require(keyCurrency[_idx] == _currency, "!match");
        keyCurrency[_idx] = keyCurrency[keyCurrency.length - 1];
        keyCurrency.pop();
        isKeyCurrency[_currency] = false;
    }

    function setMinimumLiquidity(address _currency, uint256 _liquidity)
        external
        onlyGov
    {
        minimumLiquidity[_currency] = _liquidity;
    }

    function support(address _asset) external view override returns (bool) {
        // check if liquidity passes the minimum
        for (uint256 i = 0; i < keyCurrency.length; i++) {
            if (aboveLiquidity(_asset, keyCurrency[i])) {
                return true;
            }
        }
        return false;
    }

    function update(address _asset, bytes memory _data)
        external
        override
        returns (float memory)
    {
        (
            address p,
            bytes memory bd,
            bytes memory ap,
            bytes memory rp,
            bytes memory pp0,
            bytes memory pp1
        ) = abi.decode(_data, (address, bytes, bytes, bytes, bytes, bytes));
        require(isKeyCurrency[p], "!keyCurrency");
        (, uint256 bn, ) = uniswapCSSR.saveState(bd);
        address pair = UniswapV2Library.pairFor(
            uniswapCSSR.uniswapFactory(),
            _asset,
            p
        );
        uniswapCSSR.saveReserve(bn, pair, ap, rp, pp0, pp1);
        return getPrice(_asset);
    }

    function getPriceRaw(address _asset)
        public
        view
        returns (uint256 sumPrice, uint256 sumLiquidity)
    {
        for (uint256 i = 0; i < keyCurrency.length; i++) {
            address key = keyCurrency[i];
            if (_asset == key) {
                continue;
            }
            try uniswapCSSR.getLiquidity(_asset, key) returns (uint256 liq) {
                if (liq >= minimumLiquidity[key]) {
                    float memory currencyPrice = cssrRouter.getPrice(key);
                    uint256 liquidityValue = convertToValue(liq, currencyPrice);
                    sumLiquidity += liquidityValue;
                    sumPrice +=
                        convertToValue(
                            uniswapCSSR.getExchangeRatio(_asset, key),
                            currencyPrice
                        ) *
                        liquidityValue;
                }
            } catch {
                continue;
            }
        }
    }

    function getPrice(address _asset)
        public
        view
        override
        returns (float memory price)
    {
        (uint256 sumPrice, uint256 sumLiquidity) = getPriceRaw(_asset);
        require(sumLiquidity > 0, "!updated");
        return float({numerator: sumPrice / 2**112, denominator: sumLiquidity});
    }

    function getLiquidity(address _asset)
        external
        view
        override
        returns (uint256 sum)
    {
        for (uint256 i = 0; i < keyCurrency.length; i++) {
            address key = keyCurrency[i];
            if (_asset == key) {
                continue;
            }
            try uniswapCSSR.getLiquidity(_asset, key) returns (uint256 liq) {
                if (liq >= minimumLiquidity[key]) {
                    sum += convertToValue(liq, cssrRouter.getPrice(key));
                }
            } catch {
                continue;
            }
        }
    }

    function aboveLiquidity(address _asset, address _pairedWith)
        public
        view
        returns (bool)
    {
        try uniswapCSSR.getLiquidity(_asset, _pairedWith) returns (
            uint256 liq
        ) {
            return liq >= minimumLiquidity[_pairedWith];
        } catch {
            return false;
        }
    }

    function convertToValue(uint256 _amount, float memory _price)
        internal
        pure
        returns (uint256)
    {
        return (_amount * _price.numerator) / _price.denominator;
    }
}
