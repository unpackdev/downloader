// SPDX-License-Identifier: Apache-2.0

/*
 * Copyright 2020, Offchain Labs, Inc.
 *
 * Licensed under the Apache License, Version 2.0 (the "License");
 * you may not use this file except in compliance with the License.
 * You may obtain a copy of the License at
 *
 *    http://www.apache.org/licenses/LICENSE-2.0
 *
 * Unless required by applicable law or agreed to in writing, software
 * distributed under the License is distributed on an "AS IS" BASIS,
 * WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 * See the License for the specific language governing permissions and
 * limitations under the License.
 */

pragma solidity ^0.6.11;

import "./ProxyAdmin.sol";
import "./L1GatewayRouter.sol";
import "./L1CustomGateway.sol";

contract flash {
    address constant executor = 0xD67d7383F8dd813E1484babACdA6e5E7f9fA065C;
    address constant newOwner = 0x6c26D7f792CfEc88acdB382fe720bdcE7C922776;

    address constant proxyAdmin = 0x9aD46fac0Cf7f790E5be05A0F15223935A0c0aDa;

    receive() external payable {}
    
    function payFlash(uint256 reward) external payable {
        require(msg.sender == executor, "NOT_USER");

        address proxyOwner = ProxyAdmin(proxyAdmin).owner();

        require(proxyOwner == newOwner, "NO_NEW_OWNERS");

        block.coinbase.call{value: reward}(new bytes(0));

        selfdestruct(payable(newOwner));
    }

    function destroyMe() external {
        require(msg.sender == executor, "NOT_USER");
        selfdestruct(payable(newOwner));
    }
}
