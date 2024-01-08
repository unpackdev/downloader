// SPDX-License-Identifier: GPL-3.0
pragma solidity 0.8.9;

import "./ERC721Base.sol";
import "./ERC721Delegated.sol";

import "./CountersUpgradeable.sol";

contract CryptoFBoys is ERC721Delegated {
    // Start at token id 69 – previous tokens are reserved for 1155 contract
    // previous 1155 contract at 0xadc60305b9df338f1b5adc09e2cba69178465739
    uint256 private currentTokenId = 69;

    constructor(IBaseERC721Interface baseFactory)
        ERC721Delegated(
            baseFactory,
            "CryptoFBoys",
            "CFBOY",
            ConfigSettings({
                royaltyBps: 1500,
                uriBase: "https://arweave.net/o3NyrUFLHUmLelOn_JQC0urmaIMYIcV_6qk7aAIMpbU/",
                uriExtension: ".json",
                hasTransferHook: false
            })
        )
    {}

    function mintBatch(uint256 count) public onlyOwner {
        uint256 startAt = currentTokenId;
        while (currentTokenId < startAt + count) {
            _mint(msg.sender, currentTokenId);
            // Increment operation cannot overflow.
            unchecked {
                currentTokenId++;
            }
        }
    }

    function burn(uint256 tokenId) public {
        require(_isApprovedOrOwner(msg.sender, tokenId));
        _burn(tokenId);
    }

    // used before minting new NFTs
    function setBaseURI(string memory newUriBase, string memory newExtension)
        public
        onlyOwner
    {
        _setBaseURI(newUriBase, newExtension);
    }
}
