// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.0;

import "./RoleAware.sol";
import "./MarginRouter.sol";
import "./UniswapStyleLib.sol";

/// Stores how many of token you could get for 1k of peg
struct TokenPrice {
    uint256 blockLastUpdated;
    uint256 tokenPerRefAmount;
    address[] liquidationTokens;
    bytes32 amms;
    address[] inverseLiquidationTokens;
    bytes32 inverseAmms;
}

struct VolatilitySetting {
    uint256 priceUpdateWindow;
    uint256 updateRatePermil;
}

/// @title The protocol features several mechanisms to prevent vulnerability to
/// price manipulation:
/// 1) global exposure caps on all tokens which need to be raised gradually
///    during the process of introducing a new token, making attacks unprofitable
///    due to lack  of scale
/// 2) Exponential moving average with cautious price update. Prices for estimating
///    how much a trader can borrow need not be extremely current and precise, mainly
///    they must be resilient against extreme manipulation
/// 3) Liquidators may not call from a contract address, to prevent extreme forms of
///    of front-running and other price manipulation.
abstract contract PriceAware is RoleAware {
    uint256 constant pegDecimals = 6;
    uint256 constant REFERENCE_PEG_AMOUNT = 100 * (10**pegDecimals);
    address public immutable peg;

    mapping(address => TokenPrice) public tokenPrices;
    /// update window in blocks

    uint256 public priceUpdateWindow = 20;
    uint256 public UPDATE_RATE_PERMIL = 50;
    VolatilitySetting[] public volatilitySettings;

    constructor(address _peg) {
        peg = _peg;
    }

    /// Set window for price updates
    function setPriceUpdateWindow(uint16 window) external onlyOwnerExec {
        priceUpdateWindow = window;
    }

    /// Add a new volatility setting
    function addVolatilitySetting(
        uint256 _priceUpdateWindow,
        uint256 _updateRatePermil
    ) external onlyOwnerExec {
        volatilitySettings.push(
            VolatilitySetting({
                priceUpdateWindow: _priceUpdateWindow,
                updateRatePermil: _updateRatePermil
            })
        );
    }

    /// Choose a volatitlity setting
    function chooseVolatilitySetting(uint256 index)
        external
        onlyOwnerExecDisabler
    {
        VolatilitySetting storage vs = volatilitySettings[index];
        if (vs.updateRatePermil > 0) {
            UPDATE_RATE_PERMIL = vs.updateRatePermil;
            priceUpdateWindow = vs.priceUpdateWindow;
        }
    }

    /// Set rate for updates
    function setUpdateRate(uint256 rate) external onlyOwnerExec {
        UPDATE_RATE_PERMIL = rate;
    }

    /// Get current price of token in peg
    function getCurrentPriceInPeg(address token, uint256 inAmount)
        public
        returns (uint256)
    {
        if (token == peg) {
            return inAmount;
        } else {
            TokenPrice storage tokenPrice = tokenPrices[token];

            if (
                block.number - tokenPrice.blockLastUpdated >
                priceUpdateWindow ||
                tokenPrice.tokenPerRefAmount == 0
            ) {
                // update the currently cached price
                getPriceFromAMM(tokenPrice);
            }

            return
                (inAmount * REFERENCE_PEG_AMOUNT) /
                (tokenPrice.tokenPerRefAmount + 1);
        }
    }

    /// Get view of current price of token in peg
    function viewCurrentPriceInPeg(address token, uint256 inAmount)
        public
        view
        returns (uint256)
    {
        if (token == peg) {
            return inAmount;
        } else {
            TokenPrice storage tokenPrice = tokenPrices[token];
            return
                (inAmount * REFERENCE_PEG_AMOUNT) /
                (tokenPrice.tokenPerRefAmount + 1);
        }
    }

    /// @dev retrieves the price from the AMM
    function getPriceFromAMM(TokenPrice storage tokenPrice) internal virtual {
        (uint256[] memory pathAmounts, ) =
            UniswapStyleLib.getAmountsIn(
                REFERENCE_PEG_AMOUNT,
                tokenPrice.amms,
                tokenPrice.liquidationTokens
            );
        _setPriceVal(tokenPrice, pathAmounts[0], UPDATE_RATE_PERMIL);
    }

    function _setPriceVal(
        TokenPrice storage tokenPrice,
        uint256 updatePerRefAmount,
        uint256 weightPerMil
    ) internal {
        tokenPrice.tokenPerRefAmount =
            (tokenPrice.tokenPerRefAmount *
                (1000 - weightPerMil) +
                updatePerRefAmount *
                weightPerMil) /
            1000;
    }

    /// add path from token to current liquidation peg
    function setLiquidationPath(bytes32 amms, address[] memory tokens)
        external
        onlyOwnerExecActivator
    {
        address token = tokens[0];

        if (token != peg) {
            TokenPrice storage tokenPrice = tokenPrices[token];

            tokenPrice.amms = amms;

            tokenPrice.liquidationTokens = tokens;
            tokenPrice.inverseLiquidationTokens = new address[](tokens.length);

            bytes32 inverseAmms;

            for (uint256 i = 0; tokens.length - 1 > i; i++) {
                bytes32 shifted =
                    bytes32(amms[i]) >> ((tokens.length - 2 - i) * 8);
                inverseAmms = inverseAmms | shifted;
            }

            tokenPrice.inverseAmms = inverseAmms;

            for (uint256 i = 0; tokens.length > i; i++) {
                tokenPrice.inverseLiquidationTokens[i] = tokens[
                    tokens.length - i - 1
                ];
            }

            (uint256[] memory pathAmounts, ) =
                UniswapStyleLib.getAmountsIn(
                    REFERENCE_PEG_AMOUNT,
                    amms,
                    tokens
                );
            uint256 inAmount = pathAmounts[0];

            _setPriceVal(tokenPrice, inAmount, 1000);
        }
    }

    function liquidateToPeg(address token, uint256 amount)
        internal
        returns (uint256)
    {
        if (token == peg) {
            return amount;
        } else {
            TokenPrice storage tP = tokenPrices[token];
            uint256[] memory amounts =
                MarginRouter(marginRouter()).authorizedSwapExactT4T(
                    amount,
                    0,
                    tP.amms,
                    tP.liquidationTokens
                );

            uint256 outAmount = amounts[amounts.length - 1];

            return outAmount;
        }
    }

    function liquidateFromPeg(address token, uint256 targetAmount)
        internal
        returns (uint256)
    {
        if (token == peg) {
            return targetAmount;
        } else {
            TokenPrice storage tP = tokenPrices[token];
            uint256[] memory amounts =
                MarginRouter(marginRouter()).authorizedSwapT4ExactT(
                    targetAmount,
                    type(uint256).max,
                    tP.amms,
                    tP.inverseLiquidationTokens
                );

            return amounts[0];
        }
    }
}
