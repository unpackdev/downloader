// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;
import "./ERC721.sol";
import "./Ownable.sol";
import "./Counters.sol";

/// @custom:security-contact dev@stake.fish
contract TheChuChuCup is ERC721, Ownable {
    string constant METADATA_URI = "ipfs://QmQNerCvXJq59RztvfrQrZdt1evG8vaZUKNRLY9sUB2AHu";
    uint256 constant MAX_SUPPLY = 200;
    uint256 private _tokenIdCounter = 0;
    constructor() ERC721("The ChuChu Cup", "The ChuChu Cup") {}
    function batchMint(address[] calldata to) public onlyOwner {
        require(to.length + _tokenIdCounter <= MAX_SUPPLY, "Exceeds max supply");
        uint256 tokenId = _tokenIdCounter;
        for (uint256 i = 0; i < to.length; i++) {
            _mint(to[i], tokenId);
            tokenId++;
        }
        _tokenIdCounter = tokenId;
    }
    function tokenURI(uint256 tokenId) public pure override returns (string memory) {
        return METADATA_URI;
    }
}
