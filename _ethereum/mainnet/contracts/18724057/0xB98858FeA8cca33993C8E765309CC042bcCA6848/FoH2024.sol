// SPDX-License-Identifier: MIT
pragma solidity ^0.8.16;
import "./ERC721.sol";
import "./IERC721Enumerable.sol";
import "./ERC721URIStorage.sol";
import "./Ownable.sol";
import "./Counters.sol";
contract HEK is ERC721, ERC721URIStorage, Ownable {
    using Counters for Counters.Counter;
    Counters.Counter private _tokenIdCounter;
    string private _baseTokenURI;
    address payable public beneficiary;
    event TokenMinted(address indexed owner, uint256 indexed tokenId);
    constructor(string memory baseTokenURI_, address initialOwner) ERC721("Friends of HEK", "HEK") Ownable(initialOwner) {
        _baseTokenURI = baseTokenURI_;
        beneficiary = payable(0x23106570beE3c2CD6C7981C102d2bb84E98e0d53);
    }
     function contractURI() public pure returns (string memory) {
        string memory json = '{"name": "Friends of HEK","description": "Friends of HEK represents the home of all yearly membership tokens which were collectively created by the Friends of HEK community.", "image": "ipfs://QmTAQQzGFCuVcHr4J1fSVniAysVuWqNsYJ6EwcQPSjY7os/"}';
        return string(abi.encodePacked("data:application/json;utf8,", json));
    }
    function setBaseTokenURI(string memory baseTokenURI_) public onlyOwner {
        _baseTokenURI = baseTokenURI_;
        if (_tokenIdCounter.current() > 0) {  // only emit event if any tokens have been minted
            emit BatchMetadataUpdate(1, _tokenIdCounter.current());
        }
    }
    function _baseURI() internal view override returns (string memory) {
        return _baseTokenURI;
    }
    uint256 public mintPrice = 0.05 ether;
    function safeMint(address to) public payable {
        require(balanceOf(to) == 0 || to == beneficiary, "Address already owns a token");
        if (msg.sender != beneficiary) {
            require(msg.value >= mintPrice, "Not enough Ether provided.");
        }
        _tokenIdCounter.increment();
        uint256 newTokenId = _tokenIdCounter.current();
        _safeMint(to, newTokenId);
        // Forward the funds
        if (msg.value > 0) {
            beneficiary.transfer(msg.value);
        }
        emit TokenMinted(to, newTokenId);
    }
    // HEK's mint function to mint multiple tokens at once
    function mintMultiple(address to, uint256 numTokens) public {
        require(msg.sender == beneficiary, "Only beneficiary can mint multiple tokens.");
        for(uint256 i = 0; i < numTokens; i++) {
            _tokenIdCounter.increment();
            uint256 newTokenId = _tokenIdCounter.current();
            _mint(to, newTokenId);
        }
    }
    function tokenURI(uint256 tokenId) public view virtual override(ERC721, ERC721URIStorage) returns (string memory) {
        _ownerOf(tokenId) != address(0);
        return _baseTokenURI;
    }
    function supportsInterface(bytes4 interfaceId)
        public
        view
        override(ERC721, ERC721URIStorage)
        returns (bool)
    {
        return super.supportsInterface(interfaceId);
    }
}