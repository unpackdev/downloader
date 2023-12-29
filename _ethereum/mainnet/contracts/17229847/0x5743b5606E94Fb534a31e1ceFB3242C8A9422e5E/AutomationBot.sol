// SPDX-License-Identifier: AGPL-3.0-or-later

/// AutomationBot.sol

// Copyright (C) 2023 Oazo Apps Limited

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

import "./IValidator.sol";
import "./IAutomationBot.sol";
import "./IAdapter.sol";
import "./ICommand.sol";
import "./IServiceRegistry.sol";

import "./ReentrancyGuard.sol";

contract AutomationBot is IAutomationBot, ReentrancyGuard {
    struct TriggerRecord {
        bytes32 triggerHash;
        address commandAddress;
        bool continuous;
    }

    struct Counters {
        uint64 triggersCounter;
        uint64 triggersGroupCounter;
        uint128 lockCount;
    }

    uint64 private constant COUNTER_OFFSET = 10 ** 10;
    uint16 private constant SINGLE_TRIGGER_GROUP_TYPE = 2 ** 16 - 1;
    string private constant AUTOMATION_EXECUTOR_KEY = "AUTOMATION_EXECUTOR_V2";

    IServiceRegistry public immutable serviceRegistry;
    AutomationBot public immutable automationBot;

    Counters private counter;
    mapping(uint256 => AutomationBot.TriggerRecord) public activeTriggers;

    constructor(IServiceRegistry _serviceRegistry) {
        serviceRegistry = _serviceRegistry;
        require(address(_serviceRegistry) != address(0), "automation-bot/invalid-initialisation");
        automationBot = AutomationBot(address(this));
        counter.lockCount = 0;
        counter.triggersCounter = COUNTER_OFFSET;
        counter.triggersGroupCounter = COUNTER_OFFSET + 1;
    }

    modifier auth(address caller) {
        require(
            serviceRegistry.getRegisteredService(AUTOMATION_EXECUTOR_KEY) == caller,
            "bot/not-executor"
        );
        _;
    }

    modifier onlyDelegate() {
        require(address(this) != address(automationBot), "bot/only-delegate");
        _;
    }

    // works correctly in any context
    function getCommandAddress(uint256 triggerType) public view returns (address) {
        bytes32 commandHash = keccak256(abi.encode("Command", triggerType));

        address commandAddress = serviceRegistry.getServiceAddress(commandHash);

        return commandAddress;
    }

    function getAdapterAddress(
        address commandAddress,
        bool isExecute
    ) public view returns (address) {
        require(commandAddress != address(0), "bot/unknown-trigger-type");
        bytes32 adapterHash = isExecute
            ? keccak256(abi.encode("AdapterExecute", commandAddress))
            : keccak256(abi.encode("Adapter", commandAddress));
        address service = serviceRegistry.getServiceAddress(adapterHash);
        return service;
    }

    function clearLock() external {
        counter.lockCount = 0;
    }

    // works correctly in any context
    function getTriggersHash(
        bytes memory triggerData,
        address commandAddress
    ) private view returns (bytes32) {
        bytes32 triggersHash = keccak256(
            abi.encodePacked(triggerData, serviceRegistry, commandAddress)
        );

        return triggersHash;
    }

    // works correctly in context of Automation Bot
    function checkTriggersExistenceAndCorrectness(
        uint256 triggerId,
        address commandAddress,
        bytes memory triggerData
    ) private view {
        bytes32 triggerHash = activeTriggers[triggerId].triggerHash;
        require(
            triggerHash != bytes32(0) &&
                triggerHash == getTriggersHash(triggerData, commandAddress),
            "bot/invalid-trigger"
        );
    }

    // works correctly in context of automationBot
    function addRecord(
        // This function should be executed allways in a context of AutomationBot address not DsProxy,
        // msg.sender should be dsProxy
        uint256 triggerType,
        bool continuous,
        uint256 replacedTriggerId,
        bytes memory triggerData,
        bytes memory replacedTriggerData
    ) external {
        lock();

        address commandAddress = getCommandAddress(triggerType);
        if (replacedTriggerId != 0) {
            TriggerRecord memory replaced = activeTriggers[replacedTriggerId];
            bytes32 replacedTriggersHash = replaced.triggerHash;
            address originalCommandAddress = replaced.commandAddress;
            ISecurityAdapter originalAdapter = ISecurityAdapter(
                getAdapterAddress(originalCommandAddress, false)
            );
            require(
                originalAdapter.canCall(replacedTriggerData, msg.sender),
                "bot/no-permissions-replace"
            );
            require(
                replacedTriggersHash ==
                    getTriggersHash(replacedTriggerData, originalCommandAddress),
                "bot/invalid-trigger"
            );
        }

        require(
            ICommand(commandAddress).isTriggerDataValid(continuous, triggerData),
            "bot/invalid-trigger-data"
        );

        ISecurityAdapter adapter = ISecurityAdapter(getAdapterAddress(commandAddress, false));
        require(adapter.canCall(triggerData, msg.sender), "bot/no-permissions");

        appendTriggerRecord(
            TriggerRecord(getTriggersHash(triggerData, commandAddress), commandAddress, continuous)
        );

        if (replacedTriggerId != 0) {
            clearTrigger(replacedTriggerId);
            emit TriggerRemoved(replacedTriggerId);
        }

        emit TriggerAdded(
            automationBot.triggersCounter(),
            commandAddress,
            continuous,
            triggerType,
            triggerData
        );
    }

    // works correctly in context of automationBot
    function removeRecord(
        // This function should be executed allways in a context of AutomationBot address not DsProxy,
        // msg.sender should be dsProxy
        bytes memory triggerData,
        uint256 triggerId
    ) external {
        address commandAddress = activeTriggers[triggerId].commandAddress;
        ISecurityAdapter adapter = ISecurityAdapter(getAdapterAddress(commandAddress, false));
        require(adapter.canCall(triggerData, msg.sender), "no-permit");
        checkTriggersExistenceAndCorrectness(triggerId, commandAddress, triggerData);

        clearTrigger(triggerId);
        emit TriggerRemoved(triggerId);
    }

    function clearTrigger(uint256 triggerId) private {
        updateTriggerRecord(
            triggerId,
            TriggerRecord(0, 0x0000000000000000000000000000000000000000, false)
        );
    }

    // works correctly in context of dsProxy
    function addTriggers(
        uint16 groupType,
        bool[] memory continuous,
        uint256[] memory replacedTriggerId,
        bytes[] memory triggerData,
        bytes[] memory replacedTriggerData,
        uint256[] memory triggerTypes
    ) external onlyDelegate {
        require(
            replacedTriggerId.length == replacedTriggerData.length &&
                triggerData.length == triggerTypes.length &&
                triggerTypes.length == continuous.length &&
                continuous.length == triggerData.length,
            "bot/invalid-input-length"
        );

        automationBot.clearLock();

        if (groupType != SINGLE_TRIGGER_GROUP_TYPE) {
            IValidator validator = getValidatorAddress(groupType);
            require(
                validator.validate(continuous, replacedTriggerId, triggerData),
                "aggregator/validation-error"
            );
        }

        uint256 firstTriggerId = automationBot.triggersCounter() + 1;
        uint256[] memory triggerIds = new uint256[](triggerData.length);

        for (uint256 i = 0; i < triggerData.length; i++) {
            if (i == 0) {
                ISecurityAdapter adapter = ISecurityAdapter(
                    getAdapterAddress(getCommandAddress(triggerTypes[i]), false)
                );
                if (!adapter.canCall(triggerData[i], address(adapter))) {
                    (bool status, ) = address(adapter).delegatecall(
                        abi.encodeWithSelector(
                            adapter.permit.selector,
                            triggerData[i],
                            address(adapter),
                            true
                        )
                    );
                    require(status, "bot/permit-failed-add");
                }

                emit ApprovalGranted(triggerData[i], address(adapter));
            }

            automationBot.addRecord(
                triggerTypes[i],
                continuous[i],
                replacedTriggerId[i],
                triggerData[i],
                replacedTriggerData[i]
            );

            triggerIds[i] = firstTriggerId + i;
        }

        automationBot.emitGroupDetails(groupType, triggerIds);
    }

    function unlock() private {
        //To keep addRecord && emitGroupDetails atomic
        require(counter.lockCount > 0, "bot/not-locked");
        counter.lockCount = 0;
    }

    function lock() private {
        //To keep addRecord && emitGroupDetails atomic
        counter.lockCount++;
    }

    function emitGroupDetails(uint16 triggerGroupType, uint256[] memory triggerIds) external {
        require(counter.lockCount == triggerIds.length, "bot/group-inconsistent");
        unlock();

        emit TriggerGroupAdded(automationBot.triggersGroupCounter(), triggerGroupType, triggerIds);
        increaseGroupCounter();
    }

    function getValidatorAddress(uint16 groupType) public view returns (IValidator) {
        bytes32 validatorHash = keccak256(abi.encode("Validator", groupType));
        return IValidator(serviceRegistry.getServiceAddress(validatorHash));
    }

    //works correctly in context of dsProxy
    function removeTriggers(
        uint256[] memory triggerIds,
        bytes[] memory triggerData,
        bool removeAllowance
    ) external onlyDelegate {
        require(triggerData.length > 0, "bot/remove-at-least-one");
        require(triggerData.length == triggerIds.length, "bot/invalid-input-length");

        automationBot.clearLock();
        address commandAddress = automationBot.getTriggerRecord(triggerIds[0]).commandAddress;

        for (uint256 i = 0; i < triggerIds.length; i++) {
            removeTrigger(triggerIds[i], triggerData[i]);
        }

        if (removeAllowance) {
            ISecurityAdapter adapter = ISecurityAdapter(getAdapterAddress(commandAddress, false));

            (bool status, ) = address(adapter).delegatecall(
                abi.encodeWithSelector(
                    adapter.permit.selector,
                    triggerData[0],
                    address(adapter),
                    false
                )
            );
            require(status, "bot/permit-removal-failed");

            emit ApprovalRemoved(triggerData[0], address(adapter));
        }
    }

    function removeTrigger(uint256 triggerId, bytes memory triggerData) private {
        automationBot.removeRecord(triggerData, triggerId);
    }

    //works correctly in context of automationBot
    function execute(
        bytes calldata executionData,
        bytes calldata triggerData,
        address commandAddress,
        uint256 triggerId,
        uint256 coverageAmount,
        address coverageToken
    ) external auth(msg.sender) nonReentrant {
        checkTriggersExistenceAndCorrectness(triggerId, commandAddress, triggerData);
        ICommand command = ICommand(commandAddress);

        require(command.isExecutionLegal(triggerData), "bot/trigger-execution-illegal");
        ISecurityAdapter adapter = ISecurityAdapter(getAdapterAddress(commandAddress, false));
        IExecutableAdapter executableAdapter = IExecutableAdapter(
            getAdapterAddress(commandAddress, true)
        );
        getCoverage(triggerData, adapter, executableAdapter, coverageAmount, coverageToken);

        require(command.isExecutionLegal(triggerData), "bot/trigger-execution-illegal");
        {
            adapter.permit(triggerData, commandAddress, true);
        }
        {
            command.execute(executionData, triggerData); //command must be whitelisted
            bool continuous = activeTriggers[triggerId].continuous;
            if (!continuous) {
                clearTrigger(triggerId);
                emit TriggerRemoved(triggerId);
            }
        }
        {
            adapter.permit(triggerData, commandAddress, false);
            require(command.isExecutionCorrect(triggerData), "bot/trigger-execution-wrong");
        }

        emit TriggerExecuted(triggerId, executionData);
    }

    function getCoverage(
        bytes memory triggerData,
        ISecurityAdapter securityAdapter,
        IExecutableAdapter executableAdapter,
        uint256 coverageAmount,
        address coverageToken
    ) private {
        securityAdapter.permit(triggerData, address(executableAdapter), true);
        executableAdapter.getCoverage(triggerData, msg.sender, coverageToken, coverageAmount);
        securityAdapter.permit(triggerData, address(executableAdapter), false);
    }

    function increaseGroupCounter() private {
        counter.triggersGroupCounter++;
    }

    function triggersCounter() external view returns (uint256) {
        return uint256(counter.triggersCounter);
    }

    function triggersGroupCounter() external view returns (uint256) {
        return uint256(counter.triggersGroupCounter);
    }

    function getTriggerRecord(
        uint256 id
    ) external view returns (AutomationBot.TriggerRecord memory rec) {
        rec = activeTriggers[id];
    }

    function updateTriggerRecord(uint256 id, TriggerRecord memory record) private {
        activeTriggers[id] = record;
    }

    function appendTriggerRecord(TriggerRecord memory record) private {
        counter.triggersCounter++;
        activeTriggers[counter.triggersCounter] = record;
    }

    event ApprovalRemoved(bytes indexed triggerData, address approvedEntity);

    event ApprovalGranted(bytes indexed triggerData, address approvedEntity);

    event TriggerRemoved(uint256 indexed triggerId);

    event TriggerAdded(
        uint256 indexed triggerId,
        address indexed commandAddress,
        bool continuous,
        uint256 triggerType,
        bytes triggerData
    );

    event TriggerExecuted(uint256 indexed triggerId, bytes executionData);
    event TriggerGroupAdded(
        uint256 indexed groupId,
        uint16 indexed groupType,
        uint256[] triggerIds
    );
}
