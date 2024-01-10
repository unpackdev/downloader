// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "./ERC721.sol";
import "./ERC721Enumerable.sol";
import "./ERC721URIStorage.sol";
import "./ReentrancyGuard.sol";
import "./Pausable.sol";
import "./Ownable.sol";
import "./Counters.sol";

contract DickPass is ERC721, ERC721Enumerable, ReentrancyGuard, Pausable, Ownable {
    using Counters for Counters.Counter;
    using Strings for uint256;

    Counters.Counter private _tokenIdCounter;
    uint256 private passPrice = 0.025 ether;
    string private baseURI = "ipfs://QmXx1iTVatuuS3hjUK2sJts4V4qGxtkoY1gF7YMYTpebjn/";
    uint256 private maxPasses = 500;
    constructor() ERC721("Dick Pass", "DPASS") {}

    modifier publicMintChecks() {
        require(msg.value >= passPrice, "DickPass: Insufficient value");
        require(totalSupply() < maxPasses, "DickPass: Passes sold out");
        _;
    }

    function pause() public onlyOwner {
        _pause();
    }

    function unpause() public onlyOwner {
        _unpause();
    }

    function getMaxPasses() public view returns (uint256) {
        return maxPasses;
    }

    function setMaxPasses(uint256 _maxPasses) public onlyOwner {
        require(_maxPasses > totalSupply(), "Max passes must be greater than current supply.");
        maxPasses = _maxPasses;
    }

    function getPassPrice() public view returns (uint256) {
        return passPrice;
    }

    function setPassPrice(uint256 _passPrice) public onlyOwner {
        passPrice = _passPrice;
    }

    function setBaseURI(string memory _newURI) public onlyOwner {
        baseURI = _newURI;
    }

    function safeMint() public payable whenNotPaused publicMintChecks {
        address to = msg.sender;
        _tokenIdCounter.increment();
        uint256 tokenId = _tokenIdCounter.current();
        _safeMint(to, tokenId);
    }

    function safeMint(uint256 _amount) public whenNotPaused onlyOwner  {
        require(totalSupply() + _amount <= maxPasses, "DickPass: Exceeding MaxSupply");
        address to = msg.sender;
        for(uint256 i=0; i<_amount; i++) {
            _tokenIdCounter.increment();
            uint256 tokenId = _tokenIdCounter.current();
            _safeMint(to, tokenId);
        }
    }

    // Utilities
    function withdraw() external onlyOwner nonReentrant {
        payable(owner()).transfer(address(this).balance);
    }

    // The following functions are overrides required by Solidity.
    function _beforeTokenTransfer(address from, address to, uint256 tokenId)
        internal
        whenNotPaused
        override(ERC721, ERC721Enumerable)
    {
        super._beforeTokenTransfer(from, to, tokenId);
    }

    function _baseURI() internal view override returns (string memory) {
        return baseURI;
    }

    function supportsInterface(bytes4 interfaceId)
        public
        view
        override(ERC721, ERC721Enumerable)
        returns (bool)
    {
        return super.supportsInterface(interfaceId);
    }
}
