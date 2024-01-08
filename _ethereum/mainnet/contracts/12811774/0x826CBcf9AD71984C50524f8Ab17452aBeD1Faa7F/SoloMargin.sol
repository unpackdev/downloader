/*

    Copyright 2019 dYdX Trading Inc.

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

pragma solidity 0.5.7;
pragma experimental ABIEncoderV2;

import "./Admin.sol";
import "./Getters.sol";
import "./Operation.sol";
import "./Permission.sol";
import "./State.sol";
import "./Storage.sol";


/**
 * @title SoloMargin
 * @author dYdX
 *
 * Main contract that inherits from other contracts
 */
contract SoloMargin is
    State,
    Admin,
    Getters,
    Operation,
    Permission
{
    // ============ Constructor ============

    constructor(
        Storage.RiskParams memory riskParams,
        Storage.RiskLimits memory riskLimits
    )
        public
    {
        g_state.riskParams = riskParams;
        g_state.riskLimits = riskLimits;
    }
}
