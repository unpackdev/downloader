// SPDX-License-Identifier: MIT
pragma solidity 0.8.2;

interface ISimpleERC1155Project {
    /**
     * @dev batch mint a token. Can only be called by a registered manager.
     * Returns tokenIds minted
     */
    function managerMintBatch(
        address[] calldata to,
        uint256[] calldata tokenIds,
        uint256[] calldata amounts,
        bytes calldata data
    ) external;
}
