//  _________  _________   _______  __________
// /__     __\|    _____) /   .   \/    _____/
//    |___|   |___|\____\/___/ \___\________\

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.10;

import "./OwnableUpgradeable.sol";
import "./ReentrancyGuardUpgradeable.sol";
import "./ERC1155SupplyUpgradeable.sol";
import "./StringsUpgradeable.sol";

import "./ICREDIT.sol";

error MintNotActive();
error NonExistentToken();
error AmountExceedsSupply();
error InsufficientPayment();
error PaymentNotApproved();
error OnlyExternallyOwnedAccountsAllowed();

contract TRACAssets is ERC1155SupplyUpgradeable, OwnableUpgradeable, ReentrancyGuardUpgradeable {

  bool public active;

  string public constant name = "TRAC Assets";
  string public constant symbol = "ASSETS";

  uint8 private constant LOCKER_ID = 0;
  uint8 private constant BACKPACK_ID = 1;
  uint16 private constant LOCKER_SUPPLY = 888;
  uint16 private constant BACKPACK_SUPPLY = 4888;
  uint256 private constant LOCKER_COST = 2888 ether;
  uint256 private constant BACKPACK_COST = 488 ether;

  ICREDIT private _credit;

  mapping(address => mapping(uint8 => uint48[])) private _purchaseDates;
  uint48 private constant PURCHASE_FALLBACK_DATE = 1652252400;

  event MintLocker(address account);
  event MintBackpack(address account);

  function initialize(address credit_, string memory uri_) public initializer {
    __ERC1155Supply_init();
    __Ownable_init_unchained();
    __ReentrancyGuard_init_unchained();
    __ERC1155_init_unchained(uri_);
    _credit = ICREDIT(credit_);
  }

  function toggleActive() external onlyOwner {
    active = !active;
  }

  function mintLocker() external nonReentrant onlyEOA {
    if (!active && msg.sender != owner())            revert MintNotActive();
    if (totalSupply(LOCKER_ID) + 1 > LOCKER_SUPPLY)  revert AmountExceedsSupply();
    if (_credit.balanceOf(msg.sender) < LOCKER_COST) revert InsufficientPayment();

    emit MintLocker(msg.sender);

    _credit.burn(msg.sender, LOCKER_COST);
    _mint(msg.sender, LOCKER_ID, 1, "");
  }

  function mintBackpack() external nonReentrant onlyEOA {
    if (!active && msg.sender != owner())               revert MintNotActive();
    if (totalSupply(BACKPACK_ID) + 1 > BACKPACK_SUPPLY) revert AmountExceedsSupply();
    if (_credit.balanceOf(msg.sender) < BACKPACK_COST)  revert InsufficientPayment();

    emit MintBackpack(msg.sender);

    _credit.burn(msg.sender, BACKPACK_COST);
    _mint(msg.sender, BACKPACK_ID, 1, "");
  }

  function uri(uint256 id) public view override returns (string memory) {
    if (!exists(id)) revert NonExistentToken();

    return string(abi.encodePacked(super.uri(0), StringsUpgradeable.toString(id)));
  }

  struct Purchases { uint48[] backpacks; uint48[] lockers; }
  function getPurchases(address account) external view returns (Purchases memory purchases) {
    uint256 lockers = balanceOf(account, LOCKER_ID);
    uint256 backpacks = balanceOf(account, BACKPACK_ID);

    purchases = Purchases({
      backpacks: new uint48[](backpacks),
      lockers: new uint48[](lockers)
    });

    uint256 i = 0;

    // Locker dates
    uint256 existingDates = _purchaseDates[account][LOCKER_ID].length;
    uint256 fallbackDates = lockers - existingDates;
    for (; i < fallbackDates; ++i) {
      purchases.lockers[i] = PURCHASE_FALLBACK_DATE;
    }
    for (; i < lockers; ++i) {
      purchases.lockers[i] = _purchaseDates[account][LOCKER_ID][i - fallbackDates];
    }

    // Backpack dates
    existingDates = _purchaseDates[account][BACKPACK_ID].length;
    fallbackDates = backpacks - existingDates;
    for (i = 0; i < fallbackDates; ++i) {
      purchases.backpacks[i] = PURCHASE_FALLBACK_DATE;
    }
    for (; i < backpacks; ++i) {
      purchases.backpacks[i] = _purchaseDates[account][BACKPACK_ID][i - fallbackDates];
    }
  }

  function _beforeTokenTransfer(
    address operator,
    address from,
    address to,
    uint256[] memory ids,
    uint256[] memory amounts,
    bytes memory data
  ) internal virtual override {
    super._beforeTokenTransfer(operator, from, to, ids, amounts, data);

    uint48 time = uint48(block.timestamp);
    if (from == address(0)) {      // mint
      for (uint256 i = 0; i < ids.length; ++i) {
        _purchaseDates[to][uint8(ids[i])].push(time);
      }
    } else if (to == address(0)) { // burn
      for (uint256 i = 0; i < ids.length; ++i) {
        if (_purchaseDates[from][uint8(ids[i])].length > 0)
          _purchaseDates[from][uint8(ids[i])].pop();
      }
    } else {                       // transfer
      for (uint256 i = 0; i < ids.length; ++i) {
        if (_purchaseDates[from][uint8(ids[i])].length > 0)
          _purchaseDates[from][uint8(ids[i])].pop();
        _purchaseDates[to][uint8(ids[i])].push(time);
      }
    }
  }

  function totalSupply() public view returns (uint256) {
    return totalSupply(LOCKER_ID) + totalSupply(BACKPACK_ID);
  }

  modifier onlyEOA() {
    if (tx.origin != msg.sender) revert OnlyExternallyOwnedAccountsAllowed();
    _;
  }
}