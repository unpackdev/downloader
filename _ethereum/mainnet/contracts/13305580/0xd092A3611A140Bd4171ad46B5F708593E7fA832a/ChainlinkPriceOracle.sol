// Copyright 2021 Cartesi Pte. Ltd.

// SPDX-License-Identifier: Apache-2.0
// Licensed under the Apache License, Version 2.0 (the "License"); you may not use
// this file except in compliance with the License. You may obtain a copy of the
// License at http://www.apache.org/licenses/LICENSE-2.0

// Unless required by applicable law or agreed to in writing, software distributed
// under the License is distributed on an "AS IS" BASIS, WITHOUT WARRANTIES OR
// CONDITIONS OF ANY KIND, either express or implied. See the License for the
// specific language governing permissions and limitations under the License.

pragma solidity ^0.8.0;

import "./AggregatorInterface.sol";
import "./PriceOracle.sol";

contract ChainlinkPriceOracle is PriceOracle {
    AggregatorInterface public immutable oracle;

    constructor(address _oracle) {
        oracle = AggregatorInterface(_oracle);
    }

    /// @notice Returns latest ETH/CTSI price
    /// @return value of CTSI price in ETH
    function getPrice() external view override returns (uint256) {
        // get gas price from chainlink oracle
        // https://data.chain.link/ethereum/mainnet/crypto-eth/ctsi-eth
        return uint256(oracle.latestAnswer());
    }
}
