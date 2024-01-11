//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.0;

import "./PaymentSplitter.sol";
import "./MerkleProof.sol";
import "./Ownable.sol";

import "./IChocoMintERC721.sol";

contract ChocoMintWhitelist is Ownable {
  using MerkleProof for bytes32[];
  bytes32 public saleMerkleRoot;

  IChocoMintERC721 public chocomintERC721;
  uint256 public supplied;
  uint256 public mintPrice;
  uint256 public supplyLimit;
  uint256 public presaleStartTimestamp;
  uint256 public publicSaleStartTimestamp;
  address private withdrawer;

  constructor(
    address _chocomintERC721Address,
    uint256 _mintPrice,
    uint256 _supplyLimit,
    uint256 _saleStartTimestamp,
    uint256 _publicSaleStartTimestamp,
    address _withdrawer
  ) {
    chocomintERC721 = IChocoMintERC721(_chocomintERC721Address);
    mintPrice = _mintPrice;
    supplyLimit = _supplyLimit;
    presaleStartTimestamp = _saleStartTimestamp;
    publicSaleStartTimestamp = _publicSaleStartTimestamp;
    withdrawer = _withdrawer;
  }

  function setSaleMerkleRoot(bytes32 _merkleRoot) public onlyOwner {
    saleMerkleRoot = _merkleRoot;
  }

  function sale(bytes32[] calldata _proof, uint256 tokenId) public payable {
    require(block.timestamp >= presaleStartTimestamp, "ChocoMintWhitelist: sale has not started");
    require(msg.value == mintPrice, "ChocoMintWhitelist: msg value must be same as mint price");
    require(supplied < supplyLimit, "ChocoMintWhitelist: sale has already ended");
    require(tokenId >= 1 && tokenId <= supplyLimit, "ChocoMintWhitelist: invalid tokenId");

    if (block.timestamp < publicSaleStartTimestamp) {
      require(reviewSaleProof(msg.sender, _proof), "ChocoMintWhitelist:Proof does not match data");
    }

    SecurityLib.SecurityData memory validSecurityData = SecurityLib.SecurityData(0, 9999999999, 0);
    MintERC721Lib.MintERC721Data memory mintERC721Data = MintERC721Lib.MintERC721Data(
      validSecurityData,
      address(this),
      msg.sender,
      tokenId,
      ""
    );
    bytes32 root_ = MintERC721Lib.hashStruct(mintERC721Data);
    SignatureLib.SignatureData memory signatureData = SignatureLib.SignatureData(root_, new bytes32[](0), "");
    chocomintERC721.mint(mintERC721Data, signatureData);
    supplied++;
  }

  function setWithdrawer(address _withdrawer) public onlyOwner {
    withdrawer = _withdrawer;
  }

  function withdraw() public {
    require(msg.sender == withdrawer, "ChocoMintWhitelist: only withdrawer can withdraw");
    payable(msg.sender).transfer(address(this).balance);
  }

  function reviewSaleProof(address _sender, bytes32[] calldata _proof) public view returns (bool) {
    return MerkleProof.verify(_proof, saleMerkleRoot, keccak256(abi.encodePacked(_sender)));
  }
}
