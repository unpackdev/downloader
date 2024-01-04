pragma solidity ^0.7.0;

import "./LibSafeMath.sol";
import "./ERC1155Mintable.sol";
import "./MixinOwnable.sol";
import "./HashRegistry.sol";
import "./POBMinter.sol";

contract GenesisMinter is Ownable {
  using LibSafeMath for uint256;

  uint256 public tokenType;

  ERC1155Mintable public mintableErc1155;
  HashRegistry public registry;
  POBMinter public pobMinterV1;

  uint256 immutable startingPrice;

  uint256 immutable pricePerMint;

  uint256 immutable flatPriceUpTo;

  uint256 immutable maxMintingSupply;

  address payable public treasury;

  constructor(
    address _registry,
    address _pobMinterV1,
    address _mintableErc1155,
    address payable _treasury,
    uint256 _tokenType,
    uint256 _startingPrice,
    uint256 _pricePerMint,
    uint256 _flatPriceUpTo,
    uint256 _maxMintingSupply
  ) {
    registry = HashRegistry(_registry);
    pobMinterV1 = POBMinter(_pobMinterV1);
    mintableErc1155 = ERC1155Mintable(_mintableErc1155);
    treasury = _treasury;
    startingPrice = _startingPrice;
    pricePerMint = _pricePerMint;
    tokenType = _tokenType;
    flatPriceUpTo = _flatPriceUpTo;
    maxMintingSupply = _maxMintingSupply;
  }

  modifier onlyValueOverPriceForMint() {
    require(msg.value >= pricingCurve(maxIndex()), 'insufficient funds to pay for mint');
    _;
  }

  modifier onlyUnderMaxSupply() {
    require(mintableErc1155.maxIndex(tokenType) < maxMintingSupply, 'max supply minted');
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

  function mint(address _dst, uint256 _txHash) public payable onlyUnderMaxSupply() onlyValueOverPriceForMint() {
    uint256 price = pricingCurve(maxIndex());
    treasury.transfer(price);
    msg.sender.transfer(msg.value.safeSub(price));
    address[] memory dsts = new address[](1);
    dsts[0] = _dst;
    uint256 index = mintableErc1155.maxIndex(tokenType) + 1;
    uint256 tokenId  = tokenType | index;
    mintableErc1155.mintNonFungible(tokenType, dsts);
    uint256[] memory tokenIds = new uint256[](1);
    tokenIds[0] = tokenId;
    uint256[] memory txHashes = new uint256[](1);
    txHashes[0] = _txHash; 
    registry.writeToRegistry(tokenIds, txHashes);
  } 
}