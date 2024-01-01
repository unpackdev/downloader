// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "./BoundlessAuthenticityCertificates.sol";
import "./OwnableUpgradeable.sol";
import "./Strings.sol";
import "./Base64.sol";

contract BoundlessAuthenticityCertificatesV2 is
    BoundlessAuthenticityCertificates,
    OwnableUpgradeable
{
    error TokenNotFound();

    function tokenURI(
        uint256 tokenId
    ) public view virtual override(ERC721Upgradeable) returns (string memory) {
        if (!_exists(tokenId)) {
            revert TokenNotFound();
        }

        string memory metadata = string(
            abi.encodePacked(
                "data:application/json;base64,",
                Base64.encode(
                    abi.encodePacked(
                        '{ "name": "Certificate of Authenticity for Boundless NFT ',
                        Strings.toString(tokenId),
                        '",',
                        '"image": "https://v2-liveart.mypinata.cloud/ipfs/Qmdd2Hf8VoZT1AWzJX1Nt3zrLvcCLvXUFiNfwHn6yqR7in",',
                        '"properties": { "artistName": "Yue Minjun" },',
                        '"description": "Yue Minjun\'s NFT Boundless collection transitions from digital to physical with a unique collection of signed prints backed by an NFT Certificate of Authenticity",',
                        '"nft_contract_address": "0x8A27d3f7F42C7B43051e12C150e2A75E9181bFF3"',
                        "}"
                    )
                )
            )
        );

        return metadata;
    }

    function initializeOwner() public onlyAdmin {
        _transferOwnership(msg.sender);
    }
}
