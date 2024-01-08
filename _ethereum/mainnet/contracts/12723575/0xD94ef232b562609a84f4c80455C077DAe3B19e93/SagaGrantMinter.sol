pragma solidity ^0.7.0;
pragma experimental ABIEncoderV2;

import "./LibSafeMath.sol";
import "./ERC1155Mintable.sol";
import "./MixinOwnable.sol";
import "./MixinPausable.sol";
import "./HashRegistry.sol";

contract SagaGrantMinter is Ownable, MixinPausable {
  using LibSafeMath for uint256;

  uint256 public tokenType;

  ERC1155Mintable public mintableErc1155;
  HashRegistry public registry;
  mapping (address => uint256) public grantedCount;
  mapping (address => uint256) public mintedCount;

  // max total minting supply
  uint256 immutable maxMintingSupply;

  constructor(
    address _registry,
    address _mintableErc1155,
    uint256 _tokenType,
    uint256 _maxMintingSupply
  ) {
    registry = HashRegistry(_registry);
    mintableErc1155 = ERC1155Mintable(_mintableErc1155);
    tokenType = _tokenType;
    maxMintingSupply = _maxMintingSupply;
  }

  modifier onlyUnderMaxSupply(uint256 mintingAmount) {
    require(maxIndex() + mintingAmount <= maxMintingSupply, 'max supply minted');
    _;
  }

  modifier onlyUnderGrantedCount(uint256 mintingAmount) {
    require(mintedCount[_msgSender()] + mintingAmount <= grantedCount[_msgSender()], 'granted supply minted');
    _;
  }

  function pause() external onlyOwner() {
    _pause();
  } 

  function unpause() external onlyOwner() {
    _unpause();
  }  

  function maxIndex() public view returns (uint256) {
    return mintableErc1155.maxIndex(tokenType);
  }

  function setGrantedCount(address _granted, uint256 _count) external onlyOwner() {
    grantedCount[_granted] = _count;
  }

  function mint(address[] calldata _dsts, uint256[] calldata _txHashes) public payable whenNotPaused() onlyUnderGrantedCount(_dsts.length) onlyUnderMaxSupply(_dsts.length) {
    require(_dsts.length == _txHashes.length, "dsts, txhashes length mismatch");
    mintedCount[_msgSender()] = mintedCount[_msgSender()] + _dsts.length;
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
}