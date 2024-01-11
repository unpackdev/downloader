// SPDX-License-Identifier: MIT

pragma solidity ^0.8.9;

import "./ERC721Sequential.sol";
import "./Ownable.sol";
import "./SafeMath.sol";
import "./Strings.sol";
import "./ReentrancyGuard.sol";

import "./ContentMixin.sol";
import "./NativeMetaTransaction.sol";


contract Mooseverse is ERC721Sequential, Ownable, ReentrancyGuard {
    using Strings for uint256;

    uint256 public constant SUPPLY = 4444;
    uint256 public constant MAX_PER_PURCHASE = 50;
    uint256 public burnAndMintAmt = 2;
    uint256 public price = 40000000000000000;
    uint256 public burnMintPrice = 20000000000000000;
    
    string public provenanceHash;
    string public _contractURI = "https://api.mooseverse.io/api/contract-metadata.json";
    string public uriSuffix = '.json';
    string public baseURI = "https://api.mooseverse.io/api/";
    string public hiddenMetadataUri = "https://api.mooseverse.io/api/hidden.json";

    bool public revealed = false;
    bool public mintPaused = true;
    bool public burnPaused = false;

    constructor() ERC721Sequential("Mooseverse", "MOOSEVERSE") {
    }

    function mintMoose(uint256 mooseToBuy) public payable {
        uint256 totalMinted = totalMinted();

        require(!mintPaused, "Sale is not active!");
        require(mooseToBuy > 0 && mooseToBuy < MAX_PER_PURCHASE + 1, "Improper amount of moose to purchase");
        require(totalMinted + mooseToBuy < SUPPLY + 1, "Not enough moose left for sale");
        require(msg.value >= price * mooseToBuy, "Insufficient funds sent.");

        for(uint256 i = 0; i < mooseToBuy; i++){
            _safeMint(msg.sender);
        }

    }

    function airdropMoose(uint256 mooseToBuy, address recipient) public payable onlyOwner {
        uint256 totalMinted = totalMinted();

        require(mooseToBuy > 0 && mooseToBuy < MAX_PER_PURCHASE + 1, "Improper amount of moose to airdrop");
        require(totalMinted + mooseToBuy < SUPPLY + 1, "Not enough moose left for sale to airdrop");

        for(uint256 i = 0; i < mooseToBuy; i++){
            _safeMint(recipient);
        }

    }

    function burnAndMint(uint256 tokenId) public payable {
        uint256 totalMinted = totalMinted();
        address owner = ERC721Sequential.ownerOf(tokenId);

        require(!burnPaused, "Burning is not active!");
        require(totalMinted + burnAndMintAmt < SUPPLY + 1, "Not enough moose left for sale");
        require(msg.value >= burnMintPrice, "Insufficient funds sent.");
        require(msg.sender == owner, "You must own the nft in order to burn.");

        _burn(tokenId);

        for(uint256 i = 0; i < burnAndMintAmt; i++){
            _safeMint(msg.sender);
        }

    }

    function getPrice() public view returns (uint256){
        return price;
    }

    function tokenURI(uint256 _tokenId) public view virtual override returns (string memory) {
      require(_exists(_tokenId), 'ERC721Metadata: URI query for nonexistent token');

      if (revealed == false) {
         return hiddenMetadataUri;
      }

      string memory currentBaseURI = _baseURI();
      return bytes(currentBaseURI).length > 0
          ? string(abi.encodePacked(currentBaseURI, _tokenId.toString(), uriSuffix))
          : '';
    }

    function baseTokenURI() public view returns (string memory) {
        return _baseURI();
    }

    function _baseURI() internal view virtual override returns (string memory) {
        return baseURI;
    }

    function contractURI() public view returns (string memory) {
        return _contractURI;
    }

    function setMintPaused(bool _state) public onlyOwner {
        mintPaused = _state;
    }

    function setBurnPaused(bool _state) public onlyOwner {
        burnPaused = _state;
    }

    function setBaseUri(string memory _baseUri) public onlyOwner {
        baseURI = _baseUri;
    }

    function setUriSuffix(string memory _uriSuffix) public onlyOwner {
        uriSuffix = _uriSuffix;
    }

    function setPrice(uint256 _newPrice) public onlyOwner() {
        price = _newPrice;
    }

    function setContractURI(string memory newContractURI) public onlyOwner() {
        _contractURI = newContractURI;
    }

    function setBurnMintPrice(uint256 _newPrice) public onlyOwner() {
        burnMintPrice = _newPrice;
    }

    function setBurnMintAmount(uint256 _newAmt) public onlyOwner() {
        burnAndMintAmt = _newAmt;
    }

    function setProvenanceHash(string memory _provenanceHash) public onlyOwner
    {
        provenanceHash = _provenanceHash;
    }

    function setHiddenMetadataUri(string memory _hiddenMetadataUri) public onlyOwner {
        hiddenMetadataUri = _hiddenMetadataUri;
    }

    function setRevealed(bool _state) public onlyOwner {
        revealed = _state;
    }

    function withdraw() public onlyOwner nonReentrant {
        (bool os, ) = payable(owner()).call{value: address(this).balance}('');
        require(os);
    }

}