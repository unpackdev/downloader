// SPDX-License-Identifier: MIT
pragma solidity 0.8.6;

import "./CheckReceiptsProof.sol";
import "./Initializable.sol";
import "./SignatureCheck.sol";


contract CheckAura is Initializable {
    bytes1 constant PARENT_HASH_PREFIX = 0xA0;
    bytes1 constant STEP_PREFIX = 0x84;
    bytes2 constant SIGNATURE_PREFIX = 0xB841;

    address[] public validatorSet;
    address validatorSetAddress;
    bytes32 public lastProcessedBlock; // actually latest processed block in which *vs change event* emitted
    uint public minSafetyBlocksValidators;


    struct BlockAura {
        bytes3 p0Seal;
        bytes3 p0Bare;

        bytes32 parentHash;
        bytes p2;
        bytes32 receiptHash;
        bytes p3;

        bytes4 step;
        bytes signature;  // todo maybe pass s r v values?

        uint64 finalizedVs;
    }


    struct ValidatorSetChange {
        address deltaAddress;
        uint16 deltaIndex; // add if 0, else remove
    }

    struct ValidatorSetProof {
        bytes[] receiptProof;
        ValidatorSetChange[] changes;
        uint64 eventBlock;
    }

    struct AuraProof {
        BlockAura[] blocks;
        CommonStructs.TransferProof transfer;
        ValidatorSetProof[] vsChanges;
        uint64 transferEventBlock;
    }


    function __CheckAura_init(
        address[] calldata initialValidators_,
        address validatorSetAddress_,
        bytes32 lastProcessedBlock_,
        uint minSafetyBlocksValidators_
    ) internal initializer {
        require(initialValidators_.length > 0, "Length of _initialValidators must be bigger than 0");

        validatorSet = initialValidators_;
        validatorSetAddress = validatorSetAddress_;
        lastProcessedBlock = lastProcessedBlock_;
        minSafetyBlocksValidators = minSafetyBlocksValidators_;
    }



    /*
     AuraProof.blocks contains:
      - blocks for validate validatorSet change event, in that order:
        - block with `InitiateChange` events (contains list of all validators)
        - some blocks, that need for validation (the amount depends on the length of the current validator set)
        - block, when validators finalize; have `finalizedVs` != 0
        * repeated for each vs change event; all events must go in order, without omissions *

      - block with transfer event;
      - safety blocks for transfer event

      AuraProof.vsChanges contains changes in validator set and receiptProof for validation.
      block.finalizedVs-1 is index in AuraProof.vsChanges array

      Function will check all blocks, processing vs change events if needed.
      Each block parentHash must be equal to the seal hash of the previous block, except for gaps between vsChange events
      If there are no errors, the transfer is considered valid
    */
    function checkAura_(AuraProof calldata auraProof, uint minSafetyBlocks, address sideBridgeAddress) internal {

        bytes32 parentHash;
        bytes32 receiptHash;

        // auraProof can be without transfer event when we have to many vsChanges and transfer doesn't fit into proof
        if (auraProof.transfer.eventId != 0) {
            receiptHash = calcTransferReceiptsHash(auraProof.transfer, sideBridgeAddress);
            require(auraProof.blocks[auraProof.transferEventBlock].receiptHash == receiptHash, "Transfer event validation failed");
            require(auraProof.blocks.length - auraProof.transferEventBlock >= minSafetyBlocks, "Not enough safety blocks");
        }

        for (uint i = 0; i < auraProof.blocks.length; i++) {
            BlockAura calldata block_ = auraProof.blocks[i];

            // check that parentHash is correct
            if (block_.parentHash != parentHash) {
                // we can ignore wrong parentHash if:
                // - it's NOT safety blocks for transfer event
                // - it's first block (don't know parentHash)
                // - it's finalizing block (there is gap BEFORE finalizing block)
                // - it's next block after finalizing (there is gap AFTER finalizing block)
                // else, raise error

                if (i > auraProof.transferEventBlock || // safety blocks for transfer event
                    (i != 0 && // not first block
                    block_.finalizedVs == 0 && // not finalizing block
                    auraProof.blocks[i-1].finalizedVs == 0) // not next block after finalizing
                )
                    revert("Wrong parent hash");
            }

            // check validator for this block
            // calc block hash for this block
            parentHash = checkBlock(block_);

            // if this block is finalizing block
            // 0 means no events should be finalized, so indexes are shifted by 1
            if (block_.finalizedVs != 0) {
                // vs changes in that block
                ValidatorSetProof calldata vsProof = auraProof.vsChanges[block_.finalizedVs - 1];

                // apply vs changes
                for (uint k = 0; k < vsProof.changes.length; k++)
                    applyVsChange(vsProof.changes[k]);

                // check proof
                receiptHash = calcValidatorSetReceiptHash(vsProof.receiptProof, validatorSetAddress, validatorSet);
                require(auraProof.blocks[vsProof.eventBlock].receiptHash == receiptHash, "Wrong VS receipt hash");
                require(i - vsProof.eventBlock >= minSafetyBlocksValidators, "Few safety blocks validators");
            }

        }

        // save block.parentHash in which latest processed vsChange event emitted
        if (auraProof.vsChanges.length > 0) {
            lastProcessedBlock = auraProof.blocks[auraProof.vsChanges[auraProof.vsChanges.length - 1].eventBlock].parentHash;
        }
    }

    function getValidatorSet() public view returns (address[] memory) {
        return validatorSet;
    }

    function applyVsChange(ValidatorSetChange calldata vsEvent) internal {
        if (vsEvent.deltaIndex == 0) {// add validator
            validatorSet.push(vsEvent.deltaAddress);
        } else {// delete validator
            uint index = uint(vsEvent.deltaIndex - 1);
            validatorSet[index] = validatorSet[validatorSet.length - 1];
            validatorSet.pop();
        }
    }

    function checkBlock(BlockAura calldata block_) internal view returns (bytes32) {
        (bytes32 bareHash, bytes32 sealHash) = calcBlockHash(block_);

        address validator = validatorSet[bytesToUint(block_.step) % validatorSet.length];
        require(ecdsaRecover(bareHash, block_.signature) == validator, "Failed to verify sign");

        return sealHash;
    }

    function calcBlockHash(BlockAura calldata block_) internal pure returns (bytes32, bytes32) {
        bytes memory commonRlp = abi.encodePacked(PARENT_HASH_PREFIX, block_.parentHash, block_.p2, block_.receiptHash, block_.p3);
        return (
        // hash without seal (bare), for signature check
        keccak256(abi.encodePacked(block_.p0Bare, commonRlp)),
        // hash with seal, for prevHash check
        keccak256(abi.encodePacked(block_.p0Seal, commonRlp, STEP_PREFIX, block_.step, SIGNATURE_PREFIX, block_.signature))
        );
    }


    function calcValidatorSetReceiptHash(bytes[] calldata receiptProof, address validatorSetAddress_, address[] storage vSet) private pure returns (bytes32) {
        bytes32 el = keccak256(abi.encodePacked(
                receiptProof[0],
                validatorSetAddress_,
                receiptProof[1],
                abi.encode(vSet),
                receiptProof[2]
            ));
        return calcReceiptsHash(receiptProof, el, 3);
    }

    function bytesToUint(bytes4 b) internal pure returns (uint){
        return uint(uint32(b));
    }

    uint256[15] private ___gap;
}
