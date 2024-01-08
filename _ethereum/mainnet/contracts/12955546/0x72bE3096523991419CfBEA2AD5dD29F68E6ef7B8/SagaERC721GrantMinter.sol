// SPDX-License-Identifier: MIT

pragma solidity ^0.7.0;
pragma experimental ABIEncoderV2;

import "./LibSafeMath.sol";
import "./ERC1155Mintable.sol";
import "./MixinOwnable.sol";
import "./IERC721.sol";
import "./MixinPausable.sol";
import "./HashRegistry.sol";

contract SagaERC721GrantMinter is Ownable, MixinPausable {
  using LibSafeMath for uint256;

  uint256 public tokenType;

  uint256 constant MAX_MINT_PER_ADDRESS = 1;

  IERC721 public erc721;
  ERC1155Mintable public mintableErc1155;
  HashRegistry public registry;
  mapping (address => uint256) public mintedCount;
  mapping (address => bool) public permittedProxies;

  // max total minting supply
  uint256 immutable maxMintingSupply;
  uint256 public maxIndex = 0;

  constructor(
    address _registry,
    address _erc721,
    address _mintableErc1155,
    uint256 _tokenType,
    uint256 _maxMintingSupply
  ) {
    registry = HashRegistry(_registry);
    erc721 = IERC721(_erc721);
    mintableErc1155 = ERC1155Mintable(_mintableErc1155);
    tokenType = _tokenType;
    maxMintingSupply = _maxMintingSupply;
  }

  modifier onlyUnderMaxSupply(uint256 mintingAmount) {
    require(maxIndex + mintingAmount <= maxMintingSupply, 'max supply minted');
    _;
  }

  modifier onlyUnderErc721BalanceCount(address permitted, uint256 mintingAmount) {
    require(mintedCount[permitted] + mintingAmount <= erc721.balanceOf(permitted), 'exceeded erc721 balance');
    _;
  }

  modifier onlyUnderMaxMintPerAddressCount(address permitted, uint256 mintingAmount) {
    require(mintedCount[permitted] + mintingAmount <= MAX_MINT_PER_ADDRESS, 'exceeded max mint per address');
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

  function mint(address[] calldata _dsts, uint256[] calldata _txHashes) public payable whenNotPaused() onlyUnderMaxMintPerAddressCount(_msgSender(), _dsts.length) onlyUnderErc721BalanceCount(_msgSender(), _dsts.length) onlyUnderMaxSupply(_dsts.length) {
    require(_dsts.length == _txHashes.length, "dsts, txhashes length mismatch");
    mintedCount[_msgSender()] = mintedCount[_msgSender()] + _dsts.length;
    _mint(_dsts, _txHashes);
  }

  function mintByProxy(address[] calldata _dsts, uint256[] calldata _txHashes) public payable onlyProxy() whenNotPaused() onlyUnderMaxMintPerAddressCount(_txOrigin(), _dsts.length) onlyUnderErc721BalanceCount(_txOrigin(), _dsts.length) onlyUnderMaxSupply(_dsts.length) {
    require(_dsts.length == _txHashes.length, "dsts, txhashes length mismatch");
    mintedCount[_txOrigin()] = mintedCount[_txOrigin()] + _dsts.length;
    _mint(_dsts, _txHashes);
  }

  function _mint(address[] memory dsts, uint256[] memory txHashes) internal {
    uint256[] memory tokenIds = new uint256[](dsts.length);
    for (uint256 i = 0; i < dsts.length; ++i) {
      uint256 index = maxIndex + 1 + i;
      uint256 tokenId  = tokenType | index;
      tokenIds[i] = tokenId;
    }
    mintableErc1155.mintNonFungible(tokenType, dsts);
    registry.writeToRegistry(tokenIds, txHashes);
    maxIndex += dsts.length;
  }
}