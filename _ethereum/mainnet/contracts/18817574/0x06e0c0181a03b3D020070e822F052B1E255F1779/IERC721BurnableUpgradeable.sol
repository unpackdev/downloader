// SPDX-License-Identifier: MIT

pragma solidity 0.8.19;

interface IERC721BurnableUpgradeable {
    error ERC721BurnableUpgradeable__NotOwnerNorApproved();

    function burn(uint256 tokenId) external;
}
