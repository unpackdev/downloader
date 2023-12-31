/*
    Copyright 2021 Set Labs Inc.

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

pragma solidity 0.6.10;
pragma experimental "ABIEncoderV2";

import "./FlexibleLeverageStrategyExtension.sol";

interface IFLIStrategyExtension {
    function getStrategy() external view returns (FlexibleLeverageStrategyExtension.ContractSettings memory);
    function getMethodology() external view returns (FlexibleLeverageStrategyExtension.MethodologySettings memory);
    function getIncentive() external view returns (FlexibleLeverageStrategyExtension.IncentiveSettings memory);
    function getExecution() external view returns (FlexibleLeverageStrategyExtension.ExecutionSettings memory);
    function getExchangeSettings(string memory _exchangeName) external view returns (FlexibleLeverageStrategyExtension.ExchangeSettings memory);
    function getEnabledExchanges() external view returns (string[] memory);

    function getCurrentLeverageRatio() external view returns (uint256);

    function getChunkRebalanceNotional(
        string[] calldata _exchangeNames
    ) 
        external
        view
        returns(uint256[] memory sizes, address sellAsset, address buyAsset);

    function shouldRebalance() external view returns(string[] memory, FlexibleLeverageStrategyExtension.ShouldRebalance[] memory);
    function shouldRebalanceWithBounds(
        uint256 _customMinLeverageRatio,
        uint256 _customMaxLeverageRatio
    )
        external
        view
        returns(string[] memory, FlexibleLeverageStrategyExtension.ShouldRebalance[] memory);
}