// Copyright 2021 Cartesi Pte. Ltd.

// SPDX-License-Identifier: Apache-2.0
// Licensed under the Apache License, Version 2.0 (the "License"); you may not use
// this file except in compliance with the License. You may obtain a copy of the
// License at http://www.apache.org/licenses/LICENSE-2.0

// Unless required by applicable law or agreed to in writing, software distributed
// under the License is distributed on an "AS IS" BASIS, WITHOUT WARRANTIES OR
// CONDITIONS OF ANY KIND, either express or implied. See the License for the
// specific language governing permissions and limitations under the License.

/// @title Gas tax based commission model
pragma solidity ^0.8.0;

import "./IERC20.sol";
import "./Ownable.sol";
import "./Fee.sol";
import "./GasOracle.sol";
import "./PriceOracle.sol";

contract GasTaxCommission is Fee, Ownable {
    uint256 public immutable feeRaiseTimeout;
    uint256 public immutable maxRaise; // 21000 is one simple tx
    GasOracle public immutable gasOracle;

    PriceOracle public immutable priceOracle;
    uint256 public timeoutTimestamp;

    uint256 public gas;

    /// @notice event fired when setGas function is called and successful
    /// @param timeout timestamp for a new change if raising the fee
    event GasTaxChanged(uint256 newGas, uint256 timeout);

    constructor(
        address _gasOracle,
        address _priceOracle,
        uint256 _gas,
        uint256 _feeRaiseTimeout,
        uint256 _maxRaise
    ) {
        gasOracle = GasOracle(_gasOracle);
        priceOracle = PriceOracle(_priceOracle);
        gas = _gas;
        feeRaiseTimeout = _feeRaiseTimeout;
        maxRaise = _maxRaise;
        emit GasTaxChanged(_gas, timeoutTimestamp);
    }

    /// @notice calculates the total amount of the reward that will be directed to the PoolManager
    /// @return commissionTotal is the amount subtracted from the rewardAmount
    function getCommission(uint256, uint256 rewardAmount)
        external
        view
        override
        returns (uint256)
    {
        // get gas price (in Wei) from chainlink oracle, at https://data.chain.link/fast-gas-gwei
        uint256 gasPrice = gasOracle.getGasPrice();

        // gas fee (in Wei) charged by pool manager
        uint256 gasFee = gasPrice * gas;

        // get Wei price of 1 CTSI
        uint256 ctsiPrice = priceOracle.getPrice();

        // convert gas in Wei to gas in CTSI
        uint256 gasFeeCTSI = ctsiPrice > 0
            ? (gasFee * (10**18)) / ctsiPrice
            : 0;

        // this is the commission, maxed by the reward
        return gasFeeCTSI > rewardAmount ? rewardAmount : gasFeeCTSI;
    }

    /// @notice allows for the poolManager to reduce how much they want to charge for the block production tx
    function setGas(uint256 newGasCommission) external onlyOwner {
        if (newGasCommission > gas) {
            require(
                timeoutTimestamp <= block.timestamp,
                "GasTaxCommission: the fee raise timeout is not expired yet"
            );
            require(
                (newGasCommission - gas) <= maxRaise,
                "GasTaxCommission: the fee raise is over the maximum allowed gas value"
            );
            timeoutTimestamp = block.timestamp + feeRaiseTimeout;
        }
        gas = newGasCommission;
        emit GasTaxChanged(newGasCommission, timeoutTimestamp);
    }
}
