// SPDX-License-Identifier: Apache-2.0
/*

  Copyright 2020 ZeroEx Intl.

  Licensed under the Apache License, Version 2.0 (the "License");
  you may not use this file except in compliance with the License.
  You may obtain a copy of the License at

    http://www.apache.org/licenses/LICENSE-2.0

  Unless required by applicable law or agreed to in writing, software
  distributed under the License is distributed on an "AS IS" BASIS,
  WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
  See the License for the specific language governing permissions and
  limitations under the License.

*/

pragma solidity ^0.8.0;
pragma experimental ABIEncoderV2;

interface IDODOZoo {
    function getDODO(address baseToken, address quoteToken)
        external
        view
        returns (address);
}

interface IDODOHelper {
    function querySellQuoteToken(address dodo, uint256 amount)
        external
        view
        returns (uint256);
}

interface IDODO {
    function querySellBaseToken(uint256 amount) external view returns (uint256);

    function _TRADE_ALLOWED_() external view returns (bool);

    function _BASE_TOKEN_() external view returns (address);

    function _QUOTE_TOKEN_() external view returns (address);
}

contract DODOSampler {
    /// @dev Gas limit for DODO calls.
    uint256 private constant DODO_CALL_GAS = 300e3; // 300k
    struct DODOSamplerOpts {
        address pool;
        address helper;
    }

    /// @dev Sample sell quotes from DODO.
    /// @param opts DODOSamplerOpts DODO Registry and helper addresses
    /// @param takerTokenAmounts Taker token sell amount for each sample.
    /// @return makerTokenAmounts Maker amounts bought at each taker token
    ///         amount.
    function sampleSellsFromDODO(
        DODOSamplerOpts memory opts,
        address takerToken,
        address makerToken,
        uint256[] memory takerTokenAmounts
    ) public view returns (uint256[] memory makerTokenAmounts) {
        uint256 numSamples = takerTokenAmounts.length;
        makerTokenAmounts = new uint256[](numSamples);

        // DODO Pool has been disabled
        if (!IDODO(opts.pool)._TRADE_ALLOWED_()) {
            return makerTokenAmounts;
        }

        bool sellBase;
        if (IDODO(opts.pool)._BASE_TOKEN_() == takerToken) {
            require(
                IDODO(opts.pool)._QUOTE_TOKEN_() == makerToken,
                "trade condition check failed"
            );
            sellBase = true;
        } else {
            require(
                IDODO(opts.pool)._QUOTE_TOKEN_() == takerToken,
                "trade condition check failed"
            );
            require(
                IDODO(opts.pool)._BASE_TOKEN_() == makerToken,
                "trade condition check failed"
            );
            sellBase = false;
        }

        for (uint256 i = 0; i < numSamples; i++) {
            if (sellBase) {
                try
                    IDODO(opts.pool).querySellBaseToken{gas: DODO_CALL_GAS}(
                        takerTokenAmounts[i]
                    )
                returns (uint256 amount) {
                    makerTokenAmounts[i] = amount;
                } catch (bytes memory) {}
            } else {
                try
                    IDODOHelper(opts.helper).querySellQuoteToken{
                        gas: DODO_CALL_GAS
                    }(opts.pool, takerTokenAmounts[i])
                returns (uint256 amount) {
                    makerTokenAmounts[i] = amount;
                } catch (bytes memory) {}
            }
            // Break early if there are 0 amounts
            if (makerTokenAmounts[i] == 0) {
                break;
            }
        }
    }
}
