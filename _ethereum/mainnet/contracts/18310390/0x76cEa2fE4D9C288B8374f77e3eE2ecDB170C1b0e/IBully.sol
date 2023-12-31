//SPDX-License-Identifier: MIT
pragma solidity 0.8.18;

interface IBully {
    struct Bully {
        uint256 tokenId;
        bool staked;
    }

    function claimBatchFor(address recipient, Bully[] calldata bullies) external;
    function batchStakeFor(address owner, uint256[] calldata tokenIds) external;
    function batchUnstakeFor(address owner, uint256[] calldata tokenIds) external;
}
