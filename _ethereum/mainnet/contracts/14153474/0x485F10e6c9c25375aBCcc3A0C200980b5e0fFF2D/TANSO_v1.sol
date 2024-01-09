// SPDX-License-Identifier: AGPL-3.0-or-later

pragma solidity ^0.8.0;

import "./OwnableUpgradeable.sol";
import "./Initializable.sol";
import "./UUPSUpgradeable.sol";
import "./ERC20CappedUpgradeable.sol";

import "./TANSOSafeMath_v1.sol";

/**
 * @title TANSO token, the governance token of [TanSoDAO](https://tansodao.io/).
 *
 * This contract is in charge of the basic ERC20 token tasks and carbon credit transactions on the TanSoDAO marketplace
 * (calculating and transferring the fee etc.).
 */
contract TANSO_v1 is Initializable, ERC20CappedUpgradeable, OwnableUpgradeable, UUPSUpgradeable {
  using TANSOSafeMath_v1 for uint256;

  /**
   * @dev The list of the token holder addresses.
   */
  address[] private _tokenHolderAddresses;

  /**
   * @dev For tracking the list of the token holder addresses.
   */
  struct TokenHolderProperty {
    bool isInAddressArray;
    uint256 addressArrayIndex;
  }
  mapping(address => TokenHolderProperty) private _tokenHolderProperties;

  /**
   * @dev The basic staking manager contract's address.
   */
  address private _basicStakingManagerAddress;

  /**
   * @dev The fee staking manager contract's address.
   */
  address private _feeStakingManagerAddress;

  /**
   * @dev The percentage of "fee / price".
   */
  uint256 private _feePerPricePercentage;

  /**
   * @dev The percentage of "fee staking / fee".
   */
  uint256 private _feeStakingPerFeePercentage;

  /**
   * @dev The mutex lock flag for transferring.
   */
  bool private _isTransferMutexLocked;

  /**
   * @dev Emitted when the buyer purchases an item from the seller with the item price, and the part of the fee is
   * transferred to the fee recipient.
   *
   * @param buyer The buyer of the item.
   * @param seller The seller of the item.
   * @param price The price of the item.
   * @param feeRecipient The recipient of the part of the fee.
   */
  event ItemPurchase(address indexed buyer, address indexed seller, uint256 price, address indexed feeRecipient);

  /**
   * The default constructor of this contract that is inherited from OpenZeppelin Upgradeable Contracts.
   *
   * Initializes the list of the token holder addresses with the following order:
   *   1st: this token contract's address
   *   2nd: the basic staking manager contract's address
   *   3rd: the fee staking manager contract's address
   *   4th: the owner's address
   * Then mints the whole capped amount of the tokens to the owner.
   *
   * @param basicStakingManagerAddress_ The basic staking manager contract's address.
   * @param feeStakingManagerAddress_ The fee staking manager contract's address.
   */
  function initialize(address basicStakingManagerAddress_, address feeStakingManagerAddress_) initializer public {
    // Initilizes all the parent contracts.
    __ERC20_init("TANSO", "TNS");
    __ERC20Capped_init(1000000000 * (10 ** decimals()));
    __Ownable_init();
    __UUPSUpgradeable_init();

    // Reserves the token contract's address as the 1st one in the list of the token holder addresses.
    _appendTokenHolderAddress(address(this));
    require(_tokenHolderAddresses[0] == address(this));
    require(_tokenHolderProperties[address(this)].addressArrayIndex == 0);

    // Reserves the basic staking manager contract's address as the 2nd one in the list of the token holder addresses,
    // and then sets the basic staking manager contract's address.
    _appendTokenHolderAddress(basicStakingManagerAddress_);
    require(_tokenHolderAddresses[1] == basicStakingManagerAddress_);
    require(_tokenHolderProperties[basicStakingManagerAddress_].addressArrayIndex == 1);
    _basicStakingManagerAddress = basicStakingManagerAddress_;

    // Reserves the fee staking manager contract's address as the 3rd one in the list of the token holder addresses,
    // and then sets the fee staking manager contract's address.
    _appendTokenHolderAddress(feeStakingManagerAddress_);
    require(_tokenHolderAddresses[2] == feeStakingManagerAddress_);
    require(_tokenHolderProperties[feeStakingManagerAddress_].addressArrayIndex == 2);
    _feeStakingManagerAddress = feeStakingManagerAddress_;

    // Reserves the owner's address as the 4th one in the list of the token holder addresses,
    // and then mints the whole capped amount of the tokens to the owner.
    _appendTokenHolderAddress(owner());
    require(_tokenHolderAddresses[3] == owner());
    require(_tokenHolderProperties[owner()].addressArrayIndex == 3);
    _mint(owner(), cap());

    // Sets the parameters.
    _feePerPricePercentage = 2;  // [%]
    _feeStakingPerFeePercentage = 50;  // [%]
    _isTransferMutexLocked = false;
  }

  /**
   * @custom:oz-upgrades-unsafe-allow constructor
   */
  constructor() initializer {}

  /**
   * @dev See {UUPSUpgradeable-_authorizeUpgrade}.
   *
   * Note that this function is callable only by the owner.
   */
  function _authorizeUpgrade(address) onlyOwner internal override {}
 
  /**
   * @return The list of the token holder addresses.
   */
  function tokenHolderAddresses() external view returns (address[] memory) {
    return _tokenHolderAddresses;
  }

  /**
   * @return The basic staking manager contract's address.
   */
  function basicStakingManagerAddress() external view returns (address) {
    return _basicStakingManagerAddress;
  }

  /**
   * @return The fee staking manager contract's address.
   */
  function feeStakingManagerAddress() external view returns (address) {
    return _feeStakingManagerAddress;
  }

  /**
   * @return The percentage of "fee / price".
   */
  function feePerPricePercentage() external view returns (uint256) {
    return _feePerPricePercentage;
  }

  /**
   * @return The percentage of "fee staking / fee".
   */
  function feeStakingPerFeePercentage() external view returns (uint256) {
    return _feeStakingPerFeePercentage;
  }

  /**
   * @return The mutex lock flag for transferring.
   */
  function isTransferMutexLocked() external view returns (bool) {
    return _isTransferMutexLocked;
  }

  /**
   * Sets the basic staking manager contract's address.
   *
   * Note that this function is callable only by the owner.
   *
   * @param basicStakingManagerAddress_ The basic staking manager contract's address.
   */
  function setBasicStakingManagerAddress(address basicStakingManagerAddress_) onlyOwner external {
    require(basicStakingManagerAddress_ != address(0), "TANSO: The new address must not be zero address.");
    _basicStakingManagerAddress = basicStakingManagerAddress_;
  }

  /**
   * Sets the fee staking manager contract's address.
   *
   * Note that this function is callable only by the owner.
   *
   * @param feeStakingManagerAddress_ The fee staking manager contract's address.
   */
  function setFeeStakingManagerAddress(address feeStakingManagerAddress_) onlyOwner external {
    require(feeStakingManagerAddress_ != address(0), "TANSO: The new address must not be zero address.");
    _feeStakingManagerAddress = feeStakingManagerAddress_;
  }

  /**
   * Sets the percentage of "fee / price".
   *
   * Note that this function is callable only by the owner.
   *
   * @param feePerPricePercentage_ The percentage of "fee / price".
   */
  function setFeePerPricePercentage(uint256 feePerPricePercentage_) onlyOwner external {
    require(feePerPricePercentage_ <= 100, "TANSO: The new percentage must be less than or equal 100%.");
    _feePerPricePercentage = feePerPricePercentage_;
  }

  /**
   * Sets the mutex lock flag for transferring.
   *
   * Note that this function is callable only by the owner.
   *
   * @param isTransferMutexLocked_ The mutex lock flag for transferring.
   */
  function setIsTransferMutexLocked(bool isTransferMutexLocked_) onlyOwner external {
    _isTransferMutexLocked = isTransferMutexLocked_;
  }

  /**
   * Sets the fee percentage of "fee staking / fee".
   *
   * Note that this function is callable only by the owner.
   *
   * @param feeStakingPerFeePercentage_ The percentage of "fee staking / fee".
   */
  function setFeeStakingPerFeePercentage(uint256 feeStakingPerFeePercentage_) onlyOwner external {
    require(feeStakingPerFeePercentage_ <= 100, "TANSO: The new percentage must be less than or equal 100%.");
    _feeStakingPerFeePercentage = feeStakingPerFeePercentage_;
  }

  /**
   * Purchases an item from the seller with the item price. Calculates the fee, and transfers the part of the fee
   * to the fee recipient and the remaining fee to the fee staking manager contract.
   *
   * Emits a {ItemPurchase} event.
   *
   * @param seller The seller of the item.
   * @param price The price of the item.
   * @param feeRecipient The recipient of the part of the fee.
   */
  function purchaseItem(address seller, uint256 price, address feeRecipient) external {
    require(_isTransferMutexLocked == false, "TANSO: Transferring is mutex locked.");

    require(seller != address(0), "TANSO: The seller's address must not be zero address.");
    require(seller != _msgSender(), "TANSO: The seller's address must not be the msg.sender's address.");

    require(price <= balanceOf(_msgSender()), "TANSO: The msg.sender's balace is insufficient.");

    require(feeRecipient != address(0), "TANSO: The fee recipient's address must not be zero address.");
    require(feeRecipient != _msgSender(), "TANSO: The fee recipient's address must not be the msg.sender's address.");

    require(_feePerPricePercentage <= 100, "TANSO: fee / price percentage must be less than or equal 100%.");
    require(_feeStakingPerFeePercentage <= 100, "TANSO: fee staking / fee percentage must be less than or equal 100%.");

    bool isCalculationSuccess = false;
    uint256 feeAmount = 0;
    uint256 feeStakingAmount = 0;

    // feeAmount = price * _feePerPricePercentage / 100
    (isCalculationSuccess, feeAmount) = price.tryAmulBdivC(_feePerPricePercentage, 100);
    require(isCalculationSuccess, "TANSO: Failed to calculate the fee amount.");
    require(feeAmount <= price, "TANSO: The fee amount must be less than or equal the item price.");

    // feeStakingAmount = feeAmount * _feeStakingPerFeePercentage / 100
    (isCalculationSuccess, feeStakingAmount) = feeAmount.tryAmulBdivC(_feeStakingPerFeePercentage, 100);
    require(isCalculationSuccess, "TANSO: Failed to calculate the fee staking amount.");
    require(feeStakingAmount <= feeAmount, "TANSO: The fee staking amount must be less than or equal the fee amount.");

    // If the seller and the fee recipient is different, then transfers three times:
    //   1. to the seller
    //   2. to the fee recipient
    //   3. to the fee staking manager contract
    // Else, transfers just twice to save the Ethereum gas (because the seller and the fee recipient is the same):
    //   1. to the seller (the fee recipient as well)
    //   2. to the fee staking manager contract
    if (seller != feeRecipient) {
      if (0 < price - feeAmount) {
        transfer(seller, price - feeAmount);
      }
      if (0 < feeAmount - feeStakingAmount) {
        transfer(feeRecipient, feeAmount - feeStakingAmount);
      }
      if (0 < feeStakingAmount) {
        transfer(_feeStakingManagerAddress, feeStakingAmount);
      }
    } else {
      if (0 < price - feeStakingAmount) {
        transfer(seller, price - feeStakingAmount);
      }
      if (0 < feeStakingAmount) {
        transfer(_feeStakingManagerAddress, feeStakingAmount);
      }
    }

    emit ItemPurchase(_msgSender(), seller, price, feeRecipient);
  }

  /**
   * Before any transfer of tokens (including minting and burning), asserts that:
   *   * the transfer is not mutex locked
   *   * the balance of the owner is not locked up if the sender is the owner
   * Then appends the recipient address to the list of the token holder addresses if it's not appended yet.
   *
   * @param from The sender of the transferred tokens.
   * @param to The recipient of the transferred tokens.
   * @param amount The amount of the transferred tokens.
   */
  function _beforeTokenTransfer(address from, address to, uint256 amount) internal virtual override {
    super._beforeTokenTransfer(from, to, amount);
    require(_isTransferMutexLocked == false, "TANSO: Transferring is mutex locked.");
    if (from == owner()) {
      require(_isBalanceOfOwnerLockedUp(amount) == false, "TANSO: The owner's balace is locked up.");
    }
    _appendTokenHolderAddress(to);
  }

  /**
   * Appends a token holder address to the list of the token holder addresses if it's not appended yet.
   *
   * @param tokenHolderAddress The token holder's address to be appended. In most cases, it's recipient address.
   */
  function _appendTokenHolderAddress(address tokenHolderAddress) private {
    if (_tokenHolderProperties[tokenHolderAddress].isInAddressArray == false) {
      _tokenHolderProperties[tokenHolderAddress].isInAddressArray = true;
      _tokenHolderProperties[tokenHolderAddress].addressArrayIndex = _tokenHolderAddresses.length;
      _tokenHolderAddresses.push(tokenHolderAddress);
    }
  }

  /**
   * Checks that whether the balance of the owner is still locked up or not.
   *
   * The lock up schedule is shown below. The balance of the owner cannot be lower than:
   *   * 30% of the token cap until Jan. 1st 2023 00:00:00 UTC
   *   * 25% of the token cap until Jan. 1st 2024 00:00:00 UTC
   *   * 20% of the token cap until Jan. 1st 2025 00:00:00 UTC
   *   * 15% of the token cap until Jan. 1st 2026 00:00:00 UTC
   *   * 10% of the token cap until Jan. 1st 2027 00:00:00 UTC
   *   *  5% of the token cap until Jan. 1st 2028 00:00:00 UTC
   *
   * Note that the timing may differ within few seconds due to the characteristic of "block.timestamp".
   * However, differing within few seconds is not a big problem for the purpose of the lock up.
   *
   * @param amount The amount of the transferred tokens from the owner.
   * @return True if the owner's balance is still locked up, false if the the owner's balance is free (not locked up).
   */
  function _isBalanceOfOwnerLockedUp(uint256 amount) private view returns (bool) {
    require(amount <= balanceOf(owner()), "TANSO: The owner's balace is insufficient.");

    uint256 lockUpTimestamp1 = 1672531200;  // [s] Unix timestamp: Jan. 1st 2023 00:00:00 UTC
    uint256 lockUpAmount1 = 300000000 * (10 ** decimals());  // 30% of the token cap.

    uint256 lockUpTimestamp2 = 1704067200;  // [s] Unix timestamp: Jan. 1st 2024 00:00:00 UTC
    uint256 lockUpAmount2 = 250000000 * (10 ** decimals());  // 25% of the token cap.

    uint256 lockUpTimestamp3 = 1735689600;  // [s] Unix timestamp: Jan. 1st 2025 00:00:00 UTC
    uint256 lockUpAmount3 = 200000000 * (10 ** decimals());  // 20% of the token cap.

    uint256 lockUpTimestamp4 = 1767225600;  // [s] Unix timestamp: Jan. 1st 2026 00:00:00 UTC
    uint256 lockUpAmount4 = 150000000 * (10 ** decimals());  // 15% of the token cap.

    uint256 lockUpTimestamp5 = 1798761600;  // [s] Unix timestamp: Jan. 1st 2027 00:00:00 UTC
    uint256 lockUpAmount5 = 100000000 * (10 ** decimals());  // 10% of the token cap.

    uint256 lockUpTimestamp6 = 1830297600;  // [s] Unix timestamp: Jan. 1st 2028 00:00:00 UTC
    uint256 lockUpAmount6 = 50000000 * (10 ** decimals());  // 5% of the token cap.

    uint256 ownerBalanceAfterTransfer = balanceOf(owner()) - amount;
    if (block.timestamp <= lockUpTimestamp1) {
      return (ownerBalanceAfterTransfer < lockUpAmount1);
    } else if (lockUpTimestamp1 < block.timestamp && block.timestamp <= lockUpTimestamp2) {
      return (ownerBalanceAfterTransfer < lockUpAmount2);
    } else if (lockUpTimestamp2 < block.timestamp && block.timestamp <= lockUpTimestamp3) {
      return (ownerBalanceAfterTransfer < lockUpAmount3);
    } else if (lockUpTimestamp3 < block.timestamp && block.timestamp <= lockUpTimestamp4) {
      return (ownerBalanceAfterTransfer < lockUpAmount4);
    } else if (lockUpTimestamp4 < block.timestamp && block.timestamp <= lockUpTimestamp5) {
      return (ownerBalanceAfterTransfer < lockUpAmount5);
    } else if (lockUpTimestamp5 < block.timestamp && block.timestamp <= lockUpTimestamp6) {
      return (ownerBalanceAfterTransfer < lockUpAmount6);
    }

    // If the current timestamp is after Jan. 1st 2028 00:00:00 UTC, then there is no lock up anymore.
    return false;
  }
}
