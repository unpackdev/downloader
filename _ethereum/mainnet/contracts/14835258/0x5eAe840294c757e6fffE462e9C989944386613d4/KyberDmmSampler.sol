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

interface IKyberDmmRouter {
    function getAmountsOut(
        uint256 amountIn,
        address[] calldata pools,
        address[] calldata path
    ) external view returns (uint256[] memory amounts);
}

contract KyberDmmSampler {
    /// @dev Gas limit for KyberDmm calls.
    uint256 private constant KYBER_DMM_CALL_GAS = 150e3; // 150k
    struct KyberDmmSamplerOpts {
        address pool;
        IKyberDmmRouter router;
    }

    /// @dev Sample sell quotes from KyberDmm.
    /// @param opts Router to look up tokens and amounts
    /// @param takerTokenAmounts Taker token sell amount for each sample.
    /// @return makerTokenAmounts Maker amounts bought at each taker token
    ///         amount.
    function sampleSellsFromKyberDmm(
        KyberDmmSamplerOpts memory opts,
        address takerToken,
        address makerToken,
        uint256[] memory takerTokenAmounts
    ) public view returns (uint256[] memory makerTokenAmounts) {
        uint256 numSamples = takerTokenAmounts.length;
        makerTokenAmounts = new uint256[](numSamples);
        address[] memory pools = new address[](1);
        address[] memory path = new address[](2);
        pools[0] = opts.pool;
        path[0] = takerToken;
        path[1] = makerToken;
        for (uint256 i = 0; i < numSamples; i++) {
            try
                opts.router.getAmountsOut{gas: KYBER_DMM_CALL_GAS}(
                    takerTokenAmounts[i],
                    pools,
                    path
                )
            returns (uint256[] memory amounts) {
                makerTokenAmounts[i] = amounts[1];
            } catch (bytes memory) {}
            // Break early if there are 0 amounts
            if (makerTokenAmounts[i] == 0) {
                break;
            }
        }
    }
}
