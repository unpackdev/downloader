// SPDX-License-Identifier: MIT LICENSE

// ⠄⠄⠄⢰⣧⣼⣯⠄⣸⣠⣶⣶⣦⣾⠄⠄⠄⠄⡀⠄⢀⣿⣿⠄⠄⠄⢸⡇⠄⠄
//  ⠄⠄⠄⣾⣿⠿⠿⠶⠿⢿⣿⣿⣿⣿⣦⣤⣄⢀⡅⢠⣾⣛⡉⠄⠄⠄⠸⢀⣿⠄
// ⠄⠄⢀⡋⣡⣴⣶⣶⡀⠄⠄⠙⢿⣿⣿⣿⣿⣿⣴⣿⣿⣿⢃⣤⣄⣀⣥⣿⣿⠄
// ⠄⠄⢸⣇⠻⣿⣿⣿⣧⣀⢀⣠⡌⢻⣿⣿⣿⣿⣿⣿⣿⣿⣿⠿⠿⠿⣿⣿⣿⠄
// ⠄⢀⢸⣿⣷⣤⣤⣤⣬⣙⣛⢿⣿⣿⣿⣿⣿⣿⡿⣿⣿⡍⠄⠄⢀⣤⣄⠉⠋⣰
// ⠄⣼⣖⣿⣿⣿⣿⣿⣿⣿⣿⣿⢿⣿⣿⣿⣿⣿⢇⣿⣿⡷⠶⠶⢿⣿⣿⠇⢀⣤
// ⠘⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣽⣿⣿⣿⡇⣿⣿⣿⣿⣿⣿⣷⣶⣥⣴⣿⡗
// ⢀⠈⢿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⡟⠄
// ⢸⣿⣦⣌⣛⣻⣿⣿⣧⠙⠛⠛⡭⠅⠒⠦⠭⣭⡻⣿⣿⣿⣿⣿⣿⣿⣿⡿⠃⠄
// ⠘⣿⣿⣿⣿⣿⣿⣿⣿⡆⠄⠄⠄⠄⠄⠄⠄⠄⠹⠈⢋⣽⣿⣿⣿⣿⣵⣾⠃⠄
// ⠄⠘⣿⣿⣿⣿⣿⣿⣿⣿⠄⣴⣿⣶⣄⠄⣴⣶⠄⢀⣾⣿⣿⣿⣿⣿⣿⠃⠄⠄
// ⠄⠄⠈⠻⣿⣿⣿⣿⣿⣿⡄⢻⣿⣿⣿⠄⣿⣿⡀⣾⣿⣿⣿⣿⣛⠛⠁⠄⠄⠄
// ⠄⠄⠄⠄⠈⠛⢿⣿⣿⣿⠁⠞⢿⣿⣿⡄⢿⣿⡇⣸⣿⣿⠿⠛⠁⠄⠄⠄⠄⠄
// ⠄⠄⠄⠄⠄⠄⠄⠉⠻⣿⣿⣾⣦⡙⠻⣷⣾⣿⠃⠿⠋⠁⠄⠄⠄⠄⠄⢀⣠⣴
// ⣿⣿⣿⣶⣶⣮⣥⣒⠲⢮⣝⡿⣿⣿⡆⣿⡿⠃⠄⠄⠄⠄⠄⠄⠄⣠⣴⣿⣿⣿


pragma solidity ^0.8.1;

import "./console.sol";

import "./ERC721Enumerable.sol";
import "./MerkleProof.sol";
import "./Ownable.sol";

contract Waifu is ERC721Enumerable, Ownable{
  using Strings for uint256;

  string public baseURI;
  string public baseExtension = ".json";
  uint256 public maxSupply = 3000;
  uint256 public mintPrice = 0.04 ether;
  bool public mintActive = true;
  bool public whitelistActive = false;

  struct Claim {
      bool claimedAll;
      uint256 leftToClaim;
  }

  mapping(bytes32 => Claim) public claimed;

  // The root hash of the Merkle tree generated in Javascript
  bytes32 public merkleRoot;
  
  event NFTMinted(address indexed owner, uint256 tokenId, uint256 timestamp);
  event Claimed(address account, uint256 amount);

  constructor(
    string memory _name,
    string memory _symbol,
    string memory _initBaseURI,
    bytes32 merkleRoot_
  ) ERC721(_name, _symbol) {
    setBaseURI(_initBaseURI);
    merkleRoot = merkleRoot_;
  }

  // internal
  function _baseURI() internal view virtual override returns (string memory) {
    return baseURI;
  }

  function leftToClaim(bytes32[] memory proof, uint256 amount)
    public
    view
    returns (uint256)
  {
    bytes32 proofHash = keccak256(abi.encodePacked(proof));
    if (claimed[proofHash].claimedAll) return 0;
    if (claimed[proofHash].leftToClaim == 0) {
        return amount;
    } else {
        return claimed[proofHash].leftToClaim;
    }
  }

  function mint(uint256 amount) public payable {
    require(mintActive == true, "minting is not active currently");
    require(amount <= 10, "can't mint more than 10 waifus per transaction");
    require(msg.value >= mintPrice * amount, "you didn't send enough ETH to cover the minting costs"); 

    for (uint256 i = 0; i < amount; i++) {
      uint256 supply = totalSupply();
      require(supply <= maxSupply, "all waifus have already been minted");

      _safeMint(msg.sender, supply);

      emit NFTMinted(msg.sender, supply, block.timestamp);
    }
  }

  function whitelistMint(bytes32[] memory proof, uint256 amount) public {
    require(whitelistActive == true, "minting is not active currently");

    uint256 supply = totalSupply();
    require(supply + 1 < maxSupply, "all waifus have already been minted");
    
    bytes32 proofHash = keccak256(abi.encodePacked(proof));

    require(
        !claimed[proofHash].claimedAll,
        "waifu already claimed"
    );
    if (claimed[proofHash].leftToClaim == 0) {
        claimed[proofHash].leftToClaim = amount;
    }

    bytes32 leaf = keccak256(abi.encodePacked(msg.sender, amount));

    require(
        MerkleProof.verify(proof, merkleRoot, leaf),
        "MerkleAirdrop: proof invalid"
    );

    // execute mint 
    _safeMint(msg.sender, supply);

    emit NFTMinted(msg.sender, supply, block.timestamp);

    // update claim records
    claimed[proofHash].leftToClaim -= 1;

    if (claimed[proofHash].leftToClaim == 0) {
        claimed[proofHash].claimedAll = true;
    }

    emit Claimed(msg.sender, amount);
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

  //only owner
  function setBaseURI(string memory _newBaseURI) public onlyOwner {
    baseURI = _newBaseURI;
  }

  function setBaseExtension(string memory _newBaseExtension) public onlyOwner {
    baseExtension = _newBaseExtension;
  }

  function setMerkleRoot(bytes32 _merkleRoot) public onlyOwner {
    merkleRoot = _merkleRoot;
  }

  function activateWhitelistMint(bool _state) public onlyOwner {
    whitelistActive = _state;
  }
  
  function activateMint(bool _state) public onlyOwner {
    mintActive = _state;
  }
 
  function withdraw() public payable onlyOwner {
    (bool success, ) = payable(msg.sender).call{value: address(this).balance}("");
    require(success);
  }
}