pragma solidity ^0.7.0;

import "./LibSafeMath.sol";
import "./ERC1155Mintable.sol";
import "./MixinOwnable.sol";

contract POBMinter is Ownable {
  using LibSafeMath for uint256;

  uint256 public tokenType;

  ERC1155Mintable public mintableErc1155;

  uint256 immutable startingPrice;

  uint256 immutable pricePerMint;

  // uint256 immutable maxMintingSupply;

  address payable public treasury;

  mapping(uint256 => uint256) public tokenIdToTxHash;
  mapping(uint256 => uint256) public txHashToTokenId;
 
  constructor(
    address _mintableErc1155,
    address payable _treasury,
    uint256 _tokenType,
    uint256 _startingPrice,
    uint256 _pricePerMint
    // uint256 _maxMintingSupply
  ) {
    mintableErc1155 = ERC1155Mintable(_mintableErc1155);
    treasury = _treasury;
    startingPrice = _startingPrice;
    pricePerMint = _pricePerMint;
    // maxMintingSupply = _maxMintingSupply;
    tokenType = _tokenType;
  }

  event UpdatedRegistry(
      uint256 tokenId,
      uint256 txHash
  );

  modifier onlyIfNotMinted(uint256 txHash) {
    require(txHashToTokenId[txHash] == 0, 'txHash already exists');
    _;
  }

  // modifier onlyUnderMaxSupply() {
  //   require(mintableErc1155.maxIndex(tokenType) < maxMintingSupply, 'max supply minted');
  //   _;
  // }

  modifier onlyValueOverPriceForMint() {
    require(msg.value >= mintableErc1155.maxIndex(tokenType).safeMul(pricePerMint).safeAdd(startingPrice), 'insufficient funds to pay for mint');
    _;
  }

  function setTreasury(address payable _treasury) external onlyOwner() {
    treasury = _treasury;
  }

  function mint(address _dst, uint256 _txHash) public payable onlyIfNotMinted(_txHash) onlyValueOverPriceForMint() {
    uint256 price = mintableErc1155.maxIndex(tokenType).safeMul(pricePerMint).safeAdd(startingPrice);
    treasury.transfer(price);
    msg.sender.transfer(msg.value.safeSub(price));
    address[] memory dsts = new address[](1);
    dsts[0] = _dst;
    uint256 index = mintableErc1155.maxIndex(tokenType) + 1;
    uint256 tokenId  = tokenType | index;
    mintableErc1155.mintNonFungible(tokenType, dsts);
    tokenIdToTxHash[tokenId] = _txHash;
    txHashToTokenId[_txHash] = tokenId;
    emit UpdatedRegistry(tokenId, _txHash);
  } 
}