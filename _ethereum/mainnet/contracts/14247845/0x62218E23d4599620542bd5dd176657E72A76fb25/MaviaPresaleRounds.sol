// SPDX-License-Identifier: MIT
pragma solidity 0.8.4;

import "./OwnableUpgradeable.sol";
import "./draft-EIP712Upgradeable.sol";
import "./ECDSAUpgradeable.sol";
import "./AccessControlUpgradeable.sol";
import "./ReentrancyGuardUpgradeable.sol";

import "./IMintableNFT.sol";
import "./EmergencyWithdraw.sol";
import "./MaviaBlacklist.sol";
import "./MaviaNFT.sol";

/**
 * @title Mavia Presale rounds
 *
 * @notice This contract contains logic if user want to mint NFTs in presale in public, private and whitelisted rounds
 *
 * @dev This contract contains logic of buying the NFTs in different rounds
 *
 * @author mavia.com, reviewed by King
 *
 * Copyright (c) 2021 Mavia
 */
contract MaviaPresaleRounds is
  OwnableUpgradeable,
  EmergencyWithdraw,
  MaviaBlacklist,
  EIP712Upgradeable,
  AccessControlUpgradeable,
  ReentrancyGuardUpgradeable
{
  struct Logs {
    address user;
    uint256 value;
    uint8 role;
    uint8 poolType;
    uint256 fromId;
    uint256 toId;
    uint256 timestamp;
  }

  /// @dev Validator role
  bytes32 public constant VALIDATOR_ROLE = keccak256("VALIDATOR_ROLE");

  /// @dev Buy logs
  Logs[] private _logs;

  /// @dev Sold by address
  mapping(address => mapping(uint8 => uint256)) public soldByAddress;
  /// @dev Sold by type
  mapping(uint8 => uint256) public soldByType;
  /// @dev Price against each round
  mapping(uint8 => uint256) public price;

  /// @dev Mintable NFT
  address public mintableNFT;
  uint8 public roundIndex;

  /// @dev Its limit by pool type
  mapping(uint8 => uint256) public limitByType;
  /// @dev Time to get the NFT
  uint256 public receiveWindow;
  event CollectETHs(address sender, uint256 balance);
  event ChangeMintableNFT(address mintableNFT);
  event UpdateLimitByPoolType(uint256 commonPriceLimit, uint256 rarePriceLimit, uint256 legendaryPriceLimit);
  event UpdatePrice(uint256 commonPrice, uint256 rarePrice, uint256 legendaryPrice);
  event UpdateReceiveWindow(uint256 receiveWindow);
  event UpdateRoundIndex(uint8 roundundex);

  /**
   * @dev Upgradable initializer
   * @param _pMintableNFT Address of mintable NFT
   * @param _pRoundIndex Current round index 0 -> private 1-> whitelist 2 -> public
   */
  function __MaviaPresaleRounds_init(address _pMintableNFT, uint8 _pRoundIndex) external initializer {
    __Ownable_init();
    __AccessControl_init();
    __EIP712_init("MaviaPresaleRounds", "1.0.0");
    _setupRole(DEFAULT_ADMIN_ROLE, _msgSender());
    __ReentrancyGuard_init();
    mintableNFT = _pMintableNFT;
    roundIndex = _pRoundIndex;
  }

  /*
   * @notice Return length of buy logs
   */
  function fGetLogsLength() external view returns (uint) {
    return _logs.length;
  }

  /**
   * @notice View function to get buy logs.
   * @param _pOffset: Offset for paging
   * @param _pLimit: Limit for paging
   * @return Get users, next offset and total buys
   */
  function fGetLogsPaging(uint _pOffset, uint _pLimit)
    external
    view
    returns (
      Logs[] memory,
      uint,
      uint
    )
  {
    uint totalUsers = _logs.length;
    if (_pLimit == 0) {
      _pLimit = 1;
    }

    if (_pLimit > totalUsers - _pOffset) {
      _pLimit = totalUsers - _pOffset;
    }

    Logs[] memory values = new Logs[](_pLimit);
    for (uint i = 0; i < _pLimit; i++) {
      values[i] = _logs[_pOffset + i];
    }

    return (values, _pOffset + _pLimit, totalUsers);
  }

  /**
   * @dev Owner can collect all ETH
   */
  function fCollectETHs() external onlyOwner {
    address payable sender = payable(_msgSender());

    uint256 balance = address(this).balance;
    sender.transfer(balance);

    // Emit event
    emit CollectETHs(sender, balance);
  }

  /**
   * @notice Change the address of the mintable NFT
   * @dev Only Owner can call this function
   * @param _pMintableNFT Address of mavia NFT Token
   */
  function fChangeMintableNFT(address _pMintableNFT) external onlyOwner {
    mintableNFT = _pMintableNFT;
    emit ChangeMintableNFT(_pMintableNFT);
  }

  /**
   * @notice Update price against each pool type
   * @dev Only Owner can call this function
   * @param _pCommonPrice Price of common pool
   * @param _pRarePrice Price of rare pool
   * @param _pLegendaryPrice Price of legendary pool
   */
  function fUpdatePrice(
    uint256 _pCommonPrice,
    uint256 _pRarePrice,
    uint256 _pLegendaryPrice
  ) external onlyOwner {
    price[0] = _pCommonPrice;
    price[1] = _pRarePrice;
    price[2] = _pLegendaryPrice;
    emit UpdatePrice(_pCommonPrice, _pRarePrice, _pLegendaryPrice);
  }

  /**
   * @notice Update limit by pool type
   * @dev Only Owner can call this function
   * @param _pCommonLimit Limit of common pool
   * @param _pRareLimit Limit of rare pool
   * @param _pLegendaryLimit Limit of legendary pool
   */
  function fUpdateLimitByPoolType(
    uint256 _pCommonLimit,
    uint256 _pRareLimit,
    uint256 _pLegendaryLimit
  ) external onlyOwner {
    limitByType[0] = _pCommonLimit;
    limitByType[1] = _pRareLimit;
    limitByType[2] = _pLegendaryLimit;
    emit UpdateLimitByPoolType(_pCommonLimit, _pRareLimit, _pLegendaryLimit);
  }

  /**
   * @notice Update Receive window
   * @dev Only Owner can call this function
   * @param _pReceiveWindow window to update
   */
  function fUpdateReceiveWindow(uint256 _pReceiveWindow) external onlyOwner {
    receiveWindow = _pReceiveWindow;
    emit UpdateReceiveWindow(_pReceiveWindow);
  }

  /**
   * @notice Update role index
   * @dev Only Owner can call this function
   * @param _pRoundundex Current round index 0 -> private 1-> whitelist 2 -> public
   */
  function fUpdateRoundIndex(uint8 _pRoundundex) external onlyOwner {
    roundIndex = _pRoundundex;
    emit UpdateRoundIndex(_pRoundundex);
  }

  /**
   * @dev Add blacklist to the contract
   * @param _pAddresses Array of addresses
   */
  function fAddBlacklist(address[] memory _pAddresses) external onlyOwner {
    _fAddBlacklist(_pAddresses);
  }

  /**
   * @dev Remove blacklist from the contract
   * @param _pAddresses Array of addresses
   */
  function fRemoveBlacklist(address[] memory _pAddresses) external onlyOwner {
    _fRemoveBlacklist(_pAddresses);
  }

  /**
   * @dev Buy a presale NFT
   * @param _pRole 0 -> private; 1-> whitelist; 2 -> public
   * @param _pPoolType 0 -> common; 1 -> rare; 2 -> legendary
   * @param _pFromId From NFT Id of the user
   * @param _pToId To NFT Id of the user
   * @param _pMaxAmount Maximum mintable NFT amount of the user by pool type
   * @param _pSignatureTime Signature time of the user
   * @param _pSignature Byte value
   * Required Statements
   * - MPR:buy01 Pool limit is reached
   * - MPR:buy02 Max amount is reached
   * - MPR:buy03 Invalid time to buy
   * - MPR:buy04 Invalid role
   * - MPR:buy05 Sender is in blacklist
   * - MPR:buy06 Data is not correct
   * - MPR:buy07 Invalid price
   */
  function fBuy(
    uint8 _pRole,
    uint8 _pPoolType,
    uint256 _pFromId,
    uint256 _pToId,
    uint256 _pMaxAmount,
    uint256 _pSignatureTime,
    bytes calldata _pSignature
  ) external payable nonReentrant {
    uint256 value_ = msg.value;
    address sender_ = _msgSender();
    uint256 amount_ = _pToId - _pFromId + 1;

    require(soldByType[_pPoolType] + amount_ <= limitByType[_pPoolType], "MPR:buy01");
    require(soldByAddress[sender_][_pPoolType] + amount_ <= _pMaxAmount, "MPR:buy02");
    require(block.timestamp <= _pSignatureTime + receiveWindow, "MPR:buy03");
    require(_pRole <= roundIndex, "MPR:buy04");
    require(!blacklist[sender_], "MPR:buy05");
    require(
      _fVerify(_fHash(sender_, _pRole, _pPoolType, _pFromId, _pToId, _pMaxAmount, _pSignatureTime), _pSignature),
      "MPR:buy06"
    );

    // Mint NFT
    IMintableNFT(mintableNFT).fBulkMint(sender_, _pFromId, _pToId);
    soldByType[_pPoolType] += amount_;
    soldByAddress[sender_][_pPoolType] += amount_;

    uint256 prices_;
    if (_pRole > 0) {
      prices_ = price[_pPoolType] * amount_;
    }
    if (value_ != prices_) {
      if (value_ < prices_) revert("MPR:buy07");
      else {
        // Refund
        payable(sender_).transfer(value_ - prices_);
      }
    }
    _logs.push(Logs(sender_, value_, _pRole, _pPoolType, _pFromId, _pToId, block.timestamp));
  }

  /**
   * @notice Calculate hash
   * @dev This function is called in redeem functions
   * @param _pWallet User Address
   * @param _pRole 0 -> private 1-> whitelist 2 -> public
   * @param _pPoolType 0 -> common 1 -> rare -> legendary
   * @param _pFromId From NFT Id of the user
   * @param _pToId To NFT Id of the user
   * @param _pMaxAmount Maximum mintable NFT amount of the user by pool type
   * @param _pSignatureTime Signature time of the user
   */
  function _fHash(
    address _pWallet,
    uint8 _pRole,
    uint8 _pPoolType,
    uint256 _pFromId,
    uint256 _pToId,
    uint256 _pMaxAmount,
    uint256 _pSignatureTime
  ) private view returns (bytes32) {
    return
      _hashTypedDataV4(
        keccak256(
          abi.encode(
            keccak256(
              "MaviaPresaleRounds(address _pWallet,uint8 _pRole,uint8 _pPoolType,uint256 _pFromId,uint256 _pToId,uint256 _pMaxAmount,uint256 _pSignatureTime)"
            ),
            _pWallet,
            _pRole,
            _pPoolType,
            _pFromId,
            _pToId,
            _pMaxAmount,
            _pSignatureTime
          )
        )
      );
  }

  /**
   * @dev verify signature
   * @param _pDigest Bytes32 digest
   * @param _pSignature Bytes signature
   */
  function _fVerify(bytes32 _pDigest, bytes memory _pSignature) internal view returns (bool) {
    return hasRole(VALIDATOR_ROLE, ECDSAUpgradeable.recover(_pDigest, _pSignature));
  }
}
