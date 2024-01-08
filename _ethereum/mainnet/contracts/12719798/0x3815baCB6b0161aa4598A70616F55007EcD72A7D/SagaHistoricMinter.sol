pragma solidity ^0.7.0;
pragma experimental ABIEncoderV2;

import "./LibSafeMath.sol";
import "./ERC1155Mintable.sol";
import "./MixinOwnable.sol";
import "./MixinPausable.sol";
import "./HashRegistry.sol";

contract SagaHistoricMinter is Ownable, MixinPausable {
  using LibSafeMath for uint256;

  uint256 public tokenType;

  ERC1155Mintable public mintableErc1155;
  HashRegistry public registry;

  // historic pricing params
  uint256 public flatPriceForHistoric;
  // max total minting supply
  uint256 immutable maxMintingSupply;

  address payable public treasury;

  constructor(
    address _registry,
    address _mintableErc1155,
    address payable _treasury,
    uint256 _tokenType,
    uint256 _flatPriceForHistoric,
    uint256 _maxMintingSupply
  ) {
    registry = HashRegistry(_registry);
    mintableErc1155 = ERC1155Mintable(_mintableErc1155);
    treasury = _treasury;
    tokenType = _tokenType;
    flatPriceForHistoric = _flatPriceForHistoric;
    maxMintingSupply = _maxMintingSupply;
  }

  modifier onlyUnderMaxSupply(uint256 mintingAmount) {
    require(maxIndex() + mintingAmount <= maxMintingSupply, 'max supply minted');
    _;
  }

  function pause() external onlyOwner() {
    _pause();
  } 

  function unpause() external onlyOwner() {
    _unpause();
  }  

  function setTreasury(address payable _treasury) external onlyOwner() {
    treasury = _treasury;
  }

  function setFlatPriceForHistoric(uint256 _flatPriceForHistoric) external onlyOwner() {
    flatPriceForHistoric = _flatPriceForHistoric;
  }

  function maxIndex() public view returns (uint256) {
    return mintableErc1155.maxIndex(tokenType);
  }

  function pricingCurveForHistoric(uint256 _maxIndex) public view returns (uint256) {
    return flatPriceForHistoric; 
  }

  function mint(address[] calldata _dsts, uint256[] calldata _txHashes) public payable whenNotPaused() onlyUnderMaxSupply(_dsts.length) {
    require(_dsts.length == _txHashes.length, "dsts, txhashes length mismatch");
    // verify and transfer fee
    uint256 price = flatPriceForHistoric * _txHashes.length;
    require(price <= msg.value, "insufficient funds to pay for mint");
    treasury.call{value: price}("");
    // msg.sender will be limited by gas
    msg.sender.transfer(msg.value.safeSub(price));
    _mint(_dsts, _txHashes);
  }

  function _mint(address[] memory dsts, uint256[] memory txHashes) internal {
    uint256[] memory tokenIds = new uint256[](dsts.length);
    for (uint256 i = 0; i < dsts.length; ++i) {
      uint256 index = maxIndex() + 1 + i;
      uint256 tokenId  = tokenType | index;
      tokenIds[i] = tokenId;
    }
    mintableErc1155.mintNonFungible(tokenType, dsts);
    registry.writeToRegistry(tokenIds, txHashes);
  }

  // function _mintWithSignedTexts(address[] memory dsts, uint256[] memory txHashes, string[] memory keys, SignedText[] memory signedTexts) internal {
  //   uint256[] memory tokenIds = new uint256[](dsts.length);
  //   address[] memory selfDsts = new address[](dsts.length);
  //   for (uint256 i = 0; i < dsts.length; ++i) {
  //     uint256 index = maxIndex() + 1 + i;
  //     uint256 tokenId  = tokenType | index;
  //     tokenIds[i] = tokenId;
  //     selfDsts = address(self);
  //   }
  //   mintableErc1155.mintNonFungible(tokenType, selfDsts);
  //   registry.writeToRegistry(tokenIds, txHashes);
  //   // write signed messagse
  //   for (uint256 i = 0; i < dsts.length; ++i) {
  //     uint256[] memory k = new uint256[](1);
  //     SignedText[] memory t = new SignedText[](1);
  //     k[0] = keys[i];
  //     t[0] = signedTexts[i];
  //     metadataRegistry.writeAndVerifyDocuments(tokenIds[i], k, t);
  //   }
  //   // transfer to dsts
  //   for (uint256 i = 0; i < dsts.length; ++i) {
  //     mintableErc1155.safeTransferFrom(address(self), dsts[i], tokenIds[i], 1, "");
  //   }
  // }

}