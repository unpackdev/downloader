// SPDX-License-Identifier: BSD-3-Clause
pragma solidity ^0.8.6;

import "./Ownable.sol";
import "./EnumerableSet.sol";

contract Balance is Ownable {
  using EnumerableSet for EnumerableSet.AddressSet;

  /// @notice Maximum inspector count.
  uint256 public constant MAXIMUM_INSPECTOR_COUNT = 100;

  /// @notice Maximum consumer count.
  uint256 public constant MAXIMUM_CONSUMER_COUNT = 100;

  /// @notice Maximum accept or reject claims by one call.
  uint256 public constant MAXIMUM_CLAIM_PACKAGE = 500;

  /// @notice Treasury contract
  address payable public treasury;

  /// @dev Inspectors list.
  EnumerableSet.AddressSet internal _inspectors;

  /// @dev Consumers list.
  EnumerableSet.AddressSet internal _consumers;

  /// @notice Account balance.
  mapping(address => uint256) public balanceOf;

  /// @notice Account claim.
  mapping(address => uint256) public claimOf;

  /// @notice Possible statuses that a bill may be in.
  enum BillStatus {
    Pending,
    Accepted,
    Rejected
  }

  struct Bill {
    // Identificator.
    uint256 id;
    // Claimant.
    address claimant;
    // Target account.
    address account;
    // Claim gas fee.
    uint256 gasFee;
    // Claim protocol fee.
    uint256 protocolFee;
    // Current bill status.
    BillStatus status;
  }

  /// @notice Bills.
  mapping(uint256 => Bill) public bills;

  /// @notice Bill count.
  uint256 public billCount;

  event TreasuryChanged(address indexed treasury);

  event InspectorAdded(address indexed inspector);

  event InspectorRemoved(address indexed inspector);

  event ConsumerAdded(address indexed consumer);

  event ConsumerRemoved(address indexed consumer);

  event Deposit(address indexed recipient, uint256 amount);

  event Refund(address indexed recipient, uint256 amount);

  event Claim(address indexed account, uint256 indexed bill, string description);

  event AcceptClaim(uint256 indexed bill);

  event RejectClaim(uint256 indexed bill);

  constructor(address payable _treasury) {
    treasury = _treasury;
  }

  modifier onlyInspector() {
    require(_inspectors.contains(_msgSender()), "Balance: caller is not the inspector");
    _;
  }

  /**
   * @notice Change treasury contract address.
   * @param _treasury New treasury contract address.
   */
  function changeTreasury(address payable _treasury) external onlyOwner {
    treasury = _treasury;
    emit TreasuryChanged(treasury);
  }

  /**
   * @notice Add inspector.
   * @param inspector Added inspector.
   */
  function addInspector(address inspector) external onlyOwner {
    require(!_inspectors.contains(inspector), "Balance::addInspector: inspector already added");
    require(
      _inspectors.length() < MAXIMUM_INSPECTOR_COUNT,
      "Balance::addInspector: inspector must not exceed maximum count"
    );

    _inspectors.add(inspector);

    emit InspectorAdded(inspector);
  }

  /**
   * @notice Remove inspector.
   * @param inspector Removed inspector.
   */
  function removeInspector(address inspector) external onlyOwner {
    require(_inspectors.contains(inspector), "Balance::removeInspector: inspector already removed");

    _inspectors.remove(inspector);

    emit InspectorRemoved(inspector);
  }

  /**
   * @notice Get all inspectors.
   * @return All inspectors addresses.
   */
  function inspectors() external view returns (address[] memory) {
    address[] memory result = new address[](_inspectors.length());

    for (uint256 i = 0; i < _inspectors.length(); i++) {
      result[i] = _inspectors.at(i);
    }

    return result;
  }

  /**
   * @notice Add consumer.
   * @param consumer Added consumer.
   */
  function addConsumer(address consumer) external onlyOwner {
    require(!_consumers.contains(consumer), "Balance::addConsumer: consumer already added");
    require(
      _consumers.length() < MAXIMUM_CONSUMER_COUNT,
      "Balance::addConsumer: consumer must not exceed maximum count"
    );

    _consumers.add(consumer);

    emit ConsumerAdded(consumer);
  }

  /**
   * @notice Remove consumer.
   * @param consumer Removed consumer.
   */
  function removeConsumer(address consumer) external onlyOwner {
    require(_consumers.contains(consumer), "Balance::removeConsumer: consumer already removed");

    _consumers.remove(consumer);

    emit ConsumerRemoved(consumer);
  }

  /**
   * @notice Get all consumers.
   * @return All consumers addresses.
   */
  function consumers() external view returns (address[] memory) {
    address[] memory result = new address[](_consumers.length());

    for (uint256 i = 0; i < _consumers.length(); i++) {
      result[i] = _consumers.at(i);
    }

    return result;
  }

  /**
   * @notice Get net balance of account.
   * @param account Target account.
   * @return Net balance (balance minus claim).
   */
  function netBalanceOf(address account) public view returns (uint256) {
    return balanceOf[account] - claimOf[account];
  }

  /**
   * @notice Deposit ETH to balance.
   * @param recipient Target recipient.
   */
  function deposit(address recipient) external payable {
    require(recipient != address(0), "Balance::deposit: invalid recipient");
    require(msg.value > 0, "Balance::deposit: negative or zero deposit");

    balanceOf[recipient] += msg.value;

    emit Deposit(recipient, msg.value);
  }

  /**
   * @notice Refund ETH from balance.
   * @param amount Refunded amount.
   */
  function refund(uint256 amount) external {
    address payable recipient = payable(_msgSender());
    require(amount > 0, "Balance::refund: negative or zero refund");
    require(amount <= netBalanceOf(recipient), "Balance::refund: refund amount exceeds net balance");

    balanceOf[recipient] -= amount;
    recipient.transfer(amount);

    emit Refund(recipient, amount);
  }

  /**
   * @notice Send claim.
   * @param account Target account.
   * @param gasFee Claim gas fee.
   * @param protocolFee Claim protocol fee.
   * @param description Claim description.
   */
  function claim(
    address account,
    uint256 gasFee,
    uint256 protocolFee,
    string memory description
  ) external returns (uint256) {
    require(
      // solhint-disable-next-line avoid-tx-origin
      tx.origin == account || _consumers.contains(tx.origin),
      "Balance: caller is not a consumer"
    );

    uint256 amount = gasFee + protocolFee;
    require(amount > 0, "Balance::claim: negative or zero claim");
    require(amount <= netBalanceOf(account), "Balance::claim: claim amount exceeds net balance");

    claimOf[account] += amount;
    billCount++;
    bills[billCount] = Bill(billCount, _msgSender(), account, gasFee, protocolFee, BillStatus.Pending);
    emit Claim(account, billCount, description);

    return billCount;
  }

  /**
   * @notice Accept bills package.
   * @param _bills Target bills.
   * @param gasFees Confirmed claims gas fees by bills.
   * @param protocolFees Confirmed claims protocol fees by bills.
   */
  function acceptClaims(
    uint256[] memory _bills,
    uint256[] memory gasFees,
    uint256[] memory protocolFees
  ) external onlyInspector {
    require(
      _bills.length == gasFees.length && _bills.length == protocolFees.length,
      "Balance::acceptClaims: arity mismatch"
    );
    require(_bills.length <= MAXIMUM_CLAIM_PACKAGE, "Balance::acceptClaims: too many claims");

    uint256 transferredAmount;
    for (uint256 i = 0; i < _bills.length; i++) {
      uint256 billId = _bills[i];
      require(billId > 0 && billId <= billCount, "Balance::acceptClaims: bill not found");

      uint256 gasFee = gasFees[i];
      uint256 protocolFee = protocolFees[i];
      uint256 amount = gasFee + protocolFee;

      Bill storage bill = bills[billId];
      uint256 claimAmount = bill.gasFee + bill.protocolFee;
      require(bill.status == BillStatus.Pending, "Balance::acceptClaims: bill already processed");
      require(amount <= claimAmount, "Balance::acceptClaims: claim amount exceeds max fee");

      bill.status = BillStatus.Accepted;
      bill.gasFee = gasFee;
      bill.protocolFee = protocolFee;
      claimOf[bill.account] -= claimAmount;
      balanceOf[bill.account] -= amount;
      transferredAmount += amount;

      emit AcceptClaim(bill.id);
    }
    treasury.transfer(transferredAmount);
  }

  /**
   * @notice Reject bills package.
   * @param _bills Target bills.
   */
  function rejectClaims(uint256[] memory _bills) external onlyInspector {
    require(_bills.length < MAXIMUM_CLAIM_PACKAGE, "Balance::rejectClaims: too many claims");

    for (uint256 i = 0; i < _bills.length; i++) {
      uint256 billId = _bills[i];
      require(billId > 0 && billId <= billCount, "Balance::rejectClaims: bill not found");

      Bill storage bill = bills[billId];
      require(bill.status == BillStatus.Pending, "Balance::rejectClaims: bill already processed");
      uint256 amount = bill.gasFee + bill.protocolFee;

      bill.status = BillStatus.Rejected;
      claimOf[bill.account] -= amount;

      emit RejectClaim(bill.id);
    }
  }
}
