// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

interface IMutationRegistry {
    struct Mutation {
        bool enabled;
        bool finalized;
        uint8 prev;
        uint8 next;
        uint8 geneCount;
        address interpreter;
        uint256 cost;
    }

    function getMutation(uint256 mutationId)
        external
        view
        returns (Mutation memory);
}
