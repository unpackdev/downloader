// SPDX-License-Identifier: Apache-2.0
/*

  Copyright 2020 ZeroEx Intl.
  Modifications copyright (C) 2022 TheOpenDAO

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

pragma solidity ^0.6.5;
pragma experimental ABIEncoderV2;

import "./IOwnableFeature.sol";
import "./ISimpleFunctionRegistryFeature.sol";
import "./ITokenSpenderFeature.sol";
import "./IERC721OrdersFeature.sol";
import "./IERC1155OrdersFeature.sol";
import "./IERC165Feature.sol";
import "./INFTAuctionsFeature.sol";
import "./INFTToolsFeature.sol";


/// @dev Interface for a fully featured Exchange Proxy.
interface IZeroEx is
    IOwnableFeature,
    ISimpleFunctionRegistryFeature,
    IERC721OrdersFeature,
    IERC1155OrdersFeature,
    IERC165Feature,
    INFTAuctionsFeature,
    INFTToolsFeature
{
    // solhint-disable state-visibility

    /// @dev Fallback for just receiving ether.
    receive() external payable;
}
