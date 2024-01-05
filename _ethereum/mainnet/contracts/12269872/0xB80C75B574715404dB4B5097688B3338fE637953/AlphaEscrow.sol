pragma solidity 0.6.12;

import "./IERC20.sol";
import "./SafeERC20.sol";
import "./ReentrancyGuard.sol";
import "./SafeMath.sol";

contract AlphaEscrow is ReentrancyGuard {
  using SafeERC20 for IERC20;
  using SafeMath for uint;

  event Withdraw(uint indexed receiptId, uint amount, address gov);
  event Claim(uint indexed receiptId, uint amount, address gov);
  event Cancel(uint indexed receiptId, address gov);
  event Unlock(address gov, uint amount);
  event RequestLastResort(address gov);
  event CancelLastResort(address gov);
  event ClaimLastResort(address gov, uint amount);

  uint public constant STATUS_PENDING = 1;
  uint public constant STATUS_CANCELED = 2;
  uint public constant STATUS_CLAIMED = 3;
  uint public constant TIMELOCK_DURATION = 7 days;
  uint public constant LAST_RESORT_TIMELOCK_DURATION = 30 days;

  struct WithdrawReceipt {
    uint amount;
    uint withdrawTime;
    uint status;
  }

  IERC20 public alpha;
  address public alphaGovernor;
  address public creamGovernor;
  uint public nextReceiptId;
  mapping(uint => WithdrawReceipt) public receipts;
  uint public lastResortRequestTime;

  modifier onlyAlphaGov() {
    require(msg.sender == alphaGovernor, 'only Alpha governor');
    _;
  }

  modifier onlyCreamGov() {
    require(msg.sender == creamGovernor, 'only Cream governor');
    _;
  }

  modifier onlyGov() {
    require(
      msg.sender == creamGovernor || msg.sender == alphaGovernor,
      'only Cream or Alpha governor'
    );
    _;
  }

  constructor(
    address _alpha,
    address _alphaGovernor,
    address _creamGovernor
  ) public {
    alpha = IERC20(_alpha);
    alphaGovernor = _alphaGovernor;
    creamGovernor = _creamGovernor;
  }

  /// @dev Create withdraw receipt by CREAM governor
  /// @param _amount Amount of ALPHA to withdraw
  function withdraw(uint _amount) external nonReentrant onlyCreamGov {
    require(_amount > 0, 'cannot withdraw 0 alpha');
    uint alphaBalance = alpha.balanceOf(address(this));
    require(_amount <= alphaBalance, 'insufficient ALPHA to withdraw');
    WithdrawReceipt storage receipt = receipts[nextReceiptId];
    receipt.amount = _amount;
    receipt.withdrawTime = block.timestamp;
    receipt.status = STATUS_PENDING;
    nextReceiptId++;
    emit Withdraw(nextReceiptId - 1, _amount, msg.sender);
  }

  /// @dev Claim ALPHA using withdrawal receipt by CREAM governor
  /// note: CREAM governor can claim withdraw receipt after timelock duration.
  /// @param _receiptId The ID of withdrawal receipt to claim ALPHA
  function claim(uint _receiptId) external nonReentrant onlyCreamGov {
    WithdrawReceipt storage receipt = receipts[_receiptId];
    require(_receiptId < nextReceiptId, 'receipt does not exist');
    require(
      receipt.status == STATUS_PENDING,
      'receipt has been canceled, claimed, or not yet initialized'
    );
    require(
      block.timestamp >= receipt.withdrawTime.add(TIMELOCK_DURATION),
      'invalid time to claim'
    );
    receipt.status = STATUS_CLAIMED;
    alpha.safeTransfer(msg.sender, receipt.amount);
    emit Claim(_receiptId, receipt.amount, msg.sender);
  }

  /// @dev Cancel withdrawal receipt by CREAM or ALPHA governor.
  /// @param _receiptId The ID of withdrawal receipt to cancel
  function cancelWithdrawReceipt(uint _receiptId) external nonReentrant onlyGov {
    WithdrawReceipt storage receipt = receipts[_receiptId];
    require(_receiptId < nextReceiptId, 'receipt does not exist');
    require(receipt.status == STATUS_PENDING, 'only pending receipt can be canceled');
    receipt.status = STATUS_CANCELED;
    emit Cancel(_receiptId, msg.sender);
  }

  /// @dev Unlock ALPHA token to ALPHA governor
  /// @param _amount Amount of ALPHA to unlock
  function unlock(uint _amount) external nonReentrant onlyCreamGov {
    alpha.safeTransfer(alphaGovernor, _amount);
    emit Unlock(alphaGovernor, _amount);
  }

  /// @dev The last resort to withdraw ALPHA from this contract by ALPHA governor
  function requestLastResort() external nonReentrant onlyAlphaGov {
    lastResortRequestTime = block.timestamp;
    emit RequestLastResort(msg.sender);
  }

  /// @dev Cancel the last resort to withdraw ALPHA by CREAM or ALPHA governor
  function cancelLastResort() external nonReentrant onlyGov {
    lastResortRequestTime = 0;
    emit CancelLastResort(msg.sender);
  }

  /// @dev Claim withdrawn ALPHA by ALPHA governor
  function claimLastResort() external nonReentrant onlyAlphaGov {
    require(
      lastResortRequestTime > 0 &&
        block.timestamp >= lastResortRequestTime.add(LAST_RESORT_TIMELOCK_DURATION),
      'invalid time to claim requested ALPHA'
    );
    lastResortRequestTime = 0;
    uint amount = alpha.balanceOf(address(this));
    alpha.safeTransfer(msg.sender, amount);
    emit ClaimLastResort(msg.sender, amount);
  }

  /// @dev Recover any ERC20 token except ALPHA from this contract
  /// @param _token ERC20 Token address to recover from this contract
  function recover(address _token) external nonReentrant onlyAlphaGov {
    require(_token != address(alpha), 'cannot recover ALPHA');
    IERC20 token = IERC20(_token);
    uint amount = token.balanceOf(address(this));
    token.safeTransfer(msg.sender, amount);
  }
}
