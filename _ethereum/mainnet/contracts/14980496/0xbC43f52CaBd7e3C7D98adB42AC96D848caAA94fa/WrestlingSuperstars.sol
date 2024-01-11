// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "./Ownable.sol";
import "./ERC721A.sol";
import "./MerkleProof.sol";

contract WrestlingSuperstars is Ownable, ERC721A {
  using Strings for uint256;
  
  // Contract Constants
  uint128 constant public maxSupply = 6666;
  uint128 public maxPerWallet = 4;
  uint128 public teamClaimed;

  // Timestamps
  uint128 public allowlistStartTime;
  uint128 public allowlistTimeLock;

  // Contract Vars
  string public baseURI;
  string public baseExtension = '.json';

  bytes32 public allowlistMerkleRoot;
  mapping(address => uint128) public addressClaimed;


  constructor(uint128 _allowlistStartTime) ERC721A("WrestlingSuperstars", "WSS") {
    allowlistStartTime = _allowlistStartTime;
    allowlistTimeLock = allowlistStartTime + 2 hours;
  }
  

  function allowlistMint(uint128 amount, bytes32[] calldata _merkleProof) public {
    require(addressClaimed[_msgSender()] + amount <= maxPerWallet, "Exceeds wallet mint amt.");
    require(totalSupply() + amount <= maxSupply, "Quantity requested exceeds max supply.");
    require(block.timestamp >= allowlistStartTime, "Allowlist has not started yet.");
    require(block.timestamp < allowlistTimeLock, "Allowlist has ended.");

    // Verify merkle proof
    bytes32 leaf = keccak256(abi.encodePacked(msg.sender));
    require(MerkleProof.verify(_merkleProof, allowlistMerkleRoot, leaf), "Invalid proof.");
    
    _mint(msg.sender, amount);
    addressClaimed[_msgSender()] += amount;
  }

  function mint(uint128 amount) external {
    require(addressClaimed[_msgSender()] + amount <= maxPerWallet, "Exceeds wallet mint amt.");
    require(totalSupply() + amount <= maxSupply, "Quantity requested exceeds max supply.");
    require(tx.origin == msg.sender, "The caller is another contract.");
    require(block.timestamp > allowlistTimeLock, "Public has not started yet!");

    _mint(msg.sender, amount);
    addressClaimed[_msgSender()] += amount;
  }

  function teamClaim(uint128 amount) external onlyOwner{
    require(teamClaimed + amount <= 30, "Team has exceeded claim amount!");
    _mint(msg.sender, amount);
    teamClaimed += amount;
  }

  function _baseURI() internal view virtual override returns (string memory) {
    return baseURI;
  }

  function setBaseURI(string calldata newBaseURI) external onlyOwner {
    baseURI = newBaseURI;
  }

  function setAllowlistMerkleRoot(bytes32 _allowlistMerkleRoot) external onlyOwner {
      allowlistMerkleRoot = _allowlistMerkleRoot;
  }

  function _startTokenId() internal view virtual override returns (uint256) {
    return 1;
  }

  function allowedMintAmount(address _addr) external view returns (uint128) {
    return maxPerWallet - addressClaimed[_addr];
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
        ? string(abi.encodePacked(currentBaseURI, tokenId.toString(), baseExtension))
        : "";
  }

}