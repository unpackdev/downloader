// SPDX-License-Identifier: MIT
pragma solidity ^0.8.21;

import "./Ownable.sol";
import "./ERC20Votes.sol";
import "./IERC165.sol";
import "./SafeERC20.sol";

import "./OFTV2.sol";

import "./IBuyTaxReceiver.sol";
import "./IAntiMevStrategy.sol";

contract BenCoinV2 is OFTV2, ERC20Votes {
  using SafeERC20 for IERC20;

  event SetTax(uint buyTax, uint sellTax, bool isTaxing);
  event SetBuyTaxReceiver(address buyTaxReceiver);
  event SetTaxableContract(address taxableContract, bool isTaxable);
  event SetTaxWhitelist(address whitelist, bool isWhitelisted);
  event SetIsAntiMEV(bool isAntiMEV);
  event SetIsTransferBlacklisting(bool isBlacklisting);
  event SetTransferBlacklist(address blacklist, bool isBlacklisted);

  error OnlyMigrator();
  error MaxTaxExceeded();
  error BothAddressesAreContracts();
  error TransferBlacklisted(address);
  error InvalidBuyTaxReceiver();
  error InvalidArrayLength();
  error AlreadyInitialized();

  address private migrator; // Only used on Ethereum for the initial migration from BenV1 to BenV2
  uint16 private buyTax;
  uint16 private sellTax;
  bool private isTaxingEnabled;
  bool private isAntiMEV;
  bool private isBlacklisting;
  bool private isInitialized;
  // Using 1 & 2 instead of 0 to save gas when resetting
  uint8 private taxFlag = NOT_TAXING;
  address private buyTaxReceiver;
  mapping(address contractAddress => bool isTaxable) private taxableContracts;
  mapping(address whitelist => bool isWhitelisted) private taxWhitelist; // For certain addresses to be exempt from tax like exchanges

  mapping(address blacklist => bool isBlacklisted) private transferBlacklist;
  IAntiMevStrategy private antiMEVStrategy;

  uint256 private constant MAX_TAX = 10; // 10%
  uint8 private constant NOT_TAXING = 1;
  uint8 private constant TAXING = 2;
  uint256 private constant FEE_DENOMINATOR = 10000;
  uint8 private constant SHARED_DECIMALS = 8;

  constructor() OFTV2("BEN TEST", "BEN TEST", SHARED_DECIMALS) ERC20Permit("BEN TEST") {}

  function initialize(
    address _lzEndpoint,
    address _buyTaxReceiver,
    address _antiMEVStrategy,
    address _migrator,
    uint256 _buyTax,
    uint256 _sellTax,
    bool _isTaxingEnabled,
    bool _isAntiMEV,
    bool _isTransferBlacklisting
  ) external notInitialized onlyOwner {
    __OFTV2_init(_lzEndpoint);

    _setTax(_buyTax, _sellTax, _isTaxingEnabled);
    _setIsAntiMEV(_isAntiMEV);
    _setIsTransferBlacklisting(_isTransferBlacklisting);
    _setBuyTaxReceiver(_buyTaxReceiver);
    antiMEVStrategy = IAntiMevStrategy(_antiMEVStrategy);
    migrator = _migrator;
    isInitialized = true;
  }

  modifier notInitialized() {
    if (isInitialized) {
      revert AlreadyInitialized();
    }
    _;
  }

  modifier antiMEV(
    address _from,
    address _to,
    uint256 _amount
  ) {
    if (isAntiMEV) {
      antiMEVStrategy.onTransfer(_from, _to, _amount, taxFlag == TAXING);
    }
    _;
  }

  modifier onlyMigrator() {
    if (_msgSender() != migrator) {
      revert OnlyMigrator();
    }
    _;
  }

  function burn(uint256 _amount) external {
    _burn(_msgSender(), _amount);
  }

  function burnFrom(address _account, uint256 _amount) external {
    _spendAllowance(_account, _msgSender(), _amount);
    _burn(_account, _amount);
  }

  function _mint(address _account, uint256 _amount) internal override(ERC20, ERC20Votes) {
    super._mint(_account, _amount);
  }

  function _burn(address _account, uint256 _amount) internal override(ERC20, ERC20Votes) {
    super._burn(_account, _amount);
  }

  function _beforeTokenTransfer(
    address _from,
    address _to,
    uint256 _amount
  ) internal override(ERC20) antiMEV(_from, _to, _amount) {
    if (isBlacklisting && transferBlacklist[_from]) {
      revert TransferBlacklisted(_from);
    }

    ERC20._beforeTokenTransfer(_from, _to, _amount);

    if (isTaxingEnabled && taxFlag == NOT_TAXING && taxableContracts[_to] && !taxWhitelist[_from]) {
      taxFlag = TAXING; // Set this so no further taxing is done
      IBuyTaxReceiver(buyTaxReceiver).swapCallback();
      taxFlag = NOT_TAXING;
    }
  }

  function _afterTokenTransfer(address _from, address _to, uint256 _amount) internal override(ERC20, ERC20Votes) {
    ERC20Votes._afterTokenTransfer(_from, _to, _amount);

    // Take a fee if it is a taxable contract
    if (isTaxingEnabled && taxFlag == NOT_TAXING) {
      // If it's a buy then we take from who-ever it is sent to and send to the contract for selling back to ETH
      if (taxableContracts[_from] && !taxWhitelist[_to]) {
        uint256 fee = _calcTax(buyTax, _amount);
        // Transfers from the receiver to the buy tax receiver for later selling
        taxFlag = TAXING;
        _transfer(_to, buyTaxReceiver, fee);
        taxFlag = NOT_TAXING;
      } else if (taxableContracts[_to] && !taxWhitelist[_from]) {
        uint256 fee = _calcTax(sellTax, _amount);
        // Transfers from taxable contracts (like LPs) to the admin directly
        taxFlag = TAXING;
        _transfer(_to, owner(), fee);
        taxFlag = NOT_TAXING;
      }
    }
  }

  function _calcTax(uint256 _tax, uint256 _amount) private pure returns (uint256 fees) {
    fees = (_amount * _tax) / FEE_DENOMINATOR;
  }

  function _setTax(uint256 _buyTax, uint256 _sellTax, bool _isTaxingEnabled) internal {
    // Cannot set tax higher than MAX_TAX (10%)
    if ((_buyTax * MAX_TAX > FEE_DENOMINATOR) || (_sellTax * MAX_TAX > FEE_DENOMINATOR)) {
      revert MaxTaxExceeded();
    }

    buyTax = uint16(_buyTax);
    sellTax = uint16(_sellTax);
    isTaxingEnabled = _isTaxingEnabled;

    emit SetTax(_buyTax, _sellTax, _isTaxingEnabled);
  }

  function _setIsAntiMEV(bool _isAntiMEV) private {
    isAntiMEV = _isAntiMEV;
    emit SetIsAntiMEV(_isAntiMEV);
  }

  function _setIsTransferBlacklisting(bool _isBlacklisting) private {
    isBlacklisting = _isBlacklisting;
    emit SetIsTransferBlacklisting(_isBlacklisting);
  }

  function _setBuyTaxReceiver(address _buyTaxReceiver) private {
    if (!IERC165(_buyTaxReceiver).supportsInterface(type(IBuyTaxReceiver).interfaceId)) {
      revert InvalidBuyTaxReceiver();
    }
    buyTaxReceiver = _buyTaxReceiver;
    emit SetBuyTaxReceiver(_buyTaxReceiver);
  }

  function setTax(uint256 _buyTax, uint256 _sellTax, bool _isTaxingEnabled) external onlyOwner {
    _setTax(_buyTax, _sellTax, _isTaxingEnabled);
  }

  function setIsAntiMEV(bool _isAntiMEV) external onlyOwner {
    _setIsAntiMEV(_isAntiMEV);
  }

  function recoverToken(IERC20 _token, uint _amount) external onlyOwner {
    _token.safeTransfer(owner(), _amount);
  }

  function setTaxableContract(address _taxableContract, bool _isTaxable) external onlyOwner {
    taxableContracts[_taxableContract] = _isTaxable;
    emit SetTaxableContract(_taxableContract, _isTaxable);
  }

  function setTaxWhitelist(address _whitelist, bool _isWhitelisted) external onlyOwner {
    taxWhitelist[_whitelist] = _isWhitelisted;
    emit SetTaxWhitelist(_whitelist, _isWhitelisted);
  }

  function setBuyTaxReceiver(address _buyTaxReceiver) external onlyOwner {
    _setBuyTaxReceiver(_buyTaxReceiver);
  }

  function setIsTransferBlacklisting(bool _isBlacklisting) external onlyOwner {
    _setIsTransferBlacklisting(_isBlacklisting);
  }

  function setTransferBlacklist(address _blacklist, bool _isBlacklisted) external onlyOwner {
    transferBlacklist[_blacklist] = _isBlacklisted;
    emit SetTransferBlacklist(_blacklist, _isBlacklisted);
  }

  function setAntiMevStrategy(IAntiMevStrategy _antiMEVStrategy) external onlyOwner {
    antiMEVStrategy = _antiMEVStrategy;
  }

  // Only used on Ethereum for the initial migration from BenV1 to BenV2
  function mint(address _to, uint _amount) external onlyMigrator {
    _mint(_to, _amount);
  }
}
