// SPDX-License-Identifier: BSD-3-Clause
pragma solidity ^0.8.6;

import "./Ownable.sol";
import "./EnumerableSet.sol";

contract Budget is Ownable {
  using EnumerableSet for EnumerableSet.AddressSet;

  /// @notice Maximum recipient count.
  uint256 public constant MAXIMUM_RECIPIENT_COUNT = 200;

  struct Expenditure {
    // Recipient address.
    address recipient;
    // Minimum balance at which budget allocation is performed.
    uint256 min;
    // Target balance at budget allocation.
    uint256 target;
  }

  /// @notice Expenditure item to address.
  mapping(address => Expenditure) public expenditures;

  /// @dev Recipients addresses list.
  EnumerableSet.AddressSet internal _recipients;

  /// @dev Withdrawal balance of recipients.
  mapping(address => uint256) public balanceOf;

  /// @notice Total withdrawal balance.
  uint256 public totalSupply;

  event ExpenditureChanged(address indexed recipient, uint256 min, uint256 target);

  event Withdrawal(address indexed recipient, uint256 amount);

  // solhint-disable-next-line no-empty-blocks
  receive() external payable {}

  /**
   * @notice Change expenditure item.
   * @param recipient Recipient address.
   * @param min Minimal balance for payment.
   * @param target Target balance.
   */
  function changeExpenditure(
    address recipient,
    uint256 min,
    uint256 target
  ) external onlyOwner {
    require(min <= target, "Budget::changeExpenditure: minimal balance should be less or equal target balance");
    require(recipient != address(0), "Budget::changeExpenditure: invalid recipient");

    expenditures[recipient] = Expenditure(recipient, min, target);
    if (target > 0) {
      _recipients.add(recipient);
      require(
        _recipients.length() <= MAXIMUM_RECIPIENT_COUNT,
        "Budget::changeExpenditure: recipient must not exceed maximum count"
      );
    } else {
      totalSupply -= balanceOf[recipient];
      balanceOf[recipient] = 0;
      _recipients.remove(recipient);
    }
    emit ExpenditureChanged(recipient, min, target);
  }

  /**
   * @notice Transfer ETH to recipient.
   * @param recipient Recipient.
   * @param amount Transfer amount.
   */
  function transferETH(address payable recipient, uint256 amount) external onlyOwner {
    require(amount > 0, "Budget::transferETH: negative or zero amount");
    require(recipient != address(0), "Budget::transferETH: invalid recipient");
    require(amount <= address(this).balance - totalSupply, "Budget::transferETH: transfer amount exceeds balance");

    recipient.transfer(amount);
  }

  /**
   * @notice Return all recipients addresses.
   * @return Recipients addresses.
   */
  function recipients() external view returns (address[] memory) {
    address[] memory result = new address[](_recipients.length());

    for (uint256 i = 0; i < _recipients.length(); i++) {
      result[i] = _recipients.at(i);
    }

    return result;
  }

  /**
   * @notice Return balance deficit of recipient.
   * @param recipient Target recipient.
   * @return Balance deficit of recipient.
   */
  function deficitTo(address recipient) public view returns (uint256) {
    require(_recipients.contains(recipient), "Budget::deficitTo: recipient not in expenditure item");

    uint256 availableBalance = recipient.balance + balanceOf[recipient];
    if (availableBalance >= expenditures[recipient].min) return 0;

    return expenditures[recipient].target - availableBalance;
  }

  /**
   * @notice Return summary balance deficit of all recipients.
   * @return Summary balance deficit of all recipients.
   */
  function deficit() public view returns (uint256) {
    uint256 result;

    for (uint256 i = 0; i < _recipients.length(); i++) {
      result += deficitTo(_recipients.at(i));
    }

    return result;
  }

  /**
   * @notice Pay ETH to all recipients with balance deficit.
   */
  function pay() external {
    for (uint256 i = 0; i < _recipients.length(); i++) {
      uint256 budgetBalance = address(this).balance - totalSupply;
      address recipient = _recipients.at(i);
      uint256 amount = deficitTo(recipient);
      if (amount == 0 || budgetBalance < amount) continue;

      balanceOf[recipient] += amount;
      totalSupply += amount;
    }
  }

  /**
   * @notice Withdraw ETH to recipient.
   */
  function withdraw() external {
    address payable recipient = payable(_msgSender());
    uint256 amount = balanceOf[recipient];
    require(amount > 0, "Budget::withdraw: transfer amount exceeds balance");

    balanceOf[recipient] = 0;
    totalSupply -= amount;
    recipient.transfer(amount);
    emit Withdrawal(recipient, amount);
  }
}
