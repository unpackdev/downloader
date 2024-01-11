// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "./Ownable.sol";
import "./ERC721Enumerable.sol";
import "./Counters.sol";
import "./Pausable.sol";
import "./ERC2981.sol";
import "./Strings.sol";
import "./ERC721.sol";

contract Builders is ERC721, Ownable, ERC721Enumerable, ERC2981, Pausable {
    using Counters for Counters.Counter;
    Counters.Counter private _tokenIds;

    uint256 public constant MAX_SUPPLY = 1000;

    uint256 public maxMintPerUser = 5;

    string public tokenBaseURI = "https://peanuthub.s3.amazonaws.com/gen0/";

    bool public saleStatus = false;

    constructor(address _royaltyReceiver) ERC721("For the Builders", "BUILDER") {
        _setDefaultRoyalty(_royaltyReceiver, 500);
        mint(msg.sender, 1);
    }

    /**
        Function to mint internal
     */

    function mint(address to, uint256 numberOfTokens) internal {
        for (uint256 i = 1; i <= numberOfTokens; i++) {
            _tokenIds.increment();
            _mint(to, _tokenIds.current());
        }
    }

    function mintPublic(uint256 numTokens) external {
        require(saleStatus, "SALE_NOT_STARTED");

        require(totalSupply() + numTokens <= MAX_SUPPLY, "EXCEEDS_SUPPLY");

        require(balanceOf(_msgSender()) + numTokens <= maxMintPerUser, "EXCEEDS_LIMIT");

        mint(_msgSender(), numTokens);
    }

    function supportsInterface(bytes4 interfaceId) public view virtual override(ERC721, ERC721Enumerable, ERC2981) returns (bool) {
        return super.supportsInterface(interfaceId);
    }

    function _beforeTokenTransfer(address from, address to, uint256 tokenId) internal
    whenNotPaused
    override(ERC721, ERC721Enumerable)
    {
        super._beforeTokenTransfer(from, to, tokenId);
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

    function tokenURI(uint256 tokenId) public view virtual override(ERC721) returns (string memory) {
        require(_exists(tokenId), "ERC721Metadata: URI query for nonexistent token");

        return string(abi.encodePacked(_baseURI(), Strings.toString(tokenId), ".json"));
    }

    function _baseURI() internal view virtual override returns (string memory) {
        return tokenBaseURI;
    }

    function setDefaultRoyalty(address _receiver, uint96 _feeNumerator) external onlyOwner {
        _setDefaultRoyalty(_receiver, _feeNumerator);
    }

    function tokensOfOwner(address _owner)
    public
    view
    returns (uint256[] memory)
    {
        uint256 tokenCount = balanceOf(_owner);
        uint256[] memory tokensId = new uint256[](tokenCount);
        for (uint256 i; i < tokenCount; i++) {
            tokensId[i] = tokenOfOwnerByIndex(_owner, i);
        }
        return tokensId;
    }
}
