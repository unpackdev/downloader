// SPDX-License-Identifier: MIT
pragma solidity ^0.8.1;

import "./ERC721.sol";
import "./Counters.sol";
import "./Ownable.sol";

contract NFT is ERC721, Ownable {
    using Counters for Counters.Counter;

    Counters.Counter private currentTokenId;

    uint256 private maxTokenId;

    string public baseTokenURI;

    constructor() ERC721("CryptoWorld", "NFT") {
        baseTokenURI = "https://bafybeibwabrptvima3g6cc4eva7vz7ptjfrplqc5dlsjvp7qwlg7433a4i.ipfs.nftstorage.link/metadata/";
        maxTokenId = 80;
    }

    /// @dev This function returns the contract level metadata url
    function contractURI() pure public returns (string memory) {
        return "https://ipfs.io/ipfs/bafkreif5kbz7jnkx76rposdxtcra3pmydv6bo3wp2hlfjhbhcygnrjaobi";
    }

    /// @dev This function sets the maximum number of tokens that can be created.
    function setMaxTokenId(uint256 _maxTokenId) public onlyOwner {
        require(_maxTokenId >= currentTokenId.current());
        maxTokenId = _maxTokenId;
    }

    /// @dev This function is called by the contract owner to mint a new token.
    function mintTo(address recipient) public onlyOwner {
        currentTokenId.increment();
        uint256 newItemId = currentTokenId.current();
        _safeMint(recipient, newItemId);
    }

    /// @dev This function is used by the contract owner to batch mint multiple tokens to the same address
    function batchMint(address recipient, uint256 count) public onlyOwner {
        for (uint256 i = 0; i < count; i++) {
            mintTo(recipient);
        }
    }

    /// @dev This function is used to batch transfer tokens to multiple recipients.
    function batchTransfer(
        address[] calldata recipients,
        uint256[] calldata tokenIds
    ) public {
        require(recipients.length == tokenIds.length);
        for (uint256 i = 0; i < tokenIds.length; i++) {
            safeTransferFrom(msg.sender, recipients[i], tokenIds[i]);
        }
    }

    /// @dev This function is used to batch approve token transfers.
    function batchApprove(
        address[] calldata recipients,
        uint256[] calldata tokenIds
    ) public {
        require(recipients.length == tokenIds.length);
        for (uint256 i = 0; i < tokenIds.length; i++) {
            approve(recipients[i], tokenIds[i]);
        }
    }

    /// @dev Returns an URI for a given token ID
    function _baseURI() internal view virtual override returns (string memory) {
        return baseTokenURI;
    }

    /// @dev Sets the base token URI prefix.
    function setBaseTokenURI(string memory _baseTokenURI) public onlyOwner {
        baseTokenURI = _baseTokenURI;
    }
}
