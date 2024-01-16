// SPDX-License-Identifier: MIT

pragma solidity 0.8.2;

import "./IERC165.sol";

/**
 * @dev Required interface of an ERC721Project compliant manager contracts.
 */
interface IERC721ProjectMintPermissions is IERC165 {
    /**
     * @dev get approval to mint
     */
    function approveMint(
        address manager,
        address to,
        uint256 tokenId
    ) external;
}
