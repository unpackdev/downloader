// SPDX-License-Identifier: MIT
pragma solidity ^0.8.10;

import "./ERC721A.sol";
import "./Ownable.sol";
import "./MerkleProof.sol";

contract HuxlxyNFT is ERC721A, Ownable {
  string private baseURI;

  bytes32 public immutable merkleRoot;
  uint256 private immutable airdropStart;
  mapping(address => bool) private claimed;

  constructor(bytes32 merkleRoot_) ERC721A("Huxlxy", "HUXLXY") {
    merkleRoot = merkleRoot_;
    airdropStart = block.timestamp;
  }

  function isClaimed(address user) public view returns (bool) {
    return claimed[user];
  }

  function mint(
    address account,
    uint256 amount,
    bytes32[] calldata merkleProof
  ) external {
    require(!isClaimed(account), "Airdrop already claimed.");
    require(totalSupply() + amount <= 10000, "Mint limit reached.");
    bytes32 node = keccak256(abi.encodePacked(account, amount));

    require(
      MerkleProof.verify(merkleProof, merkleRoot, node),
      "Invalid proof."
    );

    claimed[account] = true;

    _safeMint(account, amount);
  }

  function setBaseURI(string calldata baseURI_) external onlyOwner {
    baseURI = baseURI_;
  }

  function sweep() external onlyOwner {
    require(block.timestamp > airdropStart + 30 days, "Airdrop period has not ended.");
    _safeMint(msg.sender, 10000 - totalSupply());
  }

  function _baseURI() internal view override returns (string memory) {
    return baseURI;
  }
}