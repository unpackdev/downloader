/*
  Copyright 2019-2023 StarkWare Industries Ltd.

  Licensed under the Apache License, Version 2.0 (the "License").
  You may not use this file except in compliance with the License.
  You may obtain a copy of the License at

  https://www.starkware.co/open-source-license/

  Unless required by applicable law or agreed to in writing,
  software distributed under the License is distributed on an "AS IS" BASIS,
  WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
  See the License for the specific language governing permissions
  and limitations under the License.
*/
// SPDX-License-Identifier: Apache-2.0.
pragma solidity ^0.8.0;

import "./NamedStorage.sol";

/*
  Holds the Proxy-specific state variables.
  to prevent collision hazard.
*/
contract ProxyStorage {
    // Random storage slot tags.
    string constant ENABLED_TIME_TAG = "PROXY_5_ENABLED_TIME";
    string constant DISABLED_TIME_TAG = "PROXY_5_DISABLED_TIME";
    string constant INTIALIZED_TAG = "PROXY_5_INITIALIZED";

    // The time after which we can switch to the implementation.
    // Hash(implementation, data, finalize) => time.
    function enabledTime() internal pure returns (mapping(bytes32 => uint256) storage) {
        return NamedStorage.bytes32ToUint256Mapping(ENABLED_TIME_TAG);
    }

    // The time after which we can NO LONGER switch to the implementation.
    // Implementation is valid to switch in time t,  enableTime <= t  <= disableTime.
    // Hash(implementation, data, finalize) => time.
    function expirationTime() internal pure returns (mapping(bytes32 => uint256) storage) {
        return NamedStorage.bytes32ToUint256Mapping(DISABLED_TIME_TAG);
    }

    // A central storage of the flags whether implementation has been initialized.
    // Note - it can be used flexibly enough to accommodate multiple levels of initialization
    // (i.e. using different key salting schemes for different initialization levels).
    function initialized() internal pure returns (mapping(bytes32 => bool) storage) {
        return NamedStorage.bytes32ToBoolMapping(INTIALIZED_TAG);
    }
}
