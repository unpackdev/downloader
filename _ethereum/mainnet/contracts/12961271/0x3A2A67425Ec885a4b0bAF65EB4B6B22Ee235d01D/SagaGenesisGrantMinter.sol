// SPDX-License-Identifier: MIT

pragma solidity ^0.7.0;
pragma experimental ABIEncoderV2;

import "./LibSafeMath.sol";
import "./ERC1155Mintable.sol";
import "./MixinOwnable.sol";
import "./MixinPausable.sol";
import "./HashRegistry.sol";

contract SagaGenesisGrantMinter is Ownable, MixinPausable {
  using LibSafeMath for uint256;

  uint256 public tokenType;
  uint256 public genesisTokenType1;
  uint256 public genesisTokenType2;

  ERC1155Mintable public mintableErc1155;
  HashRegistry public registry;
  mapping (address => uint256) public mintedCount;
  mapping (address => bool) public permittedProxies;

  // max total minting supply
  uint256 immutable maxMintingSupply;
  uint256 public maxIndex = 0;

  constructor(
    address _registry,
    address _mintableErc1155,
    uint256 _tokenType,
    uint256 _genesisTokenType1,
    uint256 _genesisTokenType2,
    uint256 _maxMintingSupply
  ) {
    registry = HashRegistry(_registry);
    mintableErc1155 = ERC1155Mintable(_mintableErc1155);
    tokenType = _tokenType;
    genesisTokenType1 = _genesisTokenType1;
    genesisTokenType2 = _genesisTokenType2;
    maxMintingSupply = _maxMintingSupply;
  }

  modifier onlyUnderMaxSupply(uint256 mintingAmount) {
    require(maxIndex + mintingAmount <= maxMintingSupply, 'max supply minted');
    _;
  }

  modifier onlyUnderGenesisMintedCount(address permitted, uint256 mintingAmount) {
    require(mintedCount[permitted] + mintingAmount <= (mintableErc1155.balanceOf(permitted, genesisTokenType1) + mintableErc1155.balanceOf(permitted, genesisTokenType2)), 'exceeded genesis minted count');
    _;
  }

  modifier onlyProxy() {
    require(permittedProxies[_msgSender()] == true, 'not called from a valid proxy');
    _;
  }

  function pause() external onlyOwner() {
    _pause();
  } 

  function unpause() external onlyOwner() {
    _unpause();
  }  

  function setPermittedProxies(address _proxy, bool _status) external onlyOwner() {
    permittedProxies[_proxy] = _status;
  }

  function mint(address[] calldata _dsts, uint256[] calldata _txHashes) public payable whenNotPaused() onlyUnderGenesisMintedCount(_msgSender(), _dsts.length) onlyUnderMaxSupply(_dsts.length) {
    require(_dsts.length == _txHashes.length, "dsts, txhashes length mismatch");
    mintedCount[_msgSender()] = mintedCount[_msgSender()] + _dsts.length;
    _mint(_dsts, _txHashes);
  }

  function mintByProxy(address[] calldata _dsts, uint256[] calldata _txHashes) public payable onlyProxy() whenNotPaused() onlyUnderGenesisMintedCount(_txOrigin(), _dsts.length) onlyUnderMaxSupply(_dsts.length) {
    require(_dsts.length == _txHashes.length, "dsts, txhashes length mismatch");
    mintedCount[_txOrigin()] = mintedCount[_txOrigin()] + _dsts.length;
    _mint(_dsts, _txHashes);
  }

  function _mint(address[] memory dsts, uint256[] memory txHashes) internal {
    uint256[] memory tokenIds = new uint256[](dsts.length);
    uint256 currentTokenMaxIndex = mintableErc1155.maxIndex(tokenType);
    for (uint256 i = 0; i < dsts.length; ++i) {
      uint256 index = currentTokenMaxIndex + 1 + i;
      uint256 tokenId  = tokenType | index;
      tokenIds[i] = tokenId;
    }
    mintableErc1155.mintNonFungible(tokenType, dsts);
    registry.writeToRegistry(tokenIds, txHashes);
    maxIndex += dsts.length;
  }
}