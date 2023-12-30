// SPDX-License-Identifier: MIT
pragma solidity 0.6.12;
pragma experimental ABIEncoderV2;

import "./ECDSA.sol";
import "./IOptIn.sol";

struct OpHandle {
    uint8 opType;
    uint64 opId;
}

struct OpMetadata {
    uint8 opType; // the operation type
    uint64 createdAt; // the creation timestamp of an op
    address booster; // the booster at the time of when the op has been created
}

struct OpCounter {
    // The current value of the counter
    uint64 value;
    // Contains the opId that is to be finalized next - i.e. FIFO order
    uint64 nextFinalize;
    // Contains the opId that is to be reverted next - i.e. LIFO order
    uint64 nextRevert;
}

// Library containing public functions for pending ops - those will never be inlined
// to reduce the bytecode size of individual contracts.
library ProtectedBoostableLib {
    using ECDSA for bytes32;

    function deleteOpHandle(
        address user,
        OpHandle memory opHandle,
        OpHandle[] storage opHandles,
        OpCounter storage opCounter,
        mapping(bytes32 => OpMetadata) storage opMetadata
    ) public {
        uint256 length = opHandles.length;
        assert(length > 0);

        uint64 minOpId; // becomes next LIFO
        uint64 maxOpId; // becomes next FIFO

        // Pending ops are capped to MAX_PENDING_OPS. We always perform
        // MIN(length, MAX_PENDING_OPS) look-ups to do a "swap-and-pop" and
        // for updating the opCounter LIFO/FIFO pointers.
        for (uint256 i = 0; i < length; i++) {
            uint64 currOpId = opHandles[i].opId;
            if (currOpId == opHandle.opId) {
                // Overwrite item at i with last
                opHandles[i] = opHandles[length - 1];

                // Continue, to ignore this opId when updating
                // minOpId and maxOpId.
                continue;
            }

            // Update minOpId
            if (minOpId == 0 || currOpId < minOpId) {
                minOpId = currOpId;
            }

            // Update maxOpId
            if (currOpId > maxOpId) {
                maxOpId = currOpId;
            }
        }

        // Might be 0 when everything got finalized/reverted
        opCounter.nextFinalize = minOpId;
        // Might be 0 when everything got finalized/reverted
        opCounter.nextRevert = maxOpId;

        // Remove the last item
        opHandles.pop();

        // Remove metadata
        delete opMetadata[_getOpKey(user, opHandle.opId)];
    }

    function assertCanFinalize(
        OpMetadata memory metadata,
        IOptIn.OptInStatus memory optInStatus
    ) public view returns (uint64) {
        // Now there are three valid scenarios remaining:
        //
        // - msg.sender is the original booster
        // - op is expired
        // - getBoosterAddress returns a different booster than the original booster
        //
        // In the second and third case, anyone can call finalize.
        address originalBooster = metadata.booster;

        if (originalBooster == msg.sender) {
            return metadata.createdAt; // First case
        }

        address currentBooster = optInStatus.optedInTo;
        uint256 optOutPeriod = optInStatus.optOutPeriod;

        bool isExpired = block.timestamp >= metadata.createdAt + optOutPeriod;
        if (isExpired) {
            return metadata.createdAt; // Second case
        }

        if (currentBooster != originalBooster) {
            return metadata.createdAt; // Third case
        }

        revert("PB-4");
    }

    function verifySignatureForRevert(
        address user,
        uint64 opTimestamp,
        IOptIn.OptInStatus memory optInStatus,
        bytes memory boosterMessage,
        address[] memory hasherContracts,
        Signature memory signature
    ) public {
        require(hasherContracts.length > 0, "PB-12");

        // Result of hasher contract call
        uint64 signedAt;
        bytes32 boosterHash;
        bool signatureVerified;

        for (uint256 i = 0; i < hasherContracts.length; i++) {
            // Call into the hasher contract and take the first non-zero result.
            // The contract must implement the following function:
            //
            // decodeAndHashBoosterMessage(
            //     address targetBooster,
            //     bytes memory boosterMessage
            // )
            //
            // If it doesn't, then the call will fail (success=false) and we try the next one.
            // If it succeeds (success = true), then we try to decode the result.
            // solhint-disable-next-line avoid-low-level-calls
            (bool success, bytes memory result) = address(hasherContracts[i])
                .call(
                // keccak256("decodeAndHashBoosterMessage(address,bytes)")
                abi.encodeWithSelector(
                    0xaf6eec54,
                    msg.sender, /* msg.sender becomes the target booster */
                    boosterMessage
                )
            );

            if (!success) {
                continue;
            }

            // The result is exactly 2 words long = 512 bits = 64 bytes
            // 32 bytes for the expected message hash
            // 8 bytes (padded to 32 bytes) for the expected timestamp
            if (result.length != 64) {
                continue;
            }

            // NOTE: A contract with malintent could return any hash that we would
            // try to recover against. But there is no harm done in doing so since
            // the user must have signed it.
            //
            // However, it might return an unrelated timestamp, that the user hasn't
            // signed - so it could prolong the expiry of a signature which is a valid
            // concern whose risk we minimize by using also the op timestamp which guarantees
            // that a signature eventually expires.

            // Decode and recover signer
            (boosterHash, signedAt) = abi.decode(result, (bytes32, uint64));
            address signer = ecrecover(
                boosterHash,
                signature.v,
                signature.r,
                signature.s
            );

            if (user != signer) {
                // NOTE: Currently, hardware wallets (e.g. Ledger, Trezor) do not support EIP712 signing (specifically `signTypedData_v4`).
                // However, a user can still sign the EIP712 hash with the caveat that it's signed using `personal_sign` which prepends
                // the prefix '"\x19Ethereum Signed Message:\n" + len(message)'.
                //
                // To still support that, we also add the prefix and try to use the recovered address instead:
                signer = ecrecover(
                    boosterHash.toEthSignedMessageHash(),
                    signature.v,
                    signature.r,
                    signature.s
                );
            }

            // If we recovered `user` from the signature, then we have a valid signature.
            if (user == signer) {
                signatureVerified = true;
                break;
            }

            // Keep trying
        }

        // Revert if signature couldn't be verified with any of the returned hashes
        require(signatureVerified, "PB-8");

        // Lastly, the current time must not be older than:
        // MIN(opTimestamp, signedAt) + optOutPeriod * 3
        uint64 _now = uint64(block.timestamp);
        // The maximum age is equal to whichever is lowest:
        //      opTimestamp + optOutPeriod * 3
        //      signedAt + optOutPeriod * 3
        uint64 maximumAge;
        if (opTimestamp > signedAt) {
            maximumAge = signedAt + uint64(optInStatus.optOutPeriod * 3);
        } else {
            maximumAge = opTimestamp + uint64(optInStatus.optOutPeriod * 3);
        }

        require(_now <= maximumAge, "PB-11");
    }

    function _getOpKey(address user, uint64 opId)
        internal
        pure
        returns (bytes32)
    {
        return keccak256(abi.encodePacked(user, opId));
    }
}
