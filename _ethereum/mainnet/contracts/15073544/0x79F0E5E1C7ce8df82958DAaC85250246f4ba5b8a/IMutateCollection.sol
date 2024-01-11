// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

interface IMutateCollection {
    /**
     * @dev mint nft in mutate mode
     */
    function mutateMint(uint256 tokenId, address recipient) external;
}
