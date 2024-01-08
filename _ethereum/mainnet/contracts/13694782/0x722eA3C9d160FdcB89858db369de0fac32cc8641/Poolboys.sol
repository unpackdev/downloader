// SPDX-License-Identifier: MIT
pragma solidity 0.8.9;

import "./ERC721.sol";
import "./Counters.sol";
import "./Ownable.sol";
import "./ReentrancyGuard.sol";

/// @title Poolboys Metatourism NFT
contract Poolboys is ERC721, Ownable, ReentrancyGuard {
    using Counters for Counters.Counter;
    Counters.Counter private _tokenIdCounter;

    uint256 private collectionStartingIndexBlock;
    uint256 public collectionStartingIndex;
    string public PBOY_PROVENANCE = "";

    uint256 public pboyPrice = 10000000000000000; //0.01 ETH
    uint256 public constant maxPurchase = 30;
    uint256 public constant MAX_PBOYS = 4444;

    bool public publicSaleActive = false;

    string private _baseURIextended;

    constructor() ERC721("Poolboys", "PBOY") {}

    function withdraw() external onlyOwner {
        payable(msg.sender).transfer(address(this).balance);
    }

    function setPrice(uint256 newPrice) external onlyOwner {
        pboyPrice = newPrice;
    }

    /// @notice Set base for the reveal
    function setBaseURI(string memory baseURI_) external onlyOwner() {
        _baseURIextended = baseURI_;
    }
    function _baseURI() internal view virtual override returns (string memory) {
        return _baseURIextended;
    }

    /// @notice Returns the total current supply
    function totalSupply() external view returns (uint256) {
        return _tokenIdCounter.current();
    }

    /// @notice Pause sale if active, make active if paused
    function flipSaleState() external onlyOwner {
        publicSaleActive = !publicSaleActive;
    }

    function _mintToken(address _to, uint numberOfTokens) private {
        require(numberOfTokens <= maxPurchase, "Can only mint 30 tokens at a time");
        require(_tokenIdCounter.current() + numberOfTokens <= MAX_PBOYS, "Purchase would exceed max supply");

        for(uint256 i; i < numberOfTokens; i++) {
            uint256 tokenId = _tokenIdCounter.current();
            if (tokenId < MAX_PBOYS) {
                _tokenIdCounter.increment();
                _safeMint(_to, tokenId);
            }
        }
    }

    /// @notice Set Poolboys aside for giveaways
    function reserveToken(address _to, uint numberOfTokens) external onlyOwner {
        _mintToken(_to,numberOfTokens);
    }

    /// @notice Mint Poolboys
    function mintToken(uint numberOfTokens) external payable nonReentrant {
        require(publicSaleActive, "Public sale is not active");
        require(pboyPrice * numberOfTokens <= msg.value, "Ether value sent is not correct");
        _mintToken(msg.sender,numberOfTokens);
        if (collectionStartingIndex == 0) {
            collectionStartingIndexBlock = block.number;
        }

    }

    /// @notice Set the starting index for the collection
    function setStartingIndices() external onlyOwner {

        require(collectionStartingIndexBlock != 0, "Starting index block must be set");
        require(collectionStartingIndex == 0, "Starting index is already set");

        collectionStartingIndex = uint256(blockhash(collectionStartingIndexBlock)) % MAX_PBOYS;

        if ((block.number - collectionStartingIndexBlock) > 255) {
            collectionStartingIndex = uint256(blockhash(collectionStartingIndexBlock - 1)) % MAX_PBOYS;
        }

        if (collectionStartingIndex == 0) {
            collectionStartingIndex++;
        }
    }

    /// @notice Set provenance once it's calculated
    function setProvenanceHash(string memory provenanceHash) external onlyOwner {
        PBOY_PROVENANCE = provenanceHash;
    }
}

