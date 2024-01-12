// SPDX-License-Identifier: GPL-3.0

/// @title: aNFT Collection Interface
/// @author: circle.xyz

pragma solidity 0.8.13;

interface aNFTCollectionInterface {

  enum DropType{ allowlist, claimlist }//list type

  struct AccessConfig {
    string name;
    string symbol;
    string baseURI;
    uint256 size;
  }

  struct RoyaltiesConfig {
    address receiver;
    uint256 percent;//ex. 1000 = 10%
  }

  struct FeeConfig {
    address receiver;
    uint256 percent;//ex. 1000 = 10%
  }

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
  ) external;

  function initializeDutchAuction(
    uint256 _startPrice,
    aNFTCollectionInterface.AccessConfig memory _collectionConfig, 
    uint256 _maxMint,
    bytes32 _allowlistMerkleRoot,
    bytes32 _claimlistMerkleRoot,
    aNFTCollectionInterface.RoyaltiesConfig memory _royaltiesConfig,
    aNFTCollectionInterface.FeeConfig memory _feeConfig,
    bool _mintState,
    bool _mintListSate,
    address _owner
  ) external;

}