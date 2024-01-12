// SPDX-License-Identifier: GPL-3.0

pragma solidity 0.8.13;

/// @title: aNFT Collection
/// @author: circle.xyz

import "./aNFTCollectionInterface.sol";
import "./aNFTLogic.sol";

contract aNFTCollectionDropFixed is aNFTLogic {

  constructor() aNFTLogic() {}
  uint256 private price;

  /**
  @notice initialize fixed price collection contract
  @param _price nft price in wei
  @param _collectionConfig includes: name, symbol, baseURI, supply
  @param _maxMint nft public mint limit per wallet address
  @param _allowlistMerkleRoot merkle tree root for allowlist
  @param _claimlistMerkleRoot merkle tree root for claim list
  @param _royaltiesConfig royalty info for nft marketplaces ERC2981
  @param _feeConfig withdraw fee percentage and recipient
  @param _mintState public mint state
  */
  function initializeFixed(
      uint256 _price,
      aNFTCollectionInterface.AccessConfig memory _collectionConfig, 
      uint256 _maxMint,
      bytes32 _allowlistMerkleRoot,
      bytes32 _claimlistMerkleRoot,
      aNFTCollectionInterface.RoyaltiesConfig memory _royaltiesConfig,
      aNFTCollectionInterface.FeeConfig memory _feeConfig,
      bool _mintState,
      bool _mintListSate,
      address _owner
    ) external {
      price = _price;
      initialize(
            _collectionConfig, 
            _maxMint,
            _allowlistMerkleRoot,
            _claimlistMerkleRoot,
            _royaltiesConfig,
            _feeConfig,
            _mintState,
            _mintListSate,
            _owner
          );
  }

  //returns nft price
  function getPrice() view public override returns (uint256){
    return price;
  }

  //update nft public mint price
  function setPrice(uint256 newPrice) external onlyOwner {
     require(mintState == false, 'sale is active');
     require(newPrice > 0, 'price cannot be 0');
     price = newPrice;
  }

  //allowlist mint
  function mintAllowlist(bytes32[] calldata _merkleProof, uint256 mintAllocation, uint256 mintAmount) external override payable {
    require(msg.value >= getPrice() * mintAmount, "Need to send more ETH.");
    _listMint(aNFTCollectionInterface.DropType.allowlist, allowlistMerkleRoot, _merkleProof, mintAllocation, mintAmount);
  }

}