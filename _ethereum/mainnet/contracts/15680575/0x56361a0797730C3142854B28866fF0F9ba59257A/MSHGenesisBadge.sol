// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

import "./ERC721.sol";
import "./Ownable.sol";
import "./Counters.sol";
import "./MerkleProof.sol";

contract MSHGenesisBadge is ERC721, Ownable {
  using Strings for uint256;
  using Counters for Counters.Counter;
  Counters.Counter private _nextTokenId;

  string public baseURI;

  uint256 public price = 0.09 ether;
  uint256 public constant maxSupply = 500;
  uint256 public constant mintPerAddressLimit = 5;
  uint256 public constant ownerMintLimit = 500;

  bool public mintActive = false;
  bool public presaleMintActive = false;

  bytes32 public merkleRoot;

  mapping(address => uint256) public addressMintedBalance;

  constructor() ERC721("MSH GENESIS BADGE", "MGB") {
    setBaseURI("ipfs://QmSFZvkSDGHQXFcdmSVgqK4oEFSZwLVrgEEuJGeMLhyryD/");
    _nextTokenId.increment();
  }

  function presaleMint(bytes32[] calldata _merkleProof, uint256 _mintAmount) public payable {
    require(presaleMintActive, "the presale Mint is paused");
    require(totalSupply() + _mintAmount <= maxSupply, "all NFTs are minted!");

    bytes32 leaf = keccak256(abi.encodePacked(msg.sender));
    require(MerkleProof.verify(_merkleProof, merkleRoot, leaf), "you're not on the whitelist.");
    require(addressMintedBalance[msg.sender] + _mintAmount <= mintPerAddressLimit, "max NFTs per address exceeded");
    require(msg.value == price * _mintAmount, "insufficient funds");

    addressMintedBalance[msg.sender] += _mintAmount;
    for (uint256 i = 0; i < _mintAmount; i++) {
      _safeMint(msg.sender, _nextTokenId.current());
      _nextTokenId.increment();
    }
  }
  
  function mint(uint256 _mintAmount) public payable {
    require(mintActive, "the public mint is paused");
    require(totalSupply() + _mintAmount <= maxSupply, "all NFTs are minted!");
    require(addressMintedBalance[msg.sender] + _mintAmount <= mintPerAddressLimit, "max NFTs per address exceeded");
    require(msg.value == price * _mintAmount, "insufficient funds");
    require(msg.sender == tx.origin, "caller should not be a contract.");

    addressMintedBalance[msg.sender] += _mintAmount;
    for (uint256 i = 0; i < _mintAmount; i++) {
      _safeMint(msg.sender, _nextTokenId.current());
      _nextTokenId.increment();      
    }
  }

  function ownerMint(address _to, uint256 _mintAmount) public onlyOwner {
    require(totalSupply() + _mintAmount <= maxSupply, "all NFTs are minted!");
    require(addressMintedBalance[msg.sender] + _mintAmount <= ownerMintLimit, "max NFTs for team exceeded");

    addressMintedBalance[msg.sender] += _mintAmount;
    for (uint256 i = 0; i < _mintAmount; i++) {
      _safeMint(_to, _nextTokenId.current());
      _nextTokenId.increment();
    }
  }

  function totalSupply() public view returns (uint256) {
      return _nextTokenId.current() - 1;
  }

  function setPrice(uint256 _newPrice) public onlyOwner {
    price = _newPrice;
  }

  function setMerkleRoot(bytes32 _newMerkleRoot) public onlyOwner {
    merkleRoot = _newMerkleRoot;
  }

  function togglepresaleMint() public onlyOwner {
    presaleMintActive = !presaleMintActive;
  }

  function toggleMint() public onlyOwner {
    mintActive = !mintActive;
  }
 
  function setBaseURI(string memory _newBaseURI) public onlyOwner {
    baseURI = _newBaseURI;
  }

  function _baseURI() internal view virtual override returns (string memory) {
    return baseURI;
  }

  function withdrawBalance() public onlyOwner {
    payable(msg.sender).transfer(address(this).balance);
  }
}