// SPDX-License-Identifier: Apache-2.0

/******************************************************************************
 * Copyright 2022 IEXEC BLOCKCHAIN TECH                                       *
 *                                                                            *
 * Licensed under the Apache License, Version 2.0 (the "License");            *
 * you may not use this file except in compliance with the License.           *
 * You may obtain a copy of the License at                                    *
 *                                                                            *
 *     http://www.apache.org/licenses/LICENSE-2.0                             *
 *                                                                            *
 * Unless required by applicable law or agreed to in writing, software        *
 * distributed under the License is distributed on an "AS IS" BASIS,          *
 * WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.   *
 * See the License for the specific language governing permissions and        *
 * limitations under the License.                                             *
 ******************************************************************************/

pragma solidity ^0.8.0;

import "./Ownable.sol";
import "./ERC2771Context.sol";
import "./GenericOracle.sol";
import "./IERC1154.sol";
//TODO: Replace with @iexec/solidity when this dependency is migrated to solidity 0.8.0 and latest OpenZeppelin
//import "./IERC1154.sol";

import "./console.sol";

contract SingleReporterOracle is GenericOracle, IOracleConsumer, ERC2771Context {
    // Authorized address to report result
    address public authorizedReporter;

    constructor(address _authorizedReporter, address _trustedForwarder)
        ERC2771Context(_trustedForwarder)
    {
        //might be deployed without forwarder, but reporter is required
        require(_authorizedReporter != address(0));
        authorizedReporter = _authorizedReporter;
        console.log("Authorized reporter (custom): %s", authorizedReporter);
    }

    modifier onlyAuthorizedReporter() {
        require(
            _msgSender() == authorizedReporter,
            "Reporter is not authorized"
        );
        _;
    }

    // ERC1154 - Callback processing
    function receiveResult(bytes32 _callID, bytes memory callback)
        external
        override
        onlyAuthorizedReporter
    {
        // Parse results
        (bytes32 id, uint256 date, bytes memory value) = abi.decode(
            callback,
            (bytes32, uint256, bytes)
        );
        
        _updateValue(id, _callID, date, value);
    }

}
