/*
    Copyright 2022 Set Labs Inc.

    Licensed under the Apache License, Version 2.0 (the "License");
    you may not use this file except in compliance with the License.
    You may obtain a copy of the License at

    http://www.apache.org/licenses/LICENSE-2.0

    Unless required by applicable law or agreed to in writing, software
    distributed under the License is distributed on an "AS IS" BASIS,
    WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
    See the License for the specific language governing permissions and
    limitations under the License.

    SPDX-License-Identifier: Apache License, Version 2.0
*/

pragma solidity 0.6.10;
pragma experimental "ABIEncoderV2";

import "./IJasperVault.sol";
import "./IGMXAdapter.sol";

import "./IWETH.sol";

interface IGMXModule {
    function weth() external view returns (IWETH);

    function increasingPosition(
        IJasperVault _jasperVault,
        IGMXAdapter.IncreasePositionRequest memory request
    ) external;

    function decreasingPosition(
        IJasperVault _jasperVault,
        IGMXAdapter.DecreasePositionRequest memory request
    ) external;

    function swap(
        IJasperVault _jasperVault,
        IGMXAdapter.SwapData memory data
    ) external;

    function creatOrder(
        IJasperVault _jasperVault,
        IGMXAdapter.CreateOrderData memory data
    ) external;

    function stakeGMX(
        IJasperVault _jasperVault,
        IGMXAdapter.StakeGMXData memory data
    ) external;

    function stakeGLP(
        IJasperVault _jasperVault,
        IGMXAdapter.StakeGLPData memory data
    ) external;

    function handleRewards(
        IJasperVault _jasperVault,
        IGMXAdapter.HandleRewardData memory data
    ) external;

    function initialize(IJasperVault _jasperVault) external;
}
