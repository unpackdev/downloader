// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;
import "./Ownable.sol";
import "./ERC721AQueryable.sol";
import "./Pausable.sol";
import "./ERC2981.sol";

contract Genesis is ERC721AQueryable, ERC2981, Ownable, Pausable {
    uint256 public constant MAX_SUPPLY = 1000;

    uint256 public maxMintPerUser = 5;

    bool public saleStatus = false;

    string public tokenBaseURI = "https://peanuthub.s3.amazonaws.com/gen0/";

    constructor() ERC721A("Builders", "BBOTS") {
        _setDefaultRoyalty(msg.sender, 500);
    }

    function mintGenesis(uint256 numTokens) external {
        require(saleStatus, "SALE_NOT_STARTED");

        require(totalSupply() + numTokens <= MAX_SUPPLY, "EXCEEDS_SUPPLY");

        require(_numberMinted(_msgSender()) + numTokens <= maxMintPerUser, "EXCEEDS_LIMIT");

        _safeMint(_msgSender(), numTokens);
    }

    function supportsInterface(bytes4 interfaceId) public view virtual override(ERC721A, ERC2981) returns (bool) {
        return super.supportsInterface(interfaceId);
    }

    function _beforeTokenTransfers(
        address from,
        address to,
        uint256 tokenId
    ) internal whenNotPaused {
        super._beforeTokenTransfers(from, to, tokenId, 1);
    }

    function pause() external onlyOwner {
        _pause();
    }

    function unpause() external onlyOwner {
        _unpause();
    }

    function updateSaleState(bool _saleState) external onlyOwner {
        saleStatus = _saleState;
    }

    function updateBaseUri(string memory baseURI) external onlyOwner {
        tokenBaseURI = baseURI;
    }

    function withdraw() external onlyOwner {
        (bool os, ) = payable(msg.sender).call{value: address(this).balance}("");
        require(os);
    }

    function _startTokenId() internal view virtual override returns (uint256) {
        return 1;
    }

    function tokenURI(uint256 tokenId) public view virtual override(ERC721A) returns (string memory) {
        require(_exists(tokenId), "ERC721Metadata: URI query for nonexistent token");

        return string(abi.encodePacked(_baseURI(), _toString(tokenId), ".json"));
    }

    function _baseURI() internal view virtual override returns (string memory) {
        return tokenBaseURI;
    }

    function setDefaultRoyalty(address _receiver, uint96 _feeNumerator) external onlyOwner {
        _setDefaultRoyalty(_receiver, _feeNumerator);
    }
}
