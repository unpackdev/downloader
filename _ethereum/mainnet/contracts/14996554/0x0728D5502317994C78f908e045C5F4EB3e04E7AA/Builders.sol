// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./Ownable.sol";
import "./ReentrancyGuard.sol";
import "./Strings.sol";
import "./Pausable.sol";
import "./ERC2981.sol";
import "./console.sol";
import "./ERC721A.sol";

contract Builders is ERC721A, ERC2981, Ownable, ReentrancyGuard,Pausable {

    uint256 public maxMintPerUser;
    uint256 public constant MAX_SUPPLY = 1000;

    bool public saleStatus = false;

    string public tokenBaseURI = "https://test-nft/";

    constructor(address _royaltyReceiver) ERC721A("This is just the test", "TESTING", 5, 1000) {
        maxMintPerUser = 5;
        _setDefaultRoyalty(_royaltyReceiver, 500);
        _safeMint(_msgSender(), 5);
    }

    modifier callerIsUser() {
        require(tx.origin == msg.sender, "The caller is another contract");
        _;
    }

    function mintPublic(uint256 numTokens) external callerIsUser nonReentrant {
        require(saleStatus, "SALE_NOT_STARTED");

        require(totalSupply() + numTokens <= MAX_SUPPLY, "EXCEEDS_SUPPLY");

        require(_numberMinted(_msgSender()) + numTokens <= maxMintPerUser, "EXCEEDS_LIMIT");

        _safeMint(_msgSender(), numTokens);
    }

    function _baseURI() internal view virtual override returns (string memory) {
        return tokenBaseURI;
    }

    function updateBaseUri(string memory baseURI) external onlyOwner {
        tokenBaseURI = baseURI;
    }

    function tokensOfOwner(address _owner) external view returns (uint256[] memory) {
        uint256 tokenCount = balanceOf(_owner);
        uint256[] memory tokensId = new uint256[](tokenCount);
        for (uint256 i = 0; i < tokenCount; i++) {
            tokensId[i] = tokenOfOwnerByIndex(_owner, i);
        }
        return tokensId;
    }

    function updateSaleState(bool state) external onlyOwner {
        saleStatus = state;
    }

    function tokenURI(uint256 tokenId) public view virtual override returns (string memory) {
        require(_exists(tokenId), "ERC721Metadata: URI query for nonexistent token");

        return string(abi.encodePacked(_baseURI(), Strings.toString(tokenId), ".json"));
    }

    function _beforeTokenTransfers(
        address from,
        address to,
        uint256 startTokenId,
        uint256 quantity
    ) internal override whenNotPaused {
        super._beforeTokenTransfers(from, to, startTokenId, quantity);
    }

    function pause() external onlyOwner {
        _pause();
    }

    function unpause() external onlyOwner {
        _unpause();
    }

    function setDefaultRoyalty(address _receiver, uint96 _feeNumerator) external onlyOwner {
        _setDefaultRoyalty(_receiver, _feeNumerator);
    }

    function supportsInterface(bytes4 interfaceId) public view virtual override(ERC721A, ERC2981) returns (bool) {
        return super.supportsInterface(interfaceId);
    }
}
