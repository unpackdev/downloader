pragma solidity ^0.7.0;

import "./LibSafeMath.sol";
import "./ERC1155Mintable.sol";
import "./MixinOwnable.sol";
import "./POBMinter.sol";

contract POBMinterV2 is Ownable {
  using LibSafeMath for uint256;

  uint256 public tokenType;

  ERC1155Mintable public mintableErc1155;
  POBMinter public pobMinterV1;

  uint256 immutable startingPrice;

  uint256 immutable pricePerMint;

  uint256 immutable flatPriceUpTo;

  address payable public treasury;

  mapping(uint256 => uint256) public tokenIdToTxHash;
  mapping(uint256 => uint256) public txHashToTokenId;
 
  constructor(
    address _pobMinterV1,
    address _mintableErc1155,
    address payable _treasury,
    uint256 _tokenType,
    uint256 _startingPrice,
    uint256 _pricePerMint,
    uint256 _flatPriceUpTo
  ) {
    pobMinterV1 = POBMinter(_pobMinterV1);
    mintableErc1155 = ERC1155Mintable(_mintableErc1155);
    treasury = _treasury;
    startingPrice = _startingPrice;
    pricePerMint = _pricePerMint;
    tokenType = _tokenType;
    flatPriceUpTo = _flatPriceUpTo;
  }

  event UpdatedRegistry(
      uint256 tokenId,
      uint256 txHash
  );

  modifier onlyIfNotMinted(uint256 txHash) {
    require(txHashToTokenId[txHash] == 0, 'txHash already exists');
    require(pobMinterV1.txHashToTokenId(txHash) == 0, 'txHash already exists');
    _;
  }

  modifier onlyValueOverPriceForMint() {
    require(msg.value >= pricingCurve(maxIndex()), 'insufficient funds to pay for mint');
    _;
  }

  function maxIndex() public view returns (uint256) {
    return mintableErc1155.maxIndex(tokenType).safeAdd(mintableErc1155.maxIndex(pobMinterV1.tokenType()));
  }

  function pricingCurve(uint256 _maxIndex) public view returns (uint256) {
    if (_maxIndex <= flatPriceUpTo) {
      return startingPrice;
    }
    return _maxIndex.safeSub(flatPriceUpTo).safeMul(pricePerMint).safeAdd(startingPrice); 
  }

  function setTreasury(address payable _treasury) external onlyOwner() {
    treasury = _treasury;
  }

  function mint(address _dst, uint256 _txHash) public payable onlyIfNotMinted(_txHash) onlyValueOverPriceForMint() {
    uint256 price = pricingCurve(maxIndex());
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