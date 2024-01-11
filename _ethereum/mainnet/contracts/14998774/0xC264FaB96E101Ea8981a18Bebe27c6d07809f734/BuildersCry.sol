// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "./Ownable.sol";
import "./ReentrancyGuard.sol";
import "./Strings.sol";
import "./ERC721A.sol";

contract BuildersCry is Ownable, ERC721A, ReentrancyGuard {
    bool public paused = true;
    uint256 maxMintPerUser = 5;
    uint256 maxSupply = 1000;
    string public tokenBaseURI = "https://peanuthub.s3.amazonaws.com/gen0/";

    constructor() ERC721A("For the Builders", "BUILDER", maxMintPerUser, maxSupply) {}

    function publicSaleMint(uint256 quantity) external payable {

        require(!paused, "sale paused");
        require(totalSupply() + quantity <= maxSupply, "EXCEEDS_SUPPLY");
        require(balanceOf(msg.sender) + quantity <= maxMintPerUser, "EXCEEDS_LIMIT");
        require(totalSupply() + quantity <= collectionSize, "reached max supply");

        _safeMint(msg.sender, quantity);
    }

    function _baseURI() internal view virtual override returns (string memory) {
        return tokenBaseURI;
    }

    function setBaseURI(string calldata baseURI) external onlyOwner {
        tokenBaseURI = baseURI;
    }

    function pauseSale() external onlyOwner {
        paused = true;
    }

    function allowSale() external onlyOwner {
        paused = false;
    }

    function withdrawMoney() external onlyOwner nonReentrant {
        (bool success, ) = msg.sender.call{value: address(this).balance}("");
        require(success, "Transfer failed.");
    }

    function numberMinted(address owner) public view returns (uint256) {
        return _numberMinted(owner);
    }

    function tokenURI(uint256 tokenId) public view virtual override returns (string memory) {
        require(_exists(tokenId), "ERC721Metadata: URI query for nonexistent token");

        return string(abi.encodePacked(_baseURI(), Strings.toString(tokenId), ".json"));
    }

    function tokensOfOwner(address _owner) external view returns (uint256[] memory) {
        uint256 tokenCount = balanceOf(_owner);
        uint256[] memory tokensId = new uint256[](tokenCount);
        for (uint256 i = 0; i < tokenCount; i++) {
            tokensId[i] = tokenOfOwnerByIndex(_owner, i);
        }
        return tokensId;
    }

    function getOwnershipData(uint256 tokenId)
    external
    view
    returns (TokenOwnership memory)
    {
        return ownershipOf(tokenId);
    }
}
