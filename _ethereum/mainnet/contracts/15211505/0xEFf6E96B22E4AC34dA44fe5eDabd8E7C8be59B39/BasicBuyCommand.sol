// SPDX-License-Identifier: AGPL-3.0-or-later

/// BasicBuyCommand.sol

// Copyright (C) 2021-2021 Oazo Apps Limited

// This program is free software: you can redistribute it and/or modify
// it under the terms of the GNU Affero General Public License as published by
// the Free Software Foundation, either version 3 of the License, or
// (at your option) any later version.
//
// This program is distributed in the hope that it will be useful,
// but WITHOUT ANY WARRANTY; without even the implied warranty of
// MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
// GNU Affero General Public License for more details.
//
// You should have received a copy of the GNU Affero General Public License
// along with this program.  If not, see <https://www.gnu.org/licenses/>.
pragma solidity ^0.8.0;

import "./SafeMath.sol";
import "./ManagerLike.sol";
import "./MPALike.sol";
import "./SpotterLike.sol";
import "./RatioUtils.sol";
import "./ServiceRegistry.sol";
import "./McdView.sol";
import "./BaseMPACommand.sol";

contract BasicBuyCommand is BaseMPACommand {
    using SafeMath for uint256;
    using RatioUtils for uint256;

    struct BasicBuyTriggerData {
        uint256 cdpId;
        uint16 triggerType;
        uint256 execCollRatio;
        uint256 targetCollRatio;
        uint256 maxBuyPrice;
        bool continuous;
        uint64 deviation;
        uint32 maxBaseFeeInGwei;
    }

    constructor(ServiceRegistry _serviceRegistry) BaseMPACommand(_serviceRegistry) {}

    function decode(bytes memory triggerData) public pure returns (BasicBuyTriggerData memory) {
        return abi.decode(triggerData, (BasicBuyTriggerData));
    }

    function isTriggerDataValid(uint256 _cdpId, bytes memory triggerData)
        external
        view
        returns (bool)
    {
        BasicBuyTriggerData memory trigger = decode(triggerData);

        ManagerLike manager = ManagerLike(serviceRegistry.getRegisteredService(CDP_MANAGER_KEY));
        bytes32 ilk = manager.ilks(trigger.cdpId);
        SpotterLike spot = SpotterLike(serviceRegistry.getRegisteredService(MCD_SPOT_KEY));
        (, uint256 liquidationRatio) = spot.ilks(ilk);

        (uint256 lowerTarget, uint256 upperTarget) = trigger.targetCollRatio.bounds(
            trigger.deviation
        );
        return
            _cdpId == trigger.cdpId &&
            trigger.triggerType == 3 &&
            trigger.execCollRatio > upperTarget &&
            lowerTarget.ray() > liquidationRatio &&
            deviationIsValid(trigger.deviation);
    }

    function isExecutionLegal(uint256 cdpId, bytes memory triggerData)
        external
        view
        returns (bool)
    {
        BasicBuyTriggerData memory trigger = decode(triggerData);

        (
            ,
            uint256 nextCollRatio,
            uint256 currPrice,
            uint256 nextPrice,
            bytes32 ilk
        ) = getVaultAndMarketInfo(cdpId);

        SpotterLike spot = SpotterLike(serviceRegistry.getRegisteredService(MCD_SPOT_KEY));
        (, uint256 liquidationRatio) = spot.ilks(ilk);

        return
            nextCollRatio >= trigger.execCollRatio.wad() &&
            nextPrice <= trigger.maxBuyPrice &&
            trigger.targetCollRatio.wad().mul(currPrice).div(nextPrice) >
            liquidationRatio.rayToWad() &&
            baseFeeIsValid(trigger.maxBaseFeeInGwei);
    }

    function execute(
        bytes calldata executionData,
        uint256 cdpId,
        bytes memory triggerData
    ) external {
        BasicBuyTriggerData memory trigger = decode(triggerData);

        validateTriggerType(trigger.triggerType, 3);
        validateSelector(MPALike.increaseMultiple.selector, executionData);

        executeMPAMethod(executionData);

        if (trigger.continuous) {
            recreateTrigger(cdpId, trigger.triggerType, triggerData);
        }
    }

    function isExecutionCorrect(uint256 cdpId, bytes memory triggerData)
        external
        view
        returns (bool)
    {
        BasicBuyTriggerData memory trigger = decode(triggerData);

        McdView mcdView = McdView(serviceRegistry.getRegisteredService(MCD_VIEW_KEY));
        uint256 nextCollRatio = mcdView.getRatio(cdpId, true);

        (uint256 lowerTarget, uint256 upperTarget) = trigger.targetCollRatio.bounds(
            trigger.deviation
        );

        return nextCollRatio <= upperTarget.wad() && nextCollRatio >= lowerTarget.wad();
    }
}
