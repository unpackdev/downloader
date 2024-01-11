// SPDX-License-Identifier: MIT
// Creator: https://cojodi.com

pragma solidity ^0.8.0;

import "./IERC721.sol";

import "./MerkleWhitelist.sol";
import "./MerkleStorage.sol";
import "./ERC721MaxSupplyBurnable.sol";
import "./BasicSellOne.sol";

contract BlockAgentsGenesis is
  ERC721MaxSupplyBurnable,
  MerkleWhitelist,
  MerkleStorage,
  BasicSellOne
{
  IERC721 public blockpass;

  address private projectOwner;

  bool public isBurnMint = false;

  address public burnAddress = 0x000000000000000000000000000000000000dEaD;

  uint256 private _publicMintCounter = 0;

  constructor(address projectOwner_, address blockpassAddress_)
    ERC721MaxSupplyBurnable("Block Agents Genesis", "BAG", 250, "TODO")
    MerkleWhitelist(0x19f7ee195f53728ff36c0db27382d1a35ffc92e54fa09290e724d4f8378ca7d5)
    MerkleStorage(0x31d405a9dd4e2dec030f3fe1509a433346ad839c39744608f474df21bd230d47)
    BasicSellOne(0.2 ether)
  {
    projectOwner = projectOwner_;
    blockpass = IERC721(blockpassAddress_);
  }

  function mintWithAlphaBlockpass(
    bytes32[] calldata merkleProof_,
    uint256 alphaBlockpassId_
  ) external {
    require(isBurnMint, "not burn mint");
    require(
      isInStorage(merkleProof_, abi.encodePacked("abp", alphaBlockpassId_)),
      "not an abp"
    );

    blockpass.transferFrom(msg.sender, burnAddress, alphaBlockpassId_);
    _safeMint(msg.sender);
  }

  function mintWithBlockpass(
    bytes32[][] calldata merkleProofs_,
    uint256[] calldata blockpassIds_
  ) external {
    require(isBurnMint, "not burn mint");
    require(merkleProofs_.length == 4 && blockpassIds_.length == 4, "not same length");

    for (uint256 i = 0; i < blockpassIds_.length; ++i) {
      uint256 blockpassId = blockpassIds_[i];
      bytes32[] calldata merkleProof = merkleProofs_[i];
      require(
        isInStorage(merkleProof, abi.encodePacked("bp", blockpassId)),
        "not a bp"
      );

      blockpass.transferFrom(msg.sender, burnAddress, blockpassId);
    }

    _safeMint(msg.sender);
  }

  function toggleBurnMint() external onlyOwner {
    isBurnMint = !isBurnMint;
  }

  function setBlockpass(address blockpassAddr_) external onlyOwner {
    blockpass = IERC721(blockpassAddr_);
  }

  function mintWhitelist(bytes32[] calldata merkleProof_)
    external
    payable
    isWhitelisted(merkleProof_)
    isPaymentOk
  {
    require(!isBurnMint, "is burn mint");
    _safeMint(msg.sender);
  }

  function mintPublic() external payable isPublic isPaymentOk {
    require(!isBurnMint, "is burn mint");
    require(_publicMintCounter < 53, "public mint over");

    _safeMint(msg.sender);
    _publicMintCounter += 1;
  }

  function mintOwner(address receiver_, uint256 amount_) external onlyOwner {
    for (uint256 i = 0; i < amount_; ++i) _safeMint(receiver_);
  }

  function withdraw() external onlyOwner {
    uint256 balance = address(this).balance;
    payable(projectOwner).transfer(balance);
  }
}
