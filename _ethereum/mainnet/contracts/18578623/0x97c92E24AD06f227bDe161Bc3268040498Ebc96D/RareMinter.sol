// SPDX-License-Identifier: MIT
pragma solidity 0.8.18;

import "./IERC721.sol";
import "./Initializable.sol";
import "./OwnableUpgradeable.sol";
import "./ReentrancyGuardUpgradeable.sol";
import "./UUPSUpgradeable.sol";

import "./MarketConfig.sol";
import "./MarketUtils.sol";
import "./IERC721Mint.sol";
import "./IRareMinter.sol";

/// @author SuperRareLabs Inc.
/// @title RareMinter
/// @notice The logic for all functions related to the RareMinter.
contract RareMinter is Initializable, IRareMinter, OwnableUpgradeable, ReentrancyGuardUpgradeable, UUPSUpgradeable {
  using MarketUtils for MarketConfig.Config;
  using MarketConfig for MarketConfig.Config;

  //////////////////////////////////////////////////////////////////////////
  //                      Private Storage
  //////////////////////////////////////////////////////////////////////////

  // Config for the market actions
  MarketConfig.Config private marketConfig;

  // Mapping of contract address to direct sale config
  mapping(address => DirectSaleConfig) private directSaleConfigs;

  // Mapping of contract address to allow list config
  mapping(address => AllowListConfig) private contractAllowlistRoots;

  // Mapping of contract address to the mint limit for limiting mints per address
  mapping(address => uint256) private contractMintLimit;

  // Mapping of contract address to address to total mints
  mapping(address => mapping(address => uint256)) private contractMintsPerAddress;

  // Mapping of contract address to the mint limit for limiting mints per address
  mapping(address => uint256) private contractTxLimit;

  // Mapping of contract address to address to total mints
  mapping(address => mapping(address => uint256)) private contractTxsPerAddress;

  //////////////////////////////////////////////////////////////////////////
  //                      Initializer
  //////////////////////////////////////////////////////////////////////////
  function initialize(
    address _networkBeneficiary,
    address _marketplaceSettings,
    address _spaceOperatorRegistry,
    address _royaltyEngine,
    address _payments,
    address _approvedTokenRegistry,
    address _stakingSettings,
    address _stakingRegistry
  ) external initializer {
    marketConfig = MarketConfig.generateMarketConfig(
      _networkBeneficiary,
      _marketplaceSettings,
      _spaceOperatorRegistry,
      _royaltyEngine,
      _payments,
      _approvedTokenRegistry,
      _stakingSettings,
      _stakingRegistry
    );
    __Ownable_init();
  }

  //////////////////////////////////////////////////////////////////////////
  //                      External Read Functions
  //////////////////////////////////////////////////////////////////////////
  function getDirectSaleConfig(address _contractAddress) external view returns (DirectSaleConfig memory) {
    return directSaleConfigs[_contractAddress];
  }

  function getContractAllowListConfig(address _contractAddress) external view returns (AllowListConfig memory) {
    return contractAllowlistRoots[_contractAddress];
  }

  function getContractMintLimit(address _contractAddress) external view returns (uint256) {
    return contractMintLimit[_contractAddress];
  }

  function getContractMintsPerAddress(address _contractAddress, address _address) external view returns (uint256) {
    return contractMintsPerAddress[_contractAddress][_address];
  }

  function getContractTxLimit(address _contractAddress) external view returns (uint256) {
    return contractTxLimit[_contractAddress];
  }

  function getContractTxsPerAddress(address _contractAddress, address _address) external view returns (uint256) {
    return contractTxsPerAddress[_contractAddress][_address];
  }

  //////////////////////////////////////////////////////////////////////////
  //                      External Write Functions
  //////////////////////////////////////////////////////////////////////////
  function prepareMintDirectSale(
    address _contractAddress,
    address _currencyAddress,
    uint256 _price,
    uint256 _startTime,
    uint256 _maxMints,
    address payable[] calldata _splitRecipients,
    uint8[] calldata _splitRatios
  ) external {
    require(
      OwnableUpgradeable(_contractAddress).owner() == msg.sender,
      "prepareMintDirectSale::Only mint contract owner can prepare the mint"
    );
    directSaleConfigs[_contractAddress] = DirectSaleConfig(
      msg.sender,
      _currencyAddress,
      _price,
      _startTime,
      _maxMints,
      _splitRecipients,
      _splitRatios
    );
    emit PrepareMintDirectSale(
      _contractAddress,
      _currencyAddress,
      msg.sender,
      _price,
      _startTime,
      _maxMints,
      _splitRecipients,
      _splitRatios
    );
  }

  function setContractAllowListConfig(bytes32 _root, uint256 _endTimestamp, address _contractAddress) external {
    require(
      msg.sender == OwnableUpgradeable(_contractAddress).owner(),
      "setContractAllowListConfig::Only contract owner can set"
    );
    contractAllowlistRoots[_contractAddress] = AllowListConfig(_root, _endTimestamp);
    emit SetContractAllowListConfig(_root, _endTimestamp, _contractAddress);
  }

  function setContractMintLimit(address _contractAddress, uint256 _limit) external {
    require(
      msg.sender == OwnableUpgradeable(_contractAddress).owner(),
      "setContractMintLimit::Only contract owner can set"
    );
    contractMintLimit[_contractAddress] = _limit;
    emit ContractMintLimitSet(_contractAddress, _limit);
  }

  function setContractTxLimit(address _contractAddress, uint256 _limit) external {
    require(
      msg.sender == OwnableUpgradeable(_contractAddress).owner(),
      "setContractTxLimit::Only contract owner can set"
    );
    contractTxLimit[_contractAddress] = _limit;
    emit ContractTxLimitSet(_contractAddress, _limit);
  }

  function mintDirectSale(
    address _contractAddress,
    address _currencyAddress,
    uint256 _price,
    uint8 _numMints,
    bytes32[] calldata _proof
  ) external payable nonReentrant {
    DirectSaleConfig memory directSaleConfig = directSaleConfigs[_contractAddress];
    // Perform checks
    _enforceContractAllowList(_contractAddress, msg.sender, _proof);
    // Num Mint Check
    require(_numMints > 0, "mintDirectSale::Mints must be greater than 0");

    // Contract mint limit check
    require(
      contractMintLimit[_contractAddress] == 0 ||
        contractMintsPerAddress[_contractAddress][msg.sender] + _numMints <= contractMintLimit[_contractAddress],
      "mintDirectSale::Exceeded mint limit for address"
    );

    // Transaction Limit Check
    require(
      contractTxLimit[_contractAddress] == 0 ||
        contractTxsPerAddress[_contractAddress][msg.sender] + 1 <= contractTxLimit[_contractAddress],
      "mintDirectSale::Exceeded transaction limit for address"
    );

    // Max Mints Check
    require(
      directSaleConfig.maxMints == 0 || _numMints <= directSaleConfig.maxMints,
      "mintDirectSale::Mints must be less than maxMint if enabled"
    );
    // Start Time Check
    require(directSaleConfig.startTime <= block.timestamp, "mintDirectSale::Sale has not started");

    // Configured Check
    require(directSaleConfig.seller != address(0), "mintDirectSale::Contract not prepared for direct sale");

    // Price Check
    require(_price == directSaleConfig.price, "mintDirectSale::Price does not match required price");

    // Approved Currency Check
    marketConfig.checkIfCurrencyIsApproved(_currencyAddress);

    // Currency Match Check
    require(
      directSaleConfig.currencyAddress == _currencyAddress,
      "mintDirectSale::Currency does not match required currency"
    );

    uint256 totalPrice = _numMints * _price;
    // Check amount
    if (directSaleConfig.price != 0) {
      uint256 requiredAmount = totalPrice + marketConfig.marketplaceSettings.calculateMarketplaceFee(totalPrice);
      MarketUtils.checkAmountAndTransfer(_currencyAddress, requiredAmount);
    }

    // If Enabled, update mint count
    if (contractMintLimit[_contractAddress] > 0) {
      contractMintsPerAddress[_contractAddress][msg.sender] += _numMints;
    }

    // If Enabled, update tx count
    if (contractTxLimit[_contractAddress] > 0) {
      contractTxsPerAddress[_contractAddress][msg.sender] += 1;
    }

    // Perform Mint
    uint256 tokenIdStart = IERC721Mint(_contractAddress).mintTo(msg.sender); // get first Token Id in range of mint
    try marketConfig.marketplaceSettings.markERC721Token(_contractAddress, tokenIdStart, true) {} catch {}
    for (uint256 i = 1; i < _numMints; i++) {
      // Start with offset of 1 since already minted first
      IERC721Mint(_contractAddress).mintTo(msg.sender);
      try marketConfig.marketplaceSettings.markERC721Token(_contractAddress, tokenIdStart + i, true) {} catch {}
    }

    // Perform payout
    if (directSaleConfig.price != 0) {
      marketConfig.payout(
        _contractAddress,
        tokenIdStart,
        _currencyAddress,
        totalPrice,
        directSaleConfig.seller,
        directSaleConfig.splitRecipients,
        directSaleConfig.splitRatios
      );
    }

    emit MintDirectSale(
      _contractAddress,
      directSaleConfig.seller,
      msg.sender,
      tokenIdStart,
      tokenIdStart + _numMints - 1,
      _currencyAddress,
      _price
    );
  }

  //////////////////////////////////////////////////////////////////////////
  //                      Internal UUPS Functions
  //////////////////////////////////////////////////////////////////////////
  /// @inheritdoc UUPSUpgradeable
  function _authorizeUpgrade(address) internal override onlyOwner {}

  //////////////////////////////////////////////////////////////////////////
  //                      Admin Write Functions
  //////////////////////////////////////////////////////////////////////////
  function setNetworkBeneficiary(address _networkBeneficiary) external onlyOwner {
    marketConfig.updateNetworkBeneficiary(_networkBeneficiary);
  }

  function setMarketplaceSettings(address _marketplaceSettings) external onlyOwner {
    marketConfig.updateMarketplaceSettings(_marketplaceSettings);
  }

  function setSpaceOperatorRegistry(address _spaceOperatorRegistry) external onlyOwner {
    marketConfig.updateSpaceOperatorRegistry(_spaceOperatorRegistry);
  }

  function setRoyaltyEngine(address _royaltyEngine) external onlyOwner {
    marketConfig.updateRoyaltyEngine(_royaltyEngine);
  }

  function setPayments(address _payments) external onlyOwner {
    marketConfig.updatePayments(_payments);
  }

  function setApprovedTokenRegistry(address _approvedTokenRegistry) external onlyOwner {
    marketConfig.updateApprovedTokenRegistry(_approvedTokenRegistry);
  }

  //////////////////////////////////////////////////////////////////////////
  //                      Internal Write Functions
  //////////////////////////////////////////////////////////////////////////
  /// @notice Checks to see if the address is on the contract allow list
  /// @param _contractAddress address The address of the ERC721 contract
  /// @param _address address The address of to be checked against the allow list
  function _enforceContractAllowList(
    address _contractAddress,
    address _address,
    bytes32[] memory _proof
  ) internal view {
    bytes32 root = contractAllowlistRoots[_contractAddress].root;

    // disabled, everyone is allowed
    if (root == bytes32(0)) {
      return;
    }
    // allow list is expired, everyone is allowed
    if (block.timestamp >= contractAllowlistRoots[_contractAddress].endTimestamp) {
      return;
    }
    require(
      _verifyProof(keccak256(abi.encodePacked(_address)), root, _proof),
      "_enforceAllowListed::Address not on allow list"
    );
  }

  /// @notice Verify a proof of inclusion
  /// @param _leaf bytes32 The leaf to verify
  /// @param _proof bytes32[] The proof to verify
  function _verifyProof(bytes32 _leaf, bytes32 _root, bytes32[] memory _proof) internal view returns (bool) {
    bytes32 currentHash = _leaf;

    for (uint256 i = 0; i < _proof.length; i++) {
      currentHash = _parentHash(currentHash, _proof[i]);
    }

    return currentHash == _root;
  }

  /// @notice Calculate the parent hash of two nodes
  /// @param a bytes32 The first node
  /// @param b bytes32 The second node
  function _parentHash(bytes32 a, bytes32 b) internal pure returns (bytes32) {
    return a <= b ? keccak256(abi.encodePacked(a, b)) : keccak256(abi.encodePacked(b, a));
  }
}
