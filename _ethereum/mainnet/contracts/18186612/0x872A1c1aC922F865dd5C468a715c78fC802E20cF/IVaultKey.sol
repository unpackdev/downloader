// SPDX-License-Identifier: MIT
pragma solidity 0.8.4;

import "./IERC721Enumerable.sol";

interface IVaultKey is IERC721Enumerable {
    function mintKey(address to, address vault) external;

    function lastMintedKeyId(address to) external view returns (uint256);

    event VaultKeyMinted(uint256 previousBlock, address indexed to, uint256 indexed tokenId, address indexed vault);
    event VaultKeyTransfer(uint256 previousBlock, address from, address indexed to, uint256 indexed tokenId);
}
