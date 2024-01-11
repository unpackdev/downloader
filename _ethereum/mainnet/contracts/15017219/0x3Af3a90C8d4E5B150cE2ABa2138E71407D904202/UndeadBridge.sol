// SPDX-License-Identifier: MIT
pragma solidity 0.8.4;

import "./IERC20Upgradeable.sol";
import "./SafeERC20Upgradeable.sol";
import "./AccessControlUpgradeable.sol";
import "./ReentrancyGuardUpgradeable.sol";
import "./draft-EIP712Upgradeable.sol";
import "./ECDSAUpgradeable.sol";

contract UndeadBridge is EIP712Upgradeable, AccessControlUpgradeable, ReentrancyGuardUpgradeable {
  using SafeERC20Upgradeable for IERC20Upgradeable;

  struct Record {
    uint256 wId;
    address user;
    address token;
    uint256 amount;
    uint256 fee;
    uint256 time;
  }

  bytes32 public constant MASTER_ROLE = keccak256("MASTER_ROLE");
  bytes32 public constant MASTER_ADMIN = keccak256("MASTER_ADMIN");
  bytes32 public constant MODIFICATION_ROLE = keccak256("MODIFICATION_ROLE");
  bytes32 public constant EMERGENCY_ROLE = keccak256("EMERGENCY_ROLE");

  address public wETH;
  mapping(bytes => address) private _usedSignature;
  mapping(address => uint256) public masterPower;
  mapping(uint256 => Record) public swapOutRecord;
  mapping(uint256 => Record) public swapInRecord;
  mapping(address => bool) public blackListed;

  uint256 public totalMaster;
  uint256 public totalPower;

  uint256 public masterRequired;
  uint256 public powersRequired;
  uint256 public receiveTime;
  address public feeHolder;

  bool public swapOutEnabled;
  uint256 public swapOutFee;

  bool public swapInEnabled;
  uint256 public swapInId;
  uint256 public swapInFee;

  event SwapIn(address _sender, uint256 _swapId, address _token, uint256 _amount, uint256 _fee, uint256 _time);
  event SwapOut(address _sender, uint256 _swapId, address _token, uint256 _amount, uint256 _sigTime, uint256 _time);
  event MasterConfig(uint256 _masters, uint256 _powers);
  event HireMaster(address _account, uint256 _power);
  event FireMaster(address _account, uint256 _power);
  event Received(address _sender, uint256 _amount);

  receive() external payable {
    emit Received(msg.sender, msg.value);
  }

  function emergencyEth(address _to, uint256 _amount) external onlyRole(EMERGENCY_ROLE) {
    require(_to != address(0), "Invalid to");
    payable(_to).transfer(_amount);
  }

  function emergencyToken(
    address _to,
    address _token,
    uint256 _amount
  ) external onlyRole(EMERGENCY_ROLE) {
    require(_to != address(0), "Invalid to");
    IERC20Upgradeable(_token).safeTransfer(_to, _amount);
  }

  /**
   * @dev Upgradable initializer
   */
  function __UndeadBridge_init(address _wETH) external initializer {
    __AccessControl_init();
    __ReentrancyGuard_init();
    __EIP712_init("UndeadBridge", "1.0.0");
    _setupRole(DEFAULT_ADMIN_ROLE, _msgSender());
    _setupRole(MODIFICATION_ROLE, _msgSender());

    _setRoleAdmin(MASTER_ROLE, MASTER_ADMIN);

    masterRequired = 3;
    powersRequired = 30;
    wETH = _wETH;
    receiveTime = 1 days;
    swapOutEnabled = true;
    swapInEnabled = true;
    feeHolder = _msgSender();
  }

  function setFeeConfig(
    uint256 _swapOutFee,
    uint256 _swapInFee,
    address _feeHolder
  ) external onlyRole(MODIFICATION_ROLE) {
    swapOutFee = _swapOutFee;
    swapInFee = _swapInFee;
    feeHolder = _feeHolder;
  }

  function setReceiveTime(uint256 _time) external onlyRole(MODIFICATION_ROLE) {
    receiveTime = _time;
  }

  function setSwapOutEnabled(bool _status) external onlyRole(MODIFICATION_ROLE) {
    swapOutEnabled = _status;
  }

  function setSwapInEnabled(bool _status) external onlyRole(MODIFICATION_ROLE) {
    swapInEnabled = _status;
  }

  function setBlacklist(address _account, bool _status) external onlyRole(MODIFICATION_ROLE) {
    require(blackListed[_account] != _status, "blacklist");
    blackListed[_account] = _status;
  }

  function setMasterRequired(uint256 _masters, uint256 _powers) external onlyRole(MASTER_ADMIN) {
    masterRequired = _masters;
    powersRequired = _powers;
    emit MasterConfig(_masters, _powers);
  }

  function hireMaster(address _account, uint256 _power) external onlyRole(MASTER_ADMIN) {
    require(_account != address(0) && _power > 0 && masterPower[_account] == 0, "invalid");
    totalMaster++;
    totalPower += _power;
    masterPower[_account] = _power;
    if (!hasRole(MASTER_ROLE, _account)) {
      grantRole(MASTER_ROLE, _account);
    }
    emit HireMaster(_account, _power);
  }

  function fireMaster(address _account) external onlyRole(MASTER_ADMIN) {
    uint currentpower_ = masterPower[_account];
    require(currentpower_ > 0, "no power");
    totalMaster--;
    totalPower -= currentpower_;
    masterPower[_account] = 0;
    if (hasRole(MASTER_ROLE, _account)) {
      revokeRole(MASTER_ROLE, _account);
    }
    emit FireMaster(_account, currentpower_);
  }

  function swapIn(uint256 _amount, address _token) external payable nonReentrant {
    require(swapInEnabled, "swap in is disabled");
    require(_amount > 0, "Invalid amount");
    address sender = _msgSender();
    require(!blackListed[sender], "in blacklist");

    swapInId++;
    require(swapInRecord[swapInId].amount == 0, "already used");
    uint256 feeAmount = (_amount * swapInFee) / 10000;
    uint256 amountAfterFee = _amount - feeAmount;

    swapInRecord[swapInId] = Record(swapInId, sender, _token, _amount, feeAmount, block.timestamp);

    if (_token == wETH) {
      require(_amount == msg.value, "invalid amount");
      if (feeAmount > 0) payable(feeHolder).transfer(feeAmount);
    } else {
      IERC20Upgradeable(_token).safeTransferFrom(sender, address(this), amountAfterFee);
      if (feeAmount > 0) {
        IERC20Upgradeable(_token).safeTransferFrom(sender, feeHolder, feeAmount);
      }
    }

    emit SwapIn(sender, swapInId, _token, amountAfterFee, feeAmount, block.timestamp);
  }

  function swapOut(
    uint256 _swapId,
    address _token,
    uint256 _amount,
    uint256 _sigTime,
    bytes[] calldata _signatures
  ) external nonReentrant {
    require(swapOutEnabled, "swap out is disabled");
    address sender = _msgSender();
    require(!blackListed[sender], "in blacklist");
    require(_amount > 0, "Invalid amount");

    require(swapOutRecord[_swapId].amount == 0, "already executed");
    require(block.timestamp <= _sigTime + receiveTime, "sig expired");

    // Authentication
    _verify(sender, _swapId, _token, _amount, _sigTime, _signatures);

    uint256 feeAmount = (_amount * swapOutFee) / 100e2;
    // Log
    swapOutRecord[_swapId] = Record(_swapId, sender, _token, _amount, feeAmount, block.timestamp);

    // swap
    if (_token == wETH) {
      payable(sender).transfer(_amount - feeAmount);
      payable(feeHolder).transfer(feeAmount);
    } else {
      IERC20Upgradeable(_token).safeTransfer(sender, _amount - feeAmount);
      IERC20Upgradeable(_token).safeTransfer(feeHolder, feeAmount);
    }

    emit SwapOut(sender, _swapId, _token, _amount, _sigTime, block.timestamp);
  }

  function _verify(
    address _user,
    uint256 _swapId,
    address _token,
    uint256 _amount,
    uint256 _sigTime,
    bytes[] calldata signatures
  ) private {
    uint256 masterCount = 0;
    uint256 powerCount = 0;
    for (uint256 i = 0; i < signatures.length; i++) {
      bytes32 digest_ = _hash(_user, _swapId, _token, _amount, _sigTime);
      address master = ECDSAUpgradeable.recover(digest_, signatures[i]);
      require(hasRole(MASTER_ROLE, master), "no role");
      require(_usedSignature[signatures[i]] == address(0), "already used");
      _usedSignature[signatures[i]] = master;
      masterCount++;
      powerCount += masterPower[master];
    }
    require(masterCount >= masterRequired, "need more masters");
    require(powerCount >= powersRequired, "need more powers");
  }

  function _hash(
    address _user,
    uint256 _swapId,
    address _token,
    uint256 _amount,
    uint256 _sigTime
  ) private view returns (bytes32) {
    return
      _hashTypedDataV4(
        keccak256(
          abi.encode(
            keccak256("UndeadBridge(address _user,uint256 _swapId,address _token,uint256 _amount,uint256 _sigTime)"),
            _user,
            _swapId,
            _token,
            _amount,
            _sigTime
          )
        )
      );
  }
}
