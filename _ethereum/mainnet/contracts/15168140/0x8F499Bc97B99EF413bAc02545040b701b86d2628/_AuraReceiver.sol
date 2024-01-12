// SPDX-License-Identifier: MIT
pragma solidity 0.8.6;

import "./CommonBridge.sol";
import "./CheckAura.sol";


contract _AuraReceiver is CommonBridge, CheckAura {

    function initialize(
        CommonStructs.ConstructorArgs calldata args,
        address[] calldata initialValidators,
        address validatorSetAddress,
        bytes32 lastProcessedBlock,
        uint minSafetyBlocksValidators
    ) public initializer {
        __CommonBridge_init(args);
        __CheckAura_init(initialValidators, validatorSetAddress, lastProcessedBlock, minSafetyBlocksValidators);
    }


    function changeMinSafetyBlocksValidators(uint minSafetyBlocksValidators_) public onlyRole(ADMIN_ROLE) {
        minSafetyBlocksValidators = minSafetyBlocksValidators_;
    }

    function submitTransferAura(AuraProof calldata auraProof) public onlyRole(RELAY_ROLE) whenNotPaused {
        emit TransferSubmit(auraProof.transfer.eventId);
        checkEventId(auraProof.transfer.eventId);
        checkAura_(auraProof, minSafetyBlocks, sideBridgeAddress);
        lockTransfers(auraProof.transfer.transfers, auraProof.transfer.eventId);
    }

    function submitValidatorSetChangesAura(AuraProof calldata auraProof) public onlyRole(RELAY_ROLE) whenNotPaused {
        checkAura_(auraProof, minSafetyBlocks, sideBridgeAddress);
    }

}
