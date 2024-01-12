// SPDX-License-Identifier: AGPL-3.0-or-later

/// AutomationBotAggregator.sol

// Copyright (C) 2022 Oazo Apps Limited

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

import "./AutomationBot.sol";
import "./ManagerLike.sol";
import "./IValidator.sol";
import "./ServiceRegistry.sol";

contract AutomationBotAggregator {
    string private constant CDP_MANAGER_KEY = "CDP_MANAGER";
    string private constant AUTOMATION_BOT_KEY = "AUTOMATION_BOT";
    string private constant AUTOMATION_BOT_AGGREGATOR_KEY = "AUTOMATION_BOT_AGGREGATOR";

    ServiceRegistry public immutable serviceRegistry;
    address public immutable self;

    uint256 public counter;

    constructor(ServiceRegistry _serviceRegistry) {
        serviceRegistry = _serviceRegistry;
        self = address(this);
    }

    modifier onlyDelegate() {
        require(address(this) != self, "aggregator/only-delegate");
        _;
    }

    modifier onlyCdpAllowed(uint256 cdpId) {
        ManagerLike manager = ManagerLike(serviceRegistry.getRegisteredService(CDP_MANAGER_KEY));
        address cdpOwner = manager.owns(cdpId);
        require(isCdpAllowed(cdpId, msg.sender, manager), "bot/no-permissions");
        _;
    }

    // works correctly in any context
    function isCdpAllowed(
        uint256 cdpId,
        address operator,
        ManagerLike manager
    ) public view returns (bool) {
        address cdpOwner = manager.owns(cdpId);
        return (manager.cdpCan(cdpOwner, cdpId, operator) == 1) || (operator == cdpOwner);
    }

    function getValidatorAddress(uint16 groupType) public view returns (IValidator) {
        bytes32 validatorHash = keccak256(abi.encode("Validator", groupType));
        return IValidator(serviceRegistry.getServiceAddress(validatorHash));
    }

    function addTriggerGroup(
        uint16 groupType,
        uint256[] memory replacedTriggerId,
        bytes[] memory triggersData
    ) external onlyDelegate {
        ManagerLike manager = ManagerLike(serviceRegistry.getRegisteredService(CDP_MANAGER_KEY));

        (uint256[] memory cdpIds, ) = getValidatorAddress(groupType).decode(triggersData);
        uint256 cdpId = cdpIds[0];
        address aggregator = serviceRegistry.getRegisteredService(AUTOMATION_BOT_AGGREGATOR_KEY);
        if (!isCdpAllowed(cdpId, aggregator, manager)) {
            manager.cdpAllow(cdpId, aggregator, 1);
        }

        address bot = serviceRegistry.getRegisteredService(AUTOMATION_BOT_KEY);
        if (!isCdpAllowed(cdpId, bot, manager)) {
            manager.cdpAllow(cdpId, bot, 1);
        }

        AutomationBotAggregator(aggregator).addRecords(groupType, replacedTriggerId, triggersData);
        manager.cdpAllow(cdpId, aggregator, 0);
    }

    function removeTriggers(uint256[] memory triggerIds, bool removeAllowance)
        external
        onlyDelegate
    {
        AutomationBot bot = AutomationBot(serviceRegistry.getRegisteredService(AUTOMATION_BOT_KEY));

        for (uint256 i = 0; i < triggerIds.length; i++) {
            (, uint256 cdpId) = bot.activeTriggers(triggerIds[i]);
            (bool status, ) = address(bot).delegatecall(
                abi.encodeWithSelector(
                    bot.removeTrigger.selector,
                    cdpId,
                    triggerIds[i],
                    removeAllowance && i == triggerIds.length - 1
                )
            );
            require(status, "aggregator/remove-trigger-failed");
        }
    }

    function addRecords(
        uint16 groupType,
        uint256[] memory replacedTriggerId,
        bytes[] memory triggersData
    ) external {
        IValidator validator = getValidatorAddress(groupType);
        require(validator.validate(replacedTriggerId, triggersData), "aggregator/validation-error");
        (uint256[] memory cdpIds, uint256[] memory triggerTypes) = validator.decode(triggersData);

        AutomationBot bot = AutomationBot(serviceRegistry.getRegisteredService(AUTOMATION_BOT_KEY));
        uint256 firstTriggerId = bot.triggersCounter() + 1;
        uint256[] memory triggerIds = new uint256[](triggersData.length);
        uint256 cdpId = cdpIds[0];
        for (uint256 i = 0; i < triggerTypes.length; i++) {
            bot.addRecord(cdpId, triggerTypes[i], replacedTriggerId[i], triggersData[i]);
            triggerIds[i] = firstTriggerId + i;
        }

        emit TriggerGroupAdded(++counter, groupType, cdpId, triggerIds);
    }

    event TriggerGroupAdded(
        uint256 indexed groupId,
        uint16 indexed groupType,
        uint256 indexed cdpId,
        uint256[] triggerIds
    );
}
