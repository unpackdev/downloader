// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "./ERC721.sol";
import "./Ownable.sol";
import "./MerkleProof.sol";
import "./Pausable.sol";

contract Wanderary is ERC721, Ownable, Pausable {
    string internal baseURI;

    constructor(string memory baseURI_) ERC721("Wanderary", "WANDERARY") {
        baseURI = baseURI_;
        _pause();
    }

    /// Pauses the contract.
    function pause() external whenPaused {
        _pause();
    }

    /// Unpauses the contract.
    function unpause() external whenNotPaused {
        _unpause();
    }

    /// Returns the base URI
    function _baseURI() internal view override returns (string memory) {
        return baseURI;
    }

    /// Set a new base URI
    /// @param newBaseURI the new base URI
    function setBaseURI(string calldata newBaseURI) external onlyOwner {
        baseURI = newBaseURI;
    }

    /// Admin mint
    /// @param to address to mint to
    /// @param tokenId token ID to mint
    function safeMint(address to, uint256 tokenId) external onlyOwner {
        _safeMint(to, tokenId);
    }
}
