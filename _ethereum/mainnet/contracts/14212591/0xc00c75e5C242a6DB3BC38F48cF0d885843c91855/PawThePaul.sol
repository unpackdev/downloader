// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "ERC721URIStorage.sol";
// import "ERC721Pausable.sol";
import "ERC721Enumerable.sol";
import "Ownable.sol";
import "Counters.sol";
import "Strings.sol";

contract PawThePaul is ERC721URIStorage, Ownable {
    using Counters for Counters.Counter;
    uint256 public MAX_DOGS;
    address private contractOwner;
    Counters.Counter private tokenIdCounter;
    string private _baseURIextended;
    uint256 public tokenPrice = 40000000000000000; //0.04 ETH
    mapping(uint256 => string) private _tokenURIs;
    bool public paused = true;

    constructor(
        string memory name,
        string memory symbol,
        uint256 maxNftSupply,
        uint256 saleStart,
        string memory base
    ) public ERC721(name, symbol) {
        MAX_DOGS = maxNftSupply;
        tokenIdCounter.reset();
        contractOwner = msg.sender;
        _baseURIextended = base;
    }

    function checkTokenCounter() external view returns (uint256) {
        return tokenIdCounter.current();
    }

    function _baseURI() internal view virtual override returns (string memory) {
        return _baseURIextended;
    }

    function setBaseURI(string memory baseURI_) external onlyOwner {
        _baseURIextended = baseURI_;
    }

    function tokenURI(uint256 tokenId)
        public
        view
        virtual
        override
        returns (string memory)
    {
        require(
            _exists(tokenId),
            "ERC721URIStorage: URI query for nonexistent token"
        );

        string memory _tokenURI = _tokenURIs[tokenId];
        string memory base = _baseURI();

        // If there is no base URI, return the token URI.
        if (bytes(base).length == 0) {
            return _tokenURI;
        }
        // If both are set, concatenate the baseURI and tokenURI (via abi.encodePacked).
        if (bytes(_tokenURI).length > 0) {
            return _tokenURI;
        }

        string memory tokenURI = Strings.toString(tokenId);
        string memory ext = ".json";
        tokenURI = string(abi.encodePacked(_baseURIextended, tokenURI));
        tokenURI = string(abi.encodePacked(tokenURI, ext));
        return tokenURI;
    }

    function _setTokenURI(uint256 tokenId, string memory _tokenURI)
        internal
        virtual
        override
    {
        require(
            _exists(tokenId),
            "ERC721Metadata: URI set of nonexistent token"
        );
        _tokenURIs[tokenId] = _tokenURI;
    }

    function setTokenURI(uint256 tokenId, string memory _tokenURI) external {
        require(
            _isApprovedOrOwner(_msgSender(), tokenId),
            "ERC721: caller is not owner or approved"
        );
        _setTokenURI(tokenId, _tokenURI);
    }

    function mint(uint256 numberOfTokens) external payable returns (uint256) {
        require(!paused);
        require(msg.value >= numberOfTokens * tokenPrice);
        require(tokenIdCounter.current() + numberOfTokens <= MAX_DOGS);
        // mint numberOfTokens Tokens
        for (uint256 i = 0; i < numberOfTokens; i++) {
            uint256 newItemId = tokenIdCounter.current();
            _safeMint(msg.sender, newItemId);
            _setTokenURI(newItemId, tokenURI(newItemId));
            tokenIdCounter.increment();
        }
        return tokenIdCounter.current();
    }

    function pause(bool _state) public onlyOwner {
        paused = _state;
    }

    function setPrice(uint256 newPrice) external onlyOwner {
        tokenPrice = newPrice;
    }

    function withdraw() external payable onlyOwner {
        payable(msg.sender).transfer(address(this).balance);
    }

    function specialMint(uint256 tokenId, string memory _tokenURI)
        external
        payable
        onlyOwner
    {
        require(tokenId >= 4000);
        _safeMint(msg.sender, tokenId);
        _setTokenURI(tokenId, _tokenURI);
    }
}
