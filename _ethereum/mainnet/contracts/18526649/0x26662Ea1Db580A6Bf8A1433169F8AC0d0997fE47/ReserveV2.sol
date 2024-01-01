// SPDX-License-Identifier: MIT
pragma solidity =0.8.19;

/*        

Reserve ($RSRV)
https://www.reserveth.com/
https://t.me/rsrv_eth
https://twitter.com/rsrv_eth

*/

import "./IERC20.sol";
import "./SafeERC20.sol";
import "./Ownable.sol";
import "./SafeMath.sol";
import "./ReentrancyGuard.sol";

import "./IRSRV.sol";
import "./IReserveBrokerage.sol";
import "./IReserveOracle.sol";
import "./IReserve.sol";

contract ReserveV2 is IReserve, Ownable, ReentrancyGuard {
  using SafeMath for uint;
  using SafeERC20 for IERC20;

  struct UserBankInfo {
    uint count;
    uint pendingRewards;
    uint rewardDebt;
  }

  struct BankInfo {
    uint id;
    uint cost;
    uint bonusMultiplier;
    uint reserveAmount;
    uint lastRewardTimestamp;
    uint accRsrvPerShare;
    uint nextUpgradeId;
    bool isReset;
    uint aprOnReset;
  }

  IRSRV public immutable rsrv;
  address public constant deadAddress = address(0xdead);
  IReserveBrokerage public brokerage;
  IReserveOracle public oracle;
  uint public baseApr = 10000; // 100%
  
  uint private constant _DENOMINATOR = 10000;
  uint private slippage = 50; // 0.50%

  BankInfo[] public bankInfo;
  mapping (uint => mapping (address => UserBankInfo)) public userBankInfo;
  mapping (address => uint) public userReserve;
  mapping (address => uint) public withdrawableRewards;
  mapping (uint => uint) public totalBankCountPerType;
  uint public totalBankCount;
  uint public startTimestamp;

  mapping (address => bool) private _isWhitelisted;
  mapping (address => bool) private _userMigrated;

  /** EVENTS **/

  event Purchased(
    address indexed account,
    uint indexed id,
    uint count
  );

  event Upgraded(
    address indexed account,
    uint indexed id,
    uint indexed upgradeId,
    uint count
  );

  event Claimed(
    address indexed account,
    uint amount
  );

  constructor (
    address _rsrv,
    uint _startTimestamp
  ) {
    rsrv = IRSRV(_rsrv);
    startTimestamp = _startTimestamp;

    // retail
    bankInfo.push(BankInfo({
      id: 0,
      cost: uint(100).mul(1e18),
      bonusMultiplier: 20000, // 200.00%
      reserveAmount: 5,
      lastRewardTimestamp: _startTimestamp,
      accRsrvPerShare: 0,
      nextUpgradeId: 1,
      isReset: false,
      aprOnReset: 800 // 8.00 %
    }));

    // commercial
    bankInfo.push(BankInfo({
      id: 1,
      cost: uint(500).mul(1e18),
      bonusMultiplier: 40000, // 400.00 %
      reserveAmount: 50,
      lastRewardTimestamp: _startTimestamp,
      accRsrvPerShare: 0,
      nextUpgradeId: 2,
      isReset: false,
      aprOnReset: 1200 // 12.00 %
    }));

    // investment
    bankInfo.push(BankInfo({
      id: 2,
      cost: uint(2000).mul(1e18),
      bonusMultiplier: 100000, // 1000.00 %
      reserveAmount: 250,
      lastRewardTimestamp: _startTimestamp,
      accRsrvPerShare: 0,
      nextUpgradeId: 0,
      isReset: false,
      aprOnReset: 2000 // 20.00 %
    }));

    _isWhitelisted[_msgSender()] = true;
  }

  /** RESTRICTED FUNCTIONS **/

  function setBrokerage(address _brokerage) external onlyOwner {
    require (_brokerage != address(0), "!ADDRESS");
    brokerage = IReserveBrokerage(_brokerage);
  }

  function setOracle(address _oracle) external onlyOwner {
    require (_oracle != address(0), "!ADDRESS");
    oracle = IReserveOracle(_oracle);
  }

  function depositToBrokerage(uint _amount) external onlyOwner {
    require (address(brokerage) != address(0), "!SET");
    rsrv.mint(_amount);
    rsrv.approve(address(brokerage), _amount);
    brokerage.depositTokens(_amount);
  }

  function triggerAprUpdate() external onlyOwner {
    massUpdate(true);
  }

  function add(uint _id, uint _cost) external onlyOwner {
    require (_id == totalBankTypes(), "!ID");
    massUpdate(true);

    uint lastRewardTimestamp = block.timestamp > startTimestamp ? block.timestamp : startTimestamp;
    bankInfo.push(BankInfo({
      id: _id,
      cost: _cost.mul(1e18),
      bonusMultiplier: 10000,
      reserveAmount: 0,
      lastRewardTimestamp: lastRewardTimestamp,
      accRsrvPerShare: 0,
      nextUpgradeId: 0,
      isReset: false,
      aprOnReset: 0
    }));
  }

  function set(uint _id, uint _cost, uint _multiplier, uint _reserveAmount, uint _nextUpgradeId, uint _aprOnReset) external onlyOwner {
    require (_id < totalBankTypes(), "!ID");
    massUpdate(true);

    bankInfo[_id].cost = _cost.mul(1e18);
    bankInfo[_id].bonusMultiplier = _multiplier;
    bankInfo[_id].reserveAmount = _reserveAmount;
    bankInfo[_id].nextUpgradeId = _nextUpgradeId;
    bankInfo[_id].aprOnReset = _aprOnReset;
  }

  /** VIEW FUNCTIONS **/

  function getRewardRate(address _account) external view returns (uint rewardRate) {
    for (uint id = 0; id < totalBankTypes(); id++) {
      rewardRate = rewardRate.add(getRewardRate(_account, id));
    }
  }

  function getRewardRate(address _account, uint _id) public view returns (uint rewardRate) {
    BankInfo memory bank = bankInfo[_id];
    UserBankInfo memory user = userBankInfo[_id][_account];

    uint bankCount = totalBankCountPerType[_id];
    if (bankCount != 0) {
      uint multiplier = getMultiplier(block.timestamp, block.timestamp.add(1), bank.bonusMultiplier, bank.isReset, bank.aprOnReset);
      uint rewardRatePerBank = multiplier.mul(bank.cost).div(1e18);
      rewardRate = user.count.mul(rewardRatePerBank);
    }
  }

  function getRewards(address _account) external view returns (uint rewards) {
    rewards = withdrawableRewards[_account].add(getPendingRewards(_account));
  }

  function getPendingRewards(address _account) public view returns (uint rewards) {
    for (uint id = 0; id < totalBankTypes(); id++) {
      rewards = rewards.add(getPendingRewards(_account, id));
    }
  }

  function getPendingRewards(address _account, uint _id) public view returns (uint rewards) {
    BankInfo memory bank = bankInfo[_id];
    UserBankInfo memory user = userBankInfo[_id][_account];

    uint accRsrvPerShare = bank.accRsrvPerShare;
    uint bankCount = totalBankCountPerType[_id];
    if (block.timestamp > bank.lastRewardTimestamp && bankCount != 0) {
      uint multiplier = getMultiplier(bank.lastRewardTimestamp, block.timestamp, bank.bonusMultiplier, bank.isReset, bank.aprOnReset);
      uint reward = multiplier.mul(bank.cost).mul(bankCount);
      accRsrvPerShare = accRsrvPerShare.add(reward.div(bankCount));
    }

    rewards = user.pendingRewards.add(user.count.mul(accRsrvPerShare).div(1e18).sub(user.rewardDebt));
  }

  function getBankCount(address _account) external view returns (uint[] memory count) {
    count = new uint[](bankInfo.length);
    for (uint id = 0; id < totalBankTypes(); id++) {
      count[id] = getBankCountForType(_account, id);
    }
  }

  function getBankCountForType(address _account, uint _id) public view returns (uint count) {
    return userBankInfo[_id][_account].count;
  }

  function isAboveReserve(address _account) public view returns (bool passed, uint amountNedeed) {
    uint currentPrice = oracle.getCurrentPrice();
    uint amountRequired;
    for (uint id = 0; id < totalBankTypes(); id++) {
      amountRequired = amountRequired.add(getRequiredReserveForType(_account, id, currentPrice));
    }

    uint slippageAmount = amountRequired.mul(slippage).div(_DENOMINATOR);
    uint minimumAmountRequired = amountRequired.sub(slippageAmount);

    if (userReserve[_account] >= minimumAmountRequired) {
      passed = true;
      amountNedeed = 0;
    } else {
      passed = false;
      amountNedeed = amountRequired.sub(userReserve[_account]);
    }
  }

  function getCurrentReserveInUsd(address _account) external view returns (uint reserveInUsd) {
    return userReserve[_account].mul(oracle.getCurrentPrice()).div(1e18);
  }

  function getRequiredReserveForType(address _account, uint _id, uint _currentPrice) public view returns (uint amountRequired) {
    uint requiredReserveInUsd = getRequiredReserveInUsdForType(_account, _id).mul(1e18);
    amountRequired = requiredReserveInUsd.mul(1e18).div(_currentPrice);
  }

  function getRequiredReserveInUsd(address _account) public view returns (uint reserveAmount) {
    for (uint id = 0; id < totalBankTypes(); id++) {
      reserveAmount = reserveAmount.add(getRequiredReserveInUsdForType(_account, id));
    }
  }

  function getRequiredReserveInUsdForType(address _account, uint _id) public view returns (uint reserveAmount) {
    uint count = getBankCountForType(_account, _id);
    reserveAmount = bankInfo[_id].reserveAmount.mul(count);
  }

  function totalBankTypes() public view returns (uint) {
    return bankInfo.length;
  }

  function hasUserMigrated(address _account) external view returns (bool) {
    return _userMigrated[_account];
  }

  /** INTERNAL FUNCTIONS **/

  function getMultiplier(uint _from, uint _to, uint _bonusMultiplier, bool _isReset, uint _aprOnReset) internal view returns (uint) {
    if (_to < _from) return 0;

    uint base;
    if (_isReset) {
      base = _aprOnReset.mul(1e18).div(_DENOMINATOR).div(365 days);
      return _to.sub(_from).mul(base);
    } else {
      base = baseApr.mul(1e18).div(_DENOMINATOR).div(365 days);
      return _to.sub(_from).mul(base).mul(_bonusMultiplier).div(_DENOMINATOR);
    }
  }

  function massUpdate(bool _updateApr) internal {
    for (uint id = 0; id < totalBankTypes(); id++) {
      updateBankType(id, false);
    }

    if (_updateApr) _setApr();
  }

  function updateBankType(uint _id, bool _updateApr) internal {
    BankInfo storage bank = bankInfo[_id];

    if (block.timestamp <= bank.lastRewardTimestamp) {
      if (_updateApr) _setApr();
      return;
    }

    uint bankCount = totalBankCountPerType[_id];
    if (bankCount == 0) {
      bank.lastRewardTimestamp = block.timestamp;
      if (_updateApr) _setApr();
      return;
    }

    uint multiplier = getMultiplier(bank.lastRewardTimestamp, block.timestamp, bank.bonusMultiplier, bank.isReset, bank.aprOnReset);
    if (multiplier > 0) {
      uint reward = multiplier.mul(bank.cost).mul(bankCount);
      rsrv.mint(reward.div(1e18));
      bank.accRsrvPerShare = bank.accRsrvPerShare.add(reward.div(bankCount));
    }

    bank.lastRewardTimestamp = block.timestamp;
    if (_updateApr) _setApr();
  }

  function safeRsrvTransfer(address _recipient, uint _amount) internal {
    uint balance = rsrv.balanceOf(address(this));
    if (_amount > balance) {
      _amount = balance;
    }

    SafeERC20.safeTransfer(rsrv, _recipient, _amount);
  }

  function _setApr() internal {
    uint _baseApr = oracle.setCurrentMultiplier();
    if (_baseApr == 1) {
      for (uint id = 0; id < totalBankTypes(); id++) {
        bankInfo[id].isReset = true;
      }

      baseApr = _DENOMINATOR;
    } else {
      baseApr = _baseApr;
    }
  }

  function _purchase(address _account, uint _id, uint _count) internal returns (uint _cost) {
    require (_id < totalBankTypes(), "!ID");
    require (_count > 0, "!ZERO");
    updateBankType(_id, true);

    BankInfo memory bank = bankInfo[_id];
    require(!bank.isReset, "!DIS");
    UserBankInfo storage user = userBankInfo[_id][_account];
    _cost = _count.mul(bank.cost);

    if (user.count > 0) {
      uint pendingRewards = user.count.mul(bank.accRsrvPerShare).div(1e18).sub(user.rewardDebt);
      if (pendingRewards > 0) {
        user.pendingRewards = user.pendingRewards.add(pendingRewards);
      }
    }

    if (_count > 0) {
      uint currentPrice = oracle.getCurrentPrice();
      userReserve[_account] = userReserve[_account].add(_count.mul(bank.reserveAmount).mul(1e36).div(currentPrice));
      user.count = user.count.add(_count);
      totalBankCountPerType[_id] = totalBankCountPerType[_id].add(_count);
      totalBankCount = totalBankCount.add(_count);
    }

    user.rewardDebt = user.count.mul(bank.accRsrvPerShare).div(1e18);
    emit Purchased(_account, _id, _count);
  }

  function _upgrade(address _account, uint _id, uint _count) internal returns (uint _nextUpgradeId) {
    require (_id < totalBankTypes(), "!ID");
    require (_count > 0, "!ZERO");
    updateBankType(_id, false);

    BankInfo memory bank = bankInfo[_id];
    require (bank.nextUpgradeId != 0, "!NONE");

    UserBankInfo storage user = userBankInfo[_id][_account];
    require (user.count >= _count, "!CNT");

    if (user.count > 0) {
      uint pendingRewards = user.count.mul(bank.accRsrvPerShare).div(1e18).sub(user.rewardDebt);
      if (pendingRewards > 0) {
        user.pendingRewards = user.pendingRewards.add(pendingRewards);
      }
    }

    _nextUpgradeId = bank.nextUpgradeId;
    updateBankType(_nextUpgradeId, true);
    
    BankInfo memory _upgradeBank = bankInfo[_nextUpgradeId];
    UserBankInfo storage _upgradeUser = userBankInfo[_nextUpgradeId][_account];

    if (_upgradeUser.count > 0) {
      uint pendingRewards = _upgradeUser.count.mul(_upgradeBank.accRsrvPerShare).div(1e18).sub(_upgradeUser.rewardDebt);
      if (pendingRewards > 0) {
        _upgradeUser.pendingRewards = _upgradeUser.pendingRewards.add(pendingRewards);
      }
    }

    user.count = user.count.sub(_count);
    totalBankCountPerType[_id] = totalBankCountPerType[_id].sub(_count);
    user.rewardDebt = user.count.mul(bank.accRsrvPerShare).div(1e18);
    uint currentPrice = oracle.getCurrentPrice();
    uint reserveToRemove = _count.mul(bank.reserveAmount).mul(1e36).div(currentPrice);
    if (reserveToRemove > userReserve[_account]) {
      userReserve[_account] = 0;
    } else {
      userReserve[_account] = userReserve[_account].sub(reserveToRemove);
    }

    userReserve[_account] = userReserve[_account].add(_count.mul(_upgradeBank.reserveAmount).mul(1e36).div(currentPrice));
    _upgradeUser.count = _upgradeUser.count.add(_count);
    totalBankCountPerType[_nextUpgradeId] = totalBankCountPerType[_nextUpgradeId].add(_count);
    _upgradeUser.rewardDebt = _upgradeUser.count.mul(_upgradeBank.accRsrvPerShare).div(1e18);

    emit Upgraded(_account, _id, _nextUpgradeId, _count);
  }

  function _processRewards(address _account, uint _id) internal {
    require (_id < totalBankTypes(), "!ID");

    BankInfo memory bank = bankInfo[_id];
    UserBankInfo storage user = userBankInfo[_id][_account];

    if (user.count > 0) {
      uint pendingRewards = user.count.mul(bank.accRsrvPerShare).div(1e18).sub(user.rewardDebt);
      if (pendingRewards > 0) {
        user.pendingRewards = user.pendingRewards.add(pendingRewards);
      }
    }

    user.rewardDebt = user.count.mul(bank.accRsrvPerShare).div(1e18);
  }

  function _claim(address _account) internal {
    massUpdate(true);

    uint totalRewards;
    for (uint id = 0; id < totalBankTypes(); id++) {
      _processRewards(_account, id);
      totalRewards = totalRewards.add(userBankInfo[id][_account].pendingRewards);
      userBankInfo[id][_account].pendingRewards = 0;
    }

    withdrawableRewards[_account] = withdrawableRewards[_account].add(totalRewards);
  }

  /** PUBLIC FUNCTIONS **/

  function purchaseBank(uint _id, uint _count) external nonReentrant {
    uint cost = _purchase(_msgSender(), _id, _count);
    SafeERC20.safeTransferFrom(rsrv, _msgSender(), deadAddress, cost);
  }

  function claimBank(address _account, uint _id, uint _count) external returns (uint cost) {
    require (_msgSender() == address(brokerage) || _isWhitelisted[_msgSender()], "!WL");
    cost = _purchase(_account, _id, _count);
  }

  function upgradeBank(uint _id, uint _count) external nonReentrant {
    uint nextUpgradeId = _upgrade(_msgSender(), _id, _count);
    uint cost = _count.mul(bankInfo[nextUpgradeId].cost.sub(bankInfo[_id].cost));
    SafeERC20.safeTransferFrom(rsrv, _msgSender(), deadAddress, cost);
  }

  function claimUpgrade(address _account, uint _id, uint _count) external returns (uint cost) {
    require (_msgSender() == address(brokerage) || _isWhitelisted[_msgSender()], "!WL");
    uint nextUpgradeId = _upgrade(_account, _id, _count);
    cost = _count.mul(bankInfo[nextUpgradeId].cost.sub(bankInfo[_id].cost));
  }

  function coverReserve(bool _fromRewards, bool _claimRest) external {
    (bool passed, uint amountNeeded) = isAboveReserve(_msgSender());
    _claim(_msgSender());

    if (!passed) {
      if (_fromRewards) {
        require (withdrawableRewards[_msgSender()] > amountNeeded, "!NE");
        withdrawableRewards[_msgSender()] = withdrawableRewards[_msgSender()].sub(amountNeeded);
        userReserve[_msgSender()] = userReserve[_msgSender()].add(amountNeeded);
        if (_claimRest) {
          uint amount = withdrawableRewards[_msgSender()];
          safeRsrvTransfer(_msgSender(), amount);
          withdrawableRewards[_msgSender()] = 0;
          emit Claimed(_msgSender(), amount);
        }
      } else {
        SafeERC20.safeTransferFrom(rsrv, _msgSender(), deadAddress, amountNeeded);
        userReserve[_msgSender()] = userReserve[_msgSender()].add(amountNeeded);
        if (_claimRest) {
          uint amount = withdrawableRewards[_msgSender()];
          safeRsrvTransfer(_msgSender(), amount);
          withdrawableRewards[_msgSender()] = 0;
          emit Claimed(_msgSender(), amount);
        }
      }
    }
  }

  function claimRewards() external nonReentrant {
    (bool passed, ) = isAboveReserve(_msgSender());
    require (passed, "!RSRV");
    
    _claim(_msgSender());
    uint amount = withdrawableRewards[_msgSender()];
    safeRsrvTransfer(_msgSender(), amount);
    withdrawableRewards[_msgSender()] = 0;
    emit Claimed(_msgSender(), amount);
  }

  function compoundRewards(uint _id, uint _count, bool _claimRest) external nonReentrant {
    (bool passed, ) = isAboveReserve(_msgSender());
    require (passed, "!RSRV");

    _claim(_msgSender());
    uint cost = _purchase(_msgSender(), _id, _count);
    require (withdrawableRewards[_msgSender()] >= cost, "!NE");

    uint left = withdrawableRewards[_msgSender()].sub(cost);
    withdrawableRewards[_msgSender()] = left;
    if (left > 0 && _claimRest) {
      safeRsrvTransfer(_msgSender(), left);
      withdrawableRewards[_msgSender()] = 0;
      emit Claimed(_msgSender(), left);
    }
  }

  function burnAndVestRewards(uint _amount, uint _period, bool _claimRest) external nonReentrant {
    require (address(brokerage) != address(0), "!ADDRESS");
    (bool passed, ) = isAboveReserve(_msgSender());
    require (passed, "!RSRV");

    _claim(_msgSender());
    require (withdrawableRewards[_msgSender()] >= _amount, "!NE");
    brokerage.burnAndVest(_amount, _period, _msgSender());
    SafeERC20.safeTransfer(rsrv, deadAddress, _amount);

    uint left = withdrawableRewards[_msgSender()].sub(_amount);
    withdrawableRewards[_msgSender()] = left;
    if (left > 0 && _claimRest) {
      safeRsrvTransfer(_msgSender(), left);
      withdrawableRewards[_msgSender()] = 0;
      emit Claimed(_msgSender(), left);
    }
  }

  /** MIGRATION FROM V1 **/

  function migrate() external nonReentrant {
    require (!_userMigrated[_msgSender()], "MIG");
    IReserve reserveV1 = IReserve(0xD6b5BfCfa8D012b2C4Db0Ae3f912CC9fa6ed5B8D);

    uint rewards = reserveV1.getRewards(_msgSender());
    if (rewards > 0) {
      rsrv.mint(rewards);
      withdrawableRewards[_msgSender()] = withdrawableRewards[_msgSender()].add(rewards);
    }

    for (uint id = 0; id < reserveV1.totalBankTypes(); id++) {
      uint count = reserveV1.getBankCountForType(_msgSender(), id);
      if (count > 0) _purchase(_msgSender(), id, count);
    }

    userReserve[_msgSender()] = reserveV1.userReserve(_msgSender());
    _userMigrated[_msgSender()] = true;
  }
}