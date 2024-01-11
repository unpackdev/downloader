// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "./ERC721A.sol";
import "./Ownable.sol";
import "./Pausable.sol";
import "./ERC721AQueryable.sol";

contract ForBuilders is ERC721AQueryable, Ownable, Pausable {

    uint256 public constant MAX_SUPPLY = 1000;
    bool public saleStatus = false;
    string public tokenBaseURI = "https://peanuthub.s3.amazonaws.com/gen0/";
    uint256 public maxMintPerUser = 5;

    constructor() ERC721A("For the Testers", "TESTING") {
        _safeMint(_msgSender(), 1);
    }

    function updateSaleState(bool _saleState) external onlyOwner {
        saleStatus = _saleState;
    }

    function updateBaseUri(string memory baseURI) external onlyOwner {
        tokenBaseURI = baseURI;
    }

    function pause() external onlyOwner {
        _pause();
    }

    function unpause() external onlyOwner {
        _unpause();
    }

    function _startTokenId() internal view virtual override returns (uint256) {
        return 0;
    }

    function tokenURI(uint256 tokenId) public view virtual override(ERC721A) returns (string memory) {
        require(_exists(tokenId), "ERC721Metadata: URI query for nonexistent token");

        return string(abi.encodePacked(_baseURI(), _toString(tokenId), ".json"));
    }

    function _baseURI() internal view virtual override returns (string memory) {
        return tokenBaseURI;
    }

    function mintPublic(uint256 numTokens) external {
        require(saleStatus, "SALE_NOT_STARTED");

        require(totalSupply() + numTokens <= MAX_SUPPLY, "EXCEEDS_SUPPLY");

        require(_numberMinted(_msgSender()) + numTokens <= maxMintPerUser, "EXCEEDS_LIMIT");

        _safeMint(_msgSender(), numTokens);
    }

    function _beforeTokenTransfers(
        address from,
        address to,
        uint256 startTokenId,
        uint256 quantity
    ) internal override whenNotPaused {
        super._beforeTokenTransfers(from, to, startTokenId, quantity);
    }
}
