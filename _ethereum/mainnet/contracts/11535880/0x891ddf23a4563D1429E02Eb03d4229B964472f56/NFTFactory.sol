// SPDX-License-Identifier: MIT
pragma solidity 0.6.12;
pragma experimental ABIEncoderV2;

import "./INFT.sol";
import "./IRAMVault.sol";
import "./NFT.sol";

import "./Ownable.sol";
import "./StorageState.sol";

contract NFTFactory is StorageState, OwnableUpgradeSafe {
  address[] public contracts;
  address public bondedContract;
  IRAMVault ramVault;
  // address public lastContractAddress;
  mapping(address => bool) public inUse;

  event NFTMinted(string tokenName, address to, uint256 tokenId);
  event NFTBurned(string tokenName, address from, uint256 tokenId);

  constructor(YGYStorageV1 __storage) public {
    __Ownable_init();
    _storage = __storage;
  }

  function deployNFT(
    string memory name,
    string memory symbol,
    string memory tokenURI,
    uint256 contractId,
    uint256 propertyChoices,
    address admin,
    bool allowTrade,
    bool isCapped,
    uint256 capAmount,
    address _ramVault
  ) public returns (NFT newContract) {
    require(_msgSender() == owner() || _msgSender() == bondedContract, "Invalid caller: can't deploy NFT");
    ramVault = IRAMVault(_ramVault);

    // Deploy new NFT
    NFT nft = new NFT(name, symbol, tokenURI, contractId, propertyChoices, admin, allowTrade, isCapped, capAmount, _ramVault);

    address addressNFT = address(nft);

    // Add to owned NFTs
    contracts.push(addressNFT);

    return nft;
  }

  function balanceOf(INFT _nft, address _who) external view returns (uint256) {
    return _nft.balanceOf(_who);
  }

  function isOwner(
    INFT _nft,
    address _who,
    uint256 _tokenId
  ) external view returns (bool) {
    return _nft.ownerOf(_tokenId) == _who;
  }

  function mint(
    INFT _nft,
    address _to,
    uint256 _randomness
  ) external returns (uint256) {
    require(_msgSender() == bondedContract || _msgSender() == owner());
    uint256 tokenId = _nft.mint(_to, _randomness, _storage);

    emit NFTMinted(_nft.name(), _to, tokenId);
    return tokenId;
  }

  function burn(INFT _nft, uint256 _tokenId) external {
    require(_nft.ownerOf(_tokenId) == _msgSender() || _msgSender() == bondedContract);
    _nft.burn(_tokenId);
    emit NFTBurned(_nft.name(), _msgSender(), _tokenId);
  }

  function setNFTProperties(address _nft, YGYStorageV1.NFTProperty[] memory _properties) external {
    require(msg.sender == owner());
    _storage.setNFTPropertiesForContract(_nft, _properties);
  }

  function useNFT(
    INFT _nft,
    uint256 _tokenId,
    uint256 _poolId
  ) public {
    require(_nft.ownerOf(_tokenId) == msg.sender, "User not owner");
    YGYStorageV1.NFTUsage[] memory nftUsage = _storage.getNFTsInUse(msg.sender);

    uint256 contractId = _nft.contractId();
    bool alreadyInUse;

    // check if nft instance is already in use for the user
    for (uint256 i; i < nftUsage.length; i++) {
      if (nftUsage[i].contractId == contractId) {

        alreadyInUse = true;
        break;
      }
    }
    require(!alreadyInUse, "NFT already in use");

    _nft.transferFrom(msg.sender, address(ramVault), _tokenId);
    ramVault.NFTUsage(msg.sender, address(_nft), _tokenId, _poolId);
  }

  function setNFTUsage(address _nft, bool _inUse) external onlyOwner {
    inUse[_nft] = _inUse;
  }

  function bondContract(address _addr) external returns (bool) {
    require(msg.sender == owner());
    bondedContract = _addr;
    return true;
  }

  function getContractCount() external view returns (uint256 contractCount) {
    return contracts.length;
  }
}
