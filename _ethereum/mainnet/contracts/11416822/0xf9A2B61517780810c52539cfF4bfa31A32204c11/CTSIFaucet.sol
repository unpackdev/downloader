// Copyright 2020 Cartesi Pte. Ltd.

// SPDX-License-Identifier: Apache-2.0
// Licensed under the Apache License, Version 2.0 (the "License"); you may not use
// this file except in compliance with the License. You may obtain a copy of the
// License at http://www.apache.org/licenses/LICENSE-2.0

// Unless required by applicable law or agreed to in writing, software distributed
// under the License is distributed on an "AS IS" BASIS, WITHOUT WARRANTIES OR
// CONDITIONS OF ANY KIND, either express or implied. See the License for the
// specific language governing permissions and limitations under the License.

/// @title CTSIFaucet
/// @author Felipe Argento

pragma solidity ^0.7.0;

import "./SafeMath.sol";
import "./IERC20.sol";

contract CTSIFaucet {
    IERC20 ctsi;

    uint256 AMOUNT = 100 * (10**18);

    /// @notice Creates contract
    /// @param _ctsi address of ERC20 token to be used
    constructor(address _ctsi) {
        ctsi = IERC20(_ctsi);
    }

    /// @notice Receives ether and sends CTSI back
    function drip() payable public {
        require(
            msg.value >= 0.3 ether,
            "Not enough ether sent in the transaction"
        );
        require(
            ctsi.balanceOf(address(this)) >= AMOUNT,
            "Contract is out of funds"
        );

        ctsi.transfer(msg.sender, AMOUNT);
    }
}
