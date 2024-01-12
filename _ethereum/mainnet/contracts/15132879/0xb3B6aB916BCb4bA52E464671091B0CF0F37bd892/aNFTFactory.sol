// SPDX-License-Identifier: GPL-3.0

pragma solidity 0.8.13;

/// @title: aNFT Factory
/// @author: circle.xyz

import "./ECDSA.sol";
import "./Ownable.sol";
import "./Clones.sol";
import "./aNFTCollectionInterface.sol";

contract aNFTFactory is Ownable {
  address private publicMintSigner;
  address private collectionCreationSigner;
  address public fixedImplementation;
  address public dutchAuctionImplementation;

  uint256 constant hundredPercent = 10000;//100.00%

  mapping (address => bool) private aNFT;
  mapping (address => address[]) private collections;

  //record of used signatures
  mapping(bytes32 => bool) private usedMessages;

  event NewFixedCollection(address indexed collection);
  event NewDutchAuctionCollection(address indexed collection);

  aNFTCollectionInterface.FeeConfig public feeConfig;

  struct Source {
    uint256 timestamp; 
    bytes signature;
  }

  constructor(
    address _fixedImplementation, 
    address _dutchAuctionImplementation, 
    aNFTCollectionInterface.FeeConfig memory _feeConfig
  ) {
    require(_feeConfig.percent > 0 && _feeConfig.percent < hundredPercent, 'incorrect fee percent');
    feeConfig = _feeConfig;
    fixedImplementation = _fixedImplementation;
    dutchAuctionImplementation = _dutchAuctionImplementation;
    publicMintSigner = msg.sender;
    collectionCreationSigner = msg.sender;
  }

  function createFixedCollection(
    uint256 _price,
    aNFTCollectionInterface.AccessConfig memory _collectionConfig,
    uint256 _maxMint,
    bytes32 _allowlistMerkleRoot,
    bytes32 _claimlistMerkleRoot,
    aNFTCollectionInterface.RoyaltiesConfig memory _royaltiesConfig,
    bool _mintState,
    bool _mintListSate, 
    Source memory _referrer,
    address _owner
  ) external {

    _validateRequest(_referrer);

    address collection = Clones.clone(fixedImplementation);

    aNFTCollectionInterface(collection).initializeFixed(
      _price,
      _collectionConfig,
      _maxMint,
      _allowlistMerkleRoot, 
      _claimlistMerkleRoot, 
      _royaltiesConfig,
      feeConfig,
      _mintState,
      _mintListSate,
      _owner
    );

    emit NewFixedCollection(collection);
    aNFT[collection] = true;
    collections[_owner == address(0)?msg.sender:_owner].push(collection);
  }

  function createDutchAuctionCollection(
    uint256 _startPrice,
    aNFTCollectionInterface.AccessConfig memory _collectionConfig,
    uint256 _maxMint,
    bytes32 _allowlistMerkleRoot,
    bytes32 _claimlistMerkleRoot,
    aNFTCollectionInterface.RoyaltiesConfig memory _royaltiesConfig,
    bool _mintState,
    bool _mintListSate,
    Source memory _referrer,
    address _owner
  ) external {

    _validateRequest(_referrer);

    address collection = Clones.clone(dutchAuctionImplementation);

    aNFTCollectionInterface(collection).initializeDutchAuction(
      _startPrice,
      _collectionConfig,
      _maxMint,
      _allowlistMerkleRoot, 
      _claimlistMerkleRoot, 
      _royaltiesConfig,
      feeConfig,
      _mintState,
      _mintListSate,
      _owner
    );

    emit NewDutchAuctionCollection(collection);
    aNFT[collection] = true;
    collections[_owner == address(0)?msg.sender:_owner].push(collection);
  }

  function getPublicMintSigner() view external returns (address){
    return publicMintSigner;
  }

  function getCollectionCreationSigner() view external returns (address){
    return collectionCreationSigner;
  }

  function changeFeeConfig(aNFTCollectionInterface.FeeConfig memory _feeConfig) external onlyOwner {
    feeConfig = _feeConfig;
  }

  function changeFixedImplementation(address _fixedImplementation) external onlyOwner {
    fixedImplementation = _fixedImplementation;
  }

  function changeDutchAuctionImplementation(address _dutchAuctionImplementation) external onlyOwner {
    dutchAuctionImplementation = _dutchAuctionImplementation;
  }

  function changePublicMintSigner(address _publicMintSigner) external onlyOwner {
    publicMintSigner = _publicMintSigner;
  }

  function changeCollectionCreationSigner(address _collectionCreationSigner) external onlyOwner {
    collectionCreationSigner = _collectionCreationSigner;
  } 
  
  function markMessageAsUsed(bytes32 msgHash) external {
    require(aNFT[msg.sender], 'not access nft');
    require(usedMessages[msgHash] == false, "Duplicate message");
    usedMessages[msgHash] = true;
  }

  function isCollection(address contractAddress) external view returns (bool){
    return aNFT[contractAddress];
  }

  function getCollections(address walletAddress) external view returns (address[] memory){
    return collections[walletAddress];
  }

  function _validateRequest(Source memory _referrer) internal {
    bytes32 msgHash = keccak256(abi.encodePacked(msg.sender, _referrer.timestamp));
    require(usedMessages[msgHash] == false, "Duplicate message");
    usedMessages[msgHash] = true;
    require(_isValidSignature(msgHash, _referrer.signature), "Invalid signature");
  }

  function _isValidSignature(bytes32 hash, bytes memory signature) internal view returns (bool isValid) {
    bytes32 signedHash = keccak256(abi.encodePacked("\x19Ethereum Signed Message:\n32", hash));
    return ECDSA.recover(signedHash, signature) == collectionCreationSigner;
  }
}