// SPDX-License-Identifier: MIT
pragma solidity 0.6.12;
pragma experimental ABIEncoderV2;

import "./EIP712Boostable.sol";
import "./IOptIn.sol";
import "./ProtectedBoostableLib.sol";

abstract contract ProtectedBoostable is EIP712Boostable {
    //---------------------------------------------------------------
    // State for non-boosted operations while opted-in and the OPT_IN permaboost is active
    //---------------------------------------------------------------

    uint256 private constant MAX_PENDING_OPS = 25;

    // A mapping of account to an opCounter.
    mapping(address => OpCounter) internal _opCounters;

    // A mapping of account to an array containing all it's pending ops.
    mapping(address => OpHandle[]) internal _pendingOpsByAddress;

    // A mapping of keccak256(address,opId) to a struct holding metadata like the associated user account and creation timestamp.
    mapping(bytes32 => OpMetadata) internal _opMetadata;

    // Event that is emitted whenever a pending op is created
    // NOTE: returning an OpHandle in the event flattens it into an array for some reason
    // i.e. emit PendingOp(0x123.., OpHandle(1, 0)) => { from: 0x123, opHandle: ['1', '0']}
    event PendingOp(address from, uint64 opId, uint8 opType);
    // Event that is emitted whenever a pending op is finalized
    event FinalizedOp(address from, uint64 opId, uint8 opType);
    // Event that is emitted whenever a pending op is reverted
    event RevertedOp(address from, uint64 opId, uint8 opType);

    constructor(address optIn, bytes32 domainSeparator)
        public
        EIP712Boostable(optIn, domainSeparator)
    {}

    //---------------------------------------------------------------
    // Pending ops
    //---------------------------------------------------------------

    /**
     * @dev Returns the metadata of an op. Returns a zero struct if it doesn't exist.
     */
    function getOpMetadata(address user, uint64 opId)
        public
        virtual
        view
        returns (OpMetadata memory)
    {
        return _opMetadata[_getOpKey(user, opId)];
    }

    /**
     * @dev Returns the metadata of an op. Returns a zero struct if it doesn't exist.
     */
    function getOpCounter(address user)
        public
        virtual
        view
        returns (OpCounter memory)
    {
        return _opCounters[user];
    }

    /**
     * @dev Returns the metadata of an op. Reverts if it doesn't exist or
     * the opType mismatches.
     */
    function safeGetOpMetadata(address user, OpHandle memory opHandle)
        public
        virtual
        view
        returns (OpMetadata memory)
    {
        OpMetadata storage metadata = _opMetadata[_getOpKey(
            user,
            opHandle.opId
        )];

        // If 'createdAt' is zero, then it's non-existent for us
        require(metadata.createdAt > 0, "PB-1");
        require(metadata.opType == opHandle.opType, "PB-2");

        return metadata;
    }

    /**
     * @dev Get the next op id for `user`
     */
    function _getNextOpId(address user) internal returns (uint64) {
        OpCounter storage counter = _opCounters[user];
        // NOTE: we always increase by 1, so it cannot overflow as long as this
        // is the only place increasing the counter.
        uint64 nextOpId = counter.value + 1;

        // This also updates the nextFinalize/Revert values
        if (counter.nextFinalize == 0) {
            // Only gets updated if currently pointing to "nothing", because FIFO
            counter.nextFinalize = nextOpId;
        }

        // nextRevert is always updated to the new opId, because LIFO
        counter.nextRevert = nextOpId;
        counter.value = nextOpId;

        // NOTE: It is safe to downcast to uint64 since it's practically impossible to overflow.
        return nextOpId;
    }

    /**
     * @dev Creates a new opHandle with the given type for `user`.
     */
    function _createNewOpHandle(
        IOptIn.OptInStatus memory optInStatus,
        address user,
        uint8 opType
    ) internal virtual returns (OpHandle memory) {
        uint64 nextOpId = _getNextOpId(user);
        OpHandle memory opHandle = OpHandle({opId: nextOpId, opType: opType});

        // NOTE: we have a hard limit of 25 pending OPs and revert if that
        // limit is exceeded.
        require(_pendingOpsByAddress[user].length < MAX_PENDING_OPS, "PB-3");

        address booster = optInStatus.optedInTo;

        _pendingOpsByAddress[user].push(opHandle);
        _opMetadata[_getOpKey(user, nextOpId)] = OpMetadata({
            createdAt: uint64(block.timestamp),
            booster: booster,
            opType: opType
        });

        return opHandle;
    }

    /**
     * @dev Delete the given `opHandle` from `user`.
     */
    function _deleteOpHandle(address user, OpHandle memory opHandle)
        internal
        virtual
    {
        OpHandle[] storage _opHandles = _pendingOpsByAddress[user];
        OpCounter storage opCounter = _opCounters[user];

        ProtectedBoostableLib.deleteOpHandle(
            user,
            opHandle,
            _opHandles,
            opCounter,
            _opMetadata
        );
    }

    /**
     * @dev Assert that the caller is allowed to finalize a pending op.
     *
     * Returns the user and createdAt timestamp of the op on success in order to
     * save some gas by minimizing redundant look-ups.
     */
    function _assertCanFinalize(address user, OpHandle memory opHandle)
        internal
        returns (uint64)
    {
        OpMetadata memory metadata = safeGetOpMetadata(user, opHandle);

        uint64 createdAt = metadata.createdAt;

        // First check if the user is still opted-in. If not, then anyone
        // can finalize since it is no longer associated with the original booster.
        IOptIn.OptInStatus memory optInStatus = getOptInStatus(user);
        if (!optInStatus.isOptedIn) {
            return createdAt;
        }

        // Revert if not FIFO order
        _assertFinalizeFIFO(user, opHandle.opId);

        return ProtectedBoostableLib.assertCanFinalize(metadata, optInStatus);
    }

    /**
     * @dev Asserts that the caller (msg.sender) is allowed to revert a pending operation.
     * The caller must be opted-in by user and provide a valid signature from the user
     * that hasn't expired yet.
     */
    function _assertCanRevert(
        address user,
        OpHandle memory opHandle,
        uint64 opTimestamp,
        bytes memory boosterMessage,
        Signature memory signature
    ) internal {
        // Revert if not LIFO order
        _assertRevertLIFO(user, opHandle.opId);

        IOptIn.OptInStatus memory optInStatus = getOptInStatus(user);

        require(
            optInStatus.isOptedIn && msg.sender == optInStatus.optedInTo,
            "PB-6"
        );

        // In order to verify the boosterMessage, we need the hash and timestamp of when it
        // was signed. To interpret the boosterMessage, consult all available hasher contracts and
        // take the first non-zero result.
        address[] memory hasherContracts = _getHasherContracts();

        // Call external library function, which performs the actual assertion. The reason
        // why it is not inlined, is that the need to reduce bytecode size.
        ProtectedBoostableLib.verifySignatureForRevert(
            user,
            opTimestamp,
            optInStatus,
            boosterMessage,
            hasherContracts,
            signature
        );
    }

    function _getHasherContracts() internal virtual returns (address[] memory);

    /**
     * @dev Asserts that the given opId is the next to be finalized for `user`.
     */
    function _assertFinalizeFIFO(address user, uint64 opId) internal virtual {
        OpCounter storage counter = _opCounters[user];
        require(counter.nextFinalize == opId, "PB-9");
    }

    /**
     * @dev Asserts that the given opId is the next to be reverted for `user`.
     */
    function _assertRevertLIFO(address user, uint64 opId) internal virtual {
        OpCounter storage counter = _opCounters[user];
        require(counter.nextRevert == opId, "PB-10");
    }

    /**
     * @dev Prepare an op revert.
     * - Asserts that the caller is allowed to revert the given op
     * - Deletes the op handle to minimize risks of reentrancy
     */
    function _prepareOpRevert(
        address user,
        OpHandle memory opHandle,
        bytes memory boosterMessage,
        Signature memory signature
    ) internal {
        OpMetadata memory metadata = safeGetOpMetadata(user, opHandle);

        _assertCanRevert(
            user,
            opHandle,
            metadata.createdAt,
            boosterMessage,
            signature
        );

        // Delete opHandle, which prevents reentrancy since `safeGetOpMetadata`
        // will fail afterwards.
        _deleteOpHandle(user, opHandle);
    }

    /**
     * @dev Returns the hash of (user, opId) which is used as a look-up
     * key in the `_opMetadata` mapping.
     */
    function _getOpKey(address user, uint64 opId)
        internal
        pure
        returns (bytes32)
    {
        return keccak256(abi.encodePacked(user, opId));
    }

    /**
     * @dev Deriving contracts can override this function to accept a boosterMessage for a given booster and
     * interpret it into a hash and timestamp.
     */
    function decodeAndHashBoosterMessage(
        address targetBooster,
        bytes memory boosterMessage
    ) external virtual view returns (bytes32, uint64) {}

    /**
     * @dev Returns the tag found in the given `boosterMesasge`.
     */
    function _readBoosterTag(bytes memory boosterMessage)
        internal
        pure
        returns (uint8)
    {
        // The tag is either the 32th byte or the 64th byte depending on whether
        // the booster message contains dynamic bytes or not.
        //
        // If it contains a dynamic byte array, then the first word points to the first
        // data location.
        //
        // Therefore, we read the 32th byte and check if it's >= 32 and if so,
        // simply read the (32 + first word)th byte to get the tag.
        //
        // This imposes a limit on the number of tags we can support (<32), but
        // given that it is very unlikely for so many tags to exist it is fine.
        //
        // Read the 32th byte to get the tag, because it is a uint8 padded to 32 bytes.
        // i.e.
        // -----------------------------------------------------------------v
        // 0x0000000000000000000000000000000000000000000000000000000000000001
        //   ...
        //
        uint8 tag = uint8(boosterMessage[31]);
        if (tag >= 32) {
            // Read the (32 + tag) byte. E.g. if tag is 32, then we read the 64th:
            // --------------------------------------------------------------------
            // 0x0000000000000000000000000000000000000000000000000000000000000020 |
            //   0000000000000000000000000000000000000000000000000000000000000001 <
            //   ...
            //
            tag = uint8(boosterMessage[31 + tag]);
        }

        return tag;
    }
}
