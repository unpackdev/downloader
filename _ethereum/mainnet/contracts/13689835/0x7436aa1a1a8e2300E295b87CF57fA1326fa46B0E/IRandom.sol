// SPDX-License-Identifier: MIT

pragma solidity ^0.8.6;

interface IRandom {
    /**
     * @dev Returns the URI for token type `id`.
     *
     * If the `\{id\}` substring is present in the URI, it must be replaced by
     * clients with the actual token type ID.
     */
    function requestChainLinkEntropy() external returns (bytes32 requestId);
}

