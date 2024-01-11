// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "./IMutationRegistry.sol";
import "./Ownable.sol";

/**
 * @dev Mutation data storage and operations.
 */
contract MutationRegistry is Ownable, IMutationRegistry {
    uint256 constant MAX_MUTATIONS = 256;

    // List of mutations
    mapping(uint256 => Mutation) private _mutations;

    modifier mutationExists(uint256 mutationId) {
        require(
            _mutations[mutationId].interpreter != address(0),
            "MutationRegistry: query for nonexistent mutation"
        );
        _;
    }

    /**
     * @dev Initialize a new instance with an active base mutation.
     */
    constructor(address interpreter) {
        loadMutation(0, true, false, 0, 0, 0, interpreter, 0);
    }

    /**
     * @dev Retrieves a mutation.
     */
    function getMutation(uint256 mutationId)
        public
        view
        override
        returns (Mutation memory)
    {
        return _mutations[mutationId];
    }

    /**
     * @dev Loads a new mutation.
     * @param enabled mutation can be mutated to
     * @param finalized mutation can't be updated
     * @param prev mutation link, 0 is any
     * @param next mutation link, 0 is any
     * @param geneCount required for the mutation
     * @param interpreter address for the mutation
     * @param cost of unlocking the mutation
     */
    function loadMutation(
        uint8 mutationId,
        bool enabled,
        bool finalized,
        uint8 prev,
        uint8 next,
        uint8 geneCount,
        address interpreter,
        uint256 cost
    ) public onlyOwner {
        require(
            _mutations[mutationId].interpreter == address(0),
            "MutationRegistry: load to existing mutation"
        );

        require(
            interpreter != address(0),
            "MutationRegistry: invalid interpreter"
        );

        _mutations[mutationId] = Mutation(
            enabled,
            finalized,
            prev,
            next,
            geneCount,
            interpreter,
            cost
        );
    }

    /**
     * @dev Toggles a mutation's enabled state.
     * note finalized mutations can't be toggled.
     */
    function toggleMutation(uint256 mutationId)
        external
        onlyOwner
        mutationExists(mutationId)
    {
        Mutation storage mutation = _mutations[mutationId];

        require(
            !mutation.finalized,
            "MutationRegistry: toggle to finalized mutation"
        );

        mutation.enabled = !mutation.enabled;
    }

    /**
     * @dev Marks a mutation as finalized, preventing it from being updated in the future.
     * note this action can't be reverted.
     */
    function finalizeMutation(uint256 mutationId)
        external
        onlyOwner
        mutationExists(mutationId)
    {
        _mutations[mutationId].finalized = true;
    }

    /**
     * @dev Updates a mutation's interpreter.
     * note finalized mutations can't be updated.
     */
    function updateMutationInterpreter(uint256 mutationId, address interpreter)
        external
        onlyOwner
        mutationExists(mutationId)
    {
        Mutation storage mutation = _mutations[mutationId];

        require(
            interpreter != address(0),
            "MutationRegistry: zero address interpreter"
        );

        require(
            !mutation.finalized,
            "MutationRegistry: update to finalized mutation"
        );

        mutation.interpreter = interpreter;
    }

    /**
     * @dev Updates a mutation's links.
     * note finalized mutations can't be updated.
     */
    function updateMutationLinks(
        uint8 mutationId,
        uint8 prevMutationId,
        uint8 nextMutationId
    ) external onlyOwner mutationExists(mutationId) {
        Mutation storage mutation = _mutations[mutationId];

        require(
            !mutation.finalized,
            "MutationRegistry: update to finalized mutation"
        );

        mutation.prev = prevMutationId;
        mutation.next = nextMutationId;
    }
}
