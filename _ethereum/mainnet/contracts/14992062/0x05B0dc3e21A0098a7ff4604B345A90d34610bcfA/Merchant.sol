// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;
pragma abicoder v2;

import "./AccessControl.sol";
import "./ReentrancyGuard.sol";

import "./IMerchant.sol";
import "./IStradivarius.sol";
import "./Types.sol";

contract Merchant is IMerchant, AccessControl, ReentrancyGuard {
  bytes32 public constant OWNER_ROLE = keccak256("OWNER");

  // addresses
  address private _owner;
  address private _beneficiary;
  address private _targetNFT;

  uint256 public tier2WhitelistedAmount = 0;
  uint256 public tier3WhitelistedAmount = 0;
  uint256 public tier2RemainingAmount = 24;
  uint256 public tier3RemainingAmount = 86;
  uint256 public whitelistTier2Price = 0.24 ether;
  uint256 public whitelistTier3Price = 0.24 ether;
  uint256 public tier2Price = 0.3 ether;
  uint256 public tier3Price = 0.3 ether;
  uint256 public userCap = 3;
  uint256 public presaleStart;
  uint256 public publicSaleStart;
  uint256 public publicSaleEnd;

  mapping(address => uint256) private _tier2Whitelist;
  mapping(address => uint256) private _tier3Whitelist;
  mapping(address => uint256) private _purchased;

  event Purchased(
    address indexed minter,
    uint256 indexed tier,
    uint256 price,
    uint256 amount
  );

  constructor(
    address beneficiary_,
    address targetNFT_,
    uint256 presaleStart_,
    uint256 publicSaleStart_,
    uint256 publicSaleEnd_
  ) {
    require(beneficiary_ != address(0), "Merchant: invalid beneficiary address");
    require(targetNFT_ != address(0), "Merchant: invalid targetNFT address");
    require(block.timestamp <= presaleStart_, "Merchant: invalid presale start time");
    require(presaleStart_ < publicSaleStart_, "Merchant: invalid public sale start time");
    require(
      publicSaleEnd_ == 0 || publicSaleStart_ < publicSaleEnd_,
      "Merchant: invalid public sale end time"
    );

    _grantRole(OWNER_ROLE, msg.sender);

    _owner = msg.sender;
    _beneficiary = beneficiary_;
    _targetNFT = targetNFT_;
    presaleStart = presaleStart_;
    publicSaleStart = publicSaleStart_;
    publicSaleEnd = publicSaleEnd_;
  }

  // ============= QUERY

  function supportsInterface(bytes4 interfaceId_)
    public
    view
    override
    returns (bool)
  {
    return interfaceId_ == type(IMerchant).interfaceId || super.supportsInterface(interfaceId_);
  }

  function availableWhitelistCapOf(address user_, uint256 tier_)
    public
    view
    override
    returns (uint256)
  {
    require(tier_ == 2 || tier_ == 3, "Merchant: invalid tier");
    return tier_ == 2 ? _tier2Whitelist[user_] : _tier3Whitelist[user_];
  }

  function availableCapOf(address user_)
    public
    view
    override
    returns (uint256)
  {
    return userCap - _purchased[user_];
  }

  function getSalesInfo()
    public
    view
    override
    returns (SalesInfo memory)
  {
    return SalesInfo({
      tier2WhitelistedAmount: tier2WhitelistedAmount,
      tier3WhitelistedAmount: tier3WhitelistedAmount,
      tier2RemainingAmount: tier2RemainingAmount,
      tier3RemainingAmount: tier3RemainingAmount,
      whitelistTier2Price: whitelistTier2Price,
      whitelistTier3Price: whitelistTier3Price,
      tier2Price: tier2Price,
      tier3Price: tier3Price,
      userCap: userCap,
      presaleStart: presaleStart,
      publicSaleStart: publicSaleStart,
      publicSaleEnd: publicSaleEnd
    });
  }

  // ============= TX

  function setPublicSaleEnd(uint256 time_)
    public
    override
    onlyRole(OWNER_ROLE)
  {
    require(
      time_ == 0 || (time_ > block.timestamp && time_ != publicSaleEnd && time_ > publicSaleStart),
      "Merchant: invalid time"
    );
    publicSaleEnd = time_;
  }

  function destroy(address payable to_)
    public
    override
    onlyRole(OWNER_ROLE)
  {
    selfdestruct(to_);
  }

  function reserve(ReservePayload[] memory payload_)
    public
    override
    onlyRole(OWNER_ROLE)
  {
    for (uint256 i = 0; i < payload_.length; i++) {
      address account = payload_[i].account;
      uint256 amount = payload_[i].amount;
      uint256 tier = payload_[i].tier;

      require(tier == 2 || tier == 3, "Merchant: invalid tier");

      if (amount <= 0) continue;

      uint256 purchasedOrWhitelisted =
        _purchased[account] + _tier2Whitelist[account] + _tier3Whitelist[account];
      if (purchasedOrWhitelisted + amount > userCap) {
        if (userCap <= purchasedOrWhitelisted) {
          continue;
        }
        amount = userCap - purchasedOrWhitelisted;
      }

      if (tier == 2) {
        require(
          tier2WhitelistedAmount + amount <= tier2RemainingAmount,
          "Merchant: reserve exceeds the tier 2 remaining amount"
        );
        _tier2Whitelist[account] += amount;
        tier2WhitelistedAmount += amount;
      } else {
        require(
          tier3WhitelistedAmount + amount <= tier3RemainingAmount,
          "Merchant: reserve exceeds the tier 3 remaining amount"
        );
        _tier3Whitelist[account] += amount;
        tier3WhitelistedAmount += amount;
      }
    }
  }

  function purchase(uint256 amount_, uint256 tier_)
    public
    payable
    override
    nonReentrant
    returns (uint256[] memory)
  {
    // check tier
    require(tier_ == 2 || tier_ == 3, "Merchant: invalid tier");
    // check times
    uint256 blockTime = block.timestamp;
    require(presaleStart <= blockTime, "Merchant: sale is not open");
    require(
      publicSaleEnd == 0 || blockTime <= publicSaleEnd, // publicSaleEnd == 0 means it doesn't end
      "Merchant: sale is closed"
    );
    // check amount
    require(1 <= amount_ && amount_ <= userCap, "Merchant: invalid sale amount");
    require(_purchased[_msgSender()] + amount_ <= userCap, "Merchant: amount exceeded user cap");
    if (tier_ == 2) {
      require(amount_ <= tier2RemainingAmount, "Merchant: amount exceeded tier 2 sale cap");
    } else {
      require(amount_ <= tier3RemainingAmount, "Merchant: amount exceeded tier 3 sale cap");
    }

    if (presaleStart <= blockTime && blockTime < publicSaleStart) { // presale ends when public sale starts
      _processPresale(amount_, tier_, msg.value);
    } else {
      _processPublicSale(amount_, tier_, msg.value);
    }

    uint256[] memory tokenIds = new uint256[](amount_);
    for (uint256 i = 0; i < amount_; i++) {
      uint256 tokenId = IStradivarius(_targetNFT).mint(_msgSender(), tier_);
      tokenIds[i] = tokenId;
    }
    payable(_beneficiary).transfer(msg.value);

    emit Purchased(_msgSender(), tier_, msg.value, amount_);
    return tokenIds;
  }

  function _processPresale(uint256 amount_, uint256 tier_, uint256 msgValue_) internal {
    if (tier_ == 2) {
      require(amount_ <= _tier2Whitelist[_msgSender()], "Merchant: amount exceeded whitelist user cap");
      require(msgValue_ == whitelistTier2Price * amount_, "Merchant: invalid presale payment");
      _tier2Whitelist[_msgSender()] -= amount_;
      tier2RemainingAmount -= amount_;
      tier2WhitelistedAmount -= amount_;
    } else {
      require(amount_ <= _tier3Whitelist[_msgSender()], "Merchant: amount exceeded whitelist user cap");
      require(msgValue_ == whitelistTier3Price * amount_, "Merchant: invalid presale payment");
      _tier3Whitelist[_msgSender()] -= amount_;
      tier3RemainingAmount -= amount_;
      tier3WhitelistedAmount -= amount_;
    }

    _purchased[_msgSender()] += amount_;
  }

  function _processPublicSale(uint256 amount_, uint256 tier_, uint256 msgValue_) internal {
    if (tier_ == 2) {
      require(msgValue_ == tier2Price * amount_, "Merchant: invalid public sale payment");
      tier2RemainingAmount -= amount_;
    } else {
      require(msgValue_ == tier3Price * amount_, "Merchant: invalid public sale payment");
      tier3RemainingAmount -= amount_;
    }

    _purchased[_msgSender()] += amount_;
  }
}
