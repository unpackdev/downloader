// Copyright (C) 2021 Exponent

// This file is part of Exponent.

// Exponent is free software: you can redistribute it and/or modify
// it under the terms of the GNU General Public License as published by
// the Free Software Foundation, either version 3 of the License, or
// (at your option) any later version.

// Exponent is distributed in the hope that it will be useful,
// but WITHOUT ANY WARRANTY; without even the implied warranty of
// MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
// GNU General Public License for more details.

// You should have received a copy of the GNU General Public License
// along with Exponent.  If not, see <http://www.gnu.org/licenses/>.

pragma solidity 0.8.0;

import "./XPNUtils.sol";
import "./console.sol";
import "./ISignal.sol";
import "./XPNSignalMath.sol";
import "./IERC20Metadata.sol";

// @notice portfolio module.
abstract contract XPNPortfolio {
    using XPNSignalMath for int256[];
    int256 constant ONE = 1e18;

    function _getVaultAddress() internal view virtual returns (address) {}

    function _getExpectedEfficiency() internal view virtual returns (int256) {}

    function _getSignal() internal view virtual returns (int256[] memory) {}

    function _getSignalSymbols()
        internal
        view
        virtual
        returns (string[] memory)
    {}

    function _getSymbolToToken(string memory _symbol)
        internal
        view
        virtual
        returns (address)
    {}

    // @dev assume 18 decimal
    function _getTokenPrice(address _asset)
        internal
        view
        virtual
        returns (int256)
    {}

    function _getDenomAssetSymbol()
        internal
        view
        virtual
        returns (string memory)
    {}

    // @notice list balance of each erc20 token in vault based on target signal asset list
    // @dev use signal meta data as reference to fetch. will not fetch token that not in signal.
    // @return int256 array of balance of each erc20
    function _viewPortfolioToken()
        internal
        view
        virtual
        returns (int256[] memory)
    {
        /*
        return amount of each asset. (in token)
        */
        string[] memory symbols = _getSignalSymbols();
        int256[] memory tokens = new int256[](symbols.length);

        for (uint256 i = 0; i < symbols.length; i++) {
            IERC20Metadata tmpToken = IERC20Metadata(
                _getSymbolToToken(symbols[i])
            );
            uint256 tokenDecimals = uint256(tmpToken.decimals());
            int256 rawBalance = int256(tmpToken.balanceOf(_getVaultAddress()));

            int256 convertedBalance = (rawBalance * ONE) /
                int256(10**tokenDecimals);

            tokens[i] = int256(convertedBalance);
        }
        return tokens;
    }

    // @notice list token price in denominated asset of each erc20 token in vault based on target signal asset list
    // @dev use signal meta data as reference to fetch. will not fetch token that not in signal.
    //assume correct price feed. (correct base and quote asset)
    // @return int256 array of price of each erc20 in denominated asset
    function _getTokensPrice() internal view virtual returns (int256[] memory) {
        string[] memory symbols = _getSignalSymbols();
        int256[] memory prices = new int256[](symbols.length);
        // resolves symbol to asset token
        for (uint256 i; i < symbols.length; i++) {
            string memory symbol = symbols[i];
            if (XPNUtils.compareStrings(symbol, _getDenomAssetSymbol())) {
                prices[i] = ONE;
                continue;
            }
            int256 price = _getTokenPrice(_getSymbolToToken(symbol));
            prices[i] = price;
        }
        return prices;
    }

    // @notice list value of each erc20 token in vault based on target signal asset list
    // @dev use signal meta data as reference to fetch. will not fetch token that not in signal.
    // @return int256 array value of each asset. (in denominated asset)
    function _viewPortfolioMixValue() internal view returns (int256[] memory) {
        /*
            return value of each asset. (in denominated asset) 
            */
        return _viewPortfolioToken().elementWiseMul(_getTokensPrice());
    }

    // @notice calculate current % allocation of vault.
    // @dev 100% = 1e18
    // @return int256 array % allocation of each asset
    function _viewPortfolioAllocation()
        internal
        view
        returns (int256[] memory)
    {
        /*
            return allocation of each asset. (in % of portfolio) - sum = 1e18
        */
        require(_portfolioValue() > 0, "vault is empty");
        return _viewPortfolioMixValue().normalize();
    }

    // @notice calculate different between current portfolio position and target from signal in % term
    // @dev 100% = 1e18
    // @return int256 array % different from target for each asset (directional)
    function _signalPortfolioDiffAllocation()
        internal
        view
        returns (int256[] memory)
    {
        /*
            get different in % allocation between master signal and current portfolio allocation
        */
        require(_portfolioValue() > 0, "vault is empty");

        return
            _getSignal().normalize().elementWiseSub(_viewPortfolioAllocation());
    }

    // @notice calculate different between current portfolio position and target from signal in denominated asset value
    // @dev 100% = 1e18
    // @return int256 array denominated asset value different from target for each asset (directional)
    function _signalPortfolioDiffValue()
        internal
        view
        returns (int256[] memory)
    {
        /*
            get different in value allocation between master signal and current portfolio allocation
        */
        require(_portfolioValue() > 0, "vault is empty");

        return _signalPortfolioDiffAllocation().vectorScale(_portfolioValue());
    }

    // @notice calculate different between current portfolio position and target from signal
    // in balance of coresponding erc20
    // @dev 100% = 1e18.
    // @return int256 array balance different from target for each asset (directional)
    function _signalPortfolioDiffToken()
        internal
        view
        returns (int256[] memory)
    {
        /*
            get different in token allocation between master signal and current portfolio allocation
        */
        require(_portfolioValue() > 0, "vault is empty");

        return _signalPortfolioDiffValue().elementWiseDiv(_getTokensPrice());
    }

    // @notice value of portfolio in denominated asset.
    // @dev only track asset that in signal list. for more reliable and complete view. pls use enzyme's
    // @return int256 portfolio value
    function _portfolioValue() internal view virtual returns (int256 value) {
        /*
            porfolio value in usd
        */
        value = _viewPortfolioMixValue().sum();
    }

    // @notice distance between current portfolio and target signal in % term
    // @dev 100% = 1e18.distance between target vs current portfolio allocation (how much value needed to be move)
    // calculate as sum(token-wise diff)/ 2
    // @return int256 distance
    function _signalPortfolioDiffPercent()
        internal
        view
        virtual
        returns (int256 distance)
    {
        require(_portfolioValue() > 0, "vault is empty");
        distance = _signalPortfolioDiffAllocation().l1Norm() / 2;
    }

    // @notice verification modifier that reverts if operations result does not improve distance
    //or cause higher than expected loss
    modifier ensureTrade() {
        int256 preTradeValue = _portfolioValue();
        int256 preTradeDistance = _signalPortfolioDiffPercent();
        _;
        int256 distanceImproved = preTradeDistance -
            _signalPortfolioDiffPercent();
        int256 valueLoss = preTradeValue - _portfolioValue();
        int256 expectedLoss = (((preTradeValue * distanceImproved) / ONE) *
            (ONE - _getExpectedEfficiency())) / ONE;

        require(
            distanceImproved > 0 && valueLoss < expectedLoss,
            "trade requirement not satisfied"
        );
    }
}
