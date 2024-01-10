// SPDX-License-Identifier: MIT
pragma solidity 0.8.6;

import "./ERC721.sol";
import "./Counters.sol";
import "./Ownable.sol";
import "./ERC721Enumerable.sol";
import "./MerkleProof.sol";

contract IntergalacticCockroaches is ERC721, Ownable {
using Counters for Counters.Counter;
Counters.Counter private _tokenIds;

uint256 private _maxSupply = 9999;
uint256 private PRESALE_RESERVE = 9000;

string public _provenanceHash;
string public _baseURL;
bool public _presaleStarted = false;
bool public _publicSaleStarted = false;
uint public MAX_NFT_PURCHASE_PRESALE = 5;
uint public MAX_NFT_PURCHASE = 5;
uint256 public mintPrice = 0.1 ether;
uint256 public presalePrice = 0.08 ether;
bytes32 public rootHash;
mapping(address => uint256) public claimed;

constructor() ERC721("CockroachPunks", "ICC") {}

function mint(uint256 count) external payable {
require(_publicSaleStarted, "Sales not active at the moment");
require(_tokenIds.current() < _maxSupply, "Can not mint more than max supply");
require(_tokenIds.current() + count <= _maxSupply, "Can not mint more than max supply");
require(count > 0 && count <= MAX_NFT_PURCHASE, "You can mint between 1 and 5 at once");
require(msg.value >= count * mintPrice, "Insufficient payment");

for (uint256 i = 0; i < count; i++) {
_mint(msg.sender, _tokenIds.current());
_tokenIds.increment();
}
}

function setPrice(uint256 _price) public onlyOwner {
mintPrice = _price;
}

function setPresalePrice(uint256 _price) public onlyOwner {
presalePrice = _price;
}

function setPresaleReserve(uint256 _count) public onlyOwner {
PRESALE_RESERVE = _count;
}

function setMaxNFTPresale(uint256 count) public onlyOwner {
MAX_NFT_PURCHASE_PRESALE = count;
}

function setMaxNFTPurchase(uint256 count) public onlyOwner {
MAX_NFT_PURCHASE = count;
}

function setProvenanceHash(string memory provenanceHash) public onlyOwner {
_provenanceHash = provenanceHash;
}

function setBaseURL(string memory baseURI) public onlyOwner {
_baseURL = baseURI;
}

function _baseURI() internal view override returns (string memory) {
return _baseURL;
}

function maxSupply() public view returns (uint256) {
return _maxSupply;
}

function totalSupply() public view returns (uint256) {
return _tokenIds.current();
}

function togglePresale () public onlyOwner {
_presaleStarted = !_presaleStarted;
}

function togglePublicSale () public onlyOwner {
_publicSaleStarted = !_publicSaleStarted;
}

function mintPresale(uint256 count, bytes32[] calldata _proof) public payable {
require(_presaleStarted, "Presale is not active at the moment");
require(!_publicSaleStarted, "Public Sale Is Live");
bytes32 leaf = keccak256(abi.encodePacked((msg.sender)));
require(MerkleProof.verify(_proof, rootHash, leaf), "Address not in whitelist");

require(count > 0 , "You can only mint more than 1 token.");
require(msg.value >= count * presalePrice, "Insufficient payment");
require(claimed[msg.sender] + count <= MAX_NFT_PURCHASE_PRESALE, "Exceeds Presale Limit");
for (uint i = 0; i < count; i++) {
_mint(msg.sender, _tokenIds.current());
_tokenIds.increment();
}
claimed[msg.sender] += count;
}

function reserve(uint256 count) public onlyOwner {
require(_tokenIds.current() < _maxSupply, "Can not mint more than max supply");
require(count > 0 , "You can one reserve more than one token");
for (uint256 i = 0; i < count; i++) {
_mint(owner(), _tokenIds.current());
_tokenIds.increment();
}
}

function setRootHash(bytes32 hash) external onlyOwner {
rootHash = hash;
}

function withdraw() external onlyOwner {
uint balance = address(this).balance;
payable(owner()).transfer(balance);
}
}