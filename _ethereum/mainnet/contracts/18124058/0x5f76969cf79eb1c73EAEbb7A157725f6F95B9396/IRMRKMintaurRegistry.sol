//SPDX-License-Identifier: Apache 2.0

pragma solidity ^0.8.21;

/**
 * @title RMRK Mint'aur Registry Interface
 * @notice
 */
interface IRMRKMintaurRegistry {
    function mint(
        address collection,
        address to,
        uint256 numToMint
    ) external payable;

    function storeNewCollection(
        address collection,
        uint256 mintPrice,
        uint256 mintFee,
        address beneficiary,
        uint256 cutOffDate
    ) external;
}
