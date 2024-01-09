//
//   ██████╗██████╗ ██╗██████╗ ██████╗  ██████╗
//  ██╔════╝██╔══██╗██║██╔══██╗██╔══██╗██╔═══██╗
//  ██║     ██████╔╝██║██████╔╝██████╔╝██║   ██║
//  ██║     ██╔══██╗██║██╔══██╗██╔══██╗██║   ██║
//  ╚██████╗██║  ██║██║██████╔╝██████╔╝╚██████╔╝
//   ╚═════╝╚═╝  ╚═╝╚═╝╚═════╝ ╚═════╝  ╚═════╝
//
//
// ╭━━━┳╮╱╱╱╱╱╭━╮╭━┳╮╱╱╱╭━╮╭━╮╱╱╱╭╮╱╭━━━╮╭╮╱╱╱╱╱╭╮
// ┃╭━╮┃┃╱╱╱╱╱┃╭╯┃╭┫┃╱╱╱┃┃╰╯┃┃╱╱╭╯╰╮┃╭━╮┣╯╰╮╱╱╱╱┃┃
// ┃╰━━┫╰━┳╮╭┳╯╰┳╯╰┫┃╭━━┫╭╮╭╮┣┳━╋╮╭╯┃╰━━╋╮╭╋╮╭┳━╯┣┳━━┳━━╮
// ╰━━╮┃╭╮┃┃┃┣╮╭┻╮╭┫┃┃┃━┫┃┃┃┃┣┫╭╮┫┃╱╰━━╮┃┃┃┃┃┃┃╭╮┣┫╭╮┃━━┫
// ┃╰━╯┃┃┃┃╰╯┃┃┃╱┃┃┃╰┫┃━┫┃┃┃┃┃┃┃┃┃╰╮┃╰━╯┃┃╰┫╰╯┃╰╯┃┃╰╯┣━━┃
// ╰━━━┻╯╰┻━━╯╰╯╱╰╯╰━┻━━┻╯╰╯╰┻┻╯╰┻━╯╰━━━╯╰━┻━━┻━━┻┻━━┻━━╯
//                                      @shufflemint
// SPDX-License-Identifier: MIT


pragma solidity ^0.8.7;

import "./ERC721.sol";
import "./ERC721Burnable.sol";
import "./Ownable.sol";
import "./Counters.sol";
import "./MerkleProof.sol";

contract Cribbo is ERC721, ERC721Burnable, Ownable {
  using Counters for Counters.Counter;
  Counters.Counter private _tokenIds;
  Counters.Counter private _circulatingSupply;

  string public baseURI;
  string public baseURI_EXT;
  bool public publicActive = false;
  bool public presaleActive = false;
  bool public teamClaimed = false;
  bool public burnActive = false;
  uint256 public cost = 0.04 ether;

  // Constants
  uint256 public constant maxSupply = 4050;
  uint256 public constant maxMintAmount = 10;
  uint256 public constant wlAllowance = 4;
  uint256 public constant teamClaimAmount = 50;

  // Set merkleRoot for whitelist
  bytes32 public whitelistMerkleRoot;

  // mapping to track whitelist that already claimed
  mapping(address => uint) public addressClaimed;

  // Payment Addresses
  address constant partner = 0x31C196751B47503B2B0929772E0A385324020aE6;
  address constant shufflemint = 0xC79108A7151814A77e1916E61e0d88D5EA935c84;

  constructor(
    string memory _name,
    string memory _symbol,
    string memory _initBaseURI
  ) ERC721(_name, _symbol) { setBaseURI(_initBaseURI);
    _tokenIds.increment();
  }

  // internal
  function _baseURI() internal view virtual override returns (string memory) {
    return baseURI;
  }

  function _mintedSupply() internal view returns (uint256) {
    return _tokenIds.current() - 1;
  }

  // presale
  function whitelistMint(uint256 _mintAmount, bytes32[] calldata _merkleProof) public payable {
    require(presaleActive, "Sale has not started yet.");
    require(_mintAmount > 0, "Quantity cannot be zero");
    require(addressClaimed[_msgSender()] + _mintAmount <= wlAllowance, "Exceeds whitelist supply");
    require(_mintedSupply() + _mintAmount <= maxSupply, "Quantity requested exceeds max supply");
    require(msg.value >= cost * _mintAmount, "Ether value sent is below the price");

    // Verify merkle proof
    bytes32 leaf = keccak256(abi.encodePacked(msg.sender));
    require(MerkleProof.verify(_merkleProof, whitelistMerkleRoot, leaf), "Invalid proof");

    // Mark address as having claimed
    addressClaimed[_msgSender()] += _mintAmount;

    for (uint256 i = 1; i <= _mintAmount; i++) {
      _mint(msg.sender, _tokenIds.current());

      // increment id counter
      _tokenIds.increment();
      _circulatingSupply.increment();
    }
  }

  function publicMint(uint256 _mintAmount) public payable {
    require(publicActive, "Sale has not started yet.");
    require(_mintAmount > 0, "Quantity cannot be zero");
    require(_mintAmount <= maxMintAmount, "Exceeds 5, the max qty per mint");
    require(_mintedSupply() + _mintAmount <= maxSupply, "Quantity requested exceeds max supply.");
    require(msg.value >= cost * _mintAmount, "Ether value sent is below the price");

    for (uint256 i = 1; i <= _mintAmount; i++) {
      _mint(msg.sender, _tokenIds.current());

      // increment id counter
      _tokenIds.increment();
      _circulatingSupply.increment();
    }
  }

  function teamClaim() public onlyOwner {
    require(_mintedSupply() + teamClaimAmount <= maxSupply, "Quantity requested exceeds max supply.");
    require(!teamClaimed, "Team has claimed");
    for (uint256 i = 1; i <= teamClaimAmount; i++) {
      _mint(msg.sender, _tokenIds.current());

    _tokenIds.increment();
    _circulatingSupply.increment();
    }
    teamClaimed = true;
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
      "ERC721Metadata: URI query for nonexistent token"
    );

    string memory currentBaseURI = _baseURI();
    return bytes(currentBaseURI).length > 0
        ? string(abi.encodePacked(currentBaseURI, Strings.toString(tokenId), baseURI_EXT))
        : "";
  }

  function setWhitelistMerkleRoot(bytes32 _whitelistMerkleRoot) external onlyOwner {
      whitelistMerkleRoot = _whitelistMerkleRoot;
  }

  function setCost(uint256 _newCost) public onlyOwner {
    cost = _newCost;
  }

  function setBaseURI(string memory _newBaseURI) public onlyOwner {
    baseURI = _newBaseURI;
  }

  function setBaseExtension(string memory _newBaseExtension) public onlyOwner {
    baseURI_EXT = _newBaseExtension;
  }

  function enablePresale(bool _state) public onlyOwner {
    presaleActive = _state;
  }

  function enablePublic(bool _state) public onlyOwner {
    publicActive = _state;
  }

  function enableBurn(bool _state) public onlyOwner {
    burnActive = _state;
  }

  function totalSupply() public view returns (uint256) {
    return _circulatingSupply.current();
  }

  function burn(uint256 tokenId) public override {
    require(burnActive, "Token burning not enabled yet.");
    ERC721Burnable.burn(tokenId);
    _circulatingSupply.decrement();
  }

  function withdraw() public payable onlyOwner {
    // Shufflemint 4.8%
    (bool sm, ) = payable(shufflemint).call{value: address(this).balance * 48 / 1000}("");
    require(sm);

    // Partner 95.2%
    (bool os, ) = payable(partner).call{value: address(this).balance}("");
    require(os);
  }
}
