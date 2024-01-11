// SPDX-License-Identifier: Apache-2.0
/*

  Copyright 2022 Element.Market

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

pragma solidity ^0.8.13;

interface IAuthenticatedProxy {

    function implementation() external view returns (address);

    /**
     * Execute a message call from the proxy contract
     *
     * @dev Can be called by the user, or by a contract authorized by the registry as long as the user has not revoked access
     * @param dest Address to which the call will be sent
     * @param howToCall 0 - Call, 1 - DelegateCall
     * @param data Calldata to send
     * @return result Result of the call (success or failure)
     */
    function proxy(address dest, uint8 howToCall, bytes calldata data) external returns (bool);

    /**
     * Execute a message call and assert success
     *
     * @dev Same functionality as `proxy`, just asserts the return value
     * @param dest Address to which the call will be sent
     * @param howToCall 0 - Call, 1 - DelegateCall
     * @param data Calldata to send
     */
    function proxyAssert(address dest, uint8 howToCall, bytes calldata data) external;
}