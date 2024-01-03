// SPDX-License-Identifier: MIT

pragma solidity >=0.5.0 <0.7.0;

import "./IERC20.sol";
import "./SafeERC20.sol";
import "./SafeMath.sol";

import "./ILockedLiquidityEvent.sol";
import "./ITDAO.sol";
import "./IVault.sol";

contract FeeSplitter {
  using SafeMath for uint256;
  using SafeERC20 for IERC20;

  event HodlerMadeWhole(address indexed account, uint256 amount);
  event TrigRewardDistributed(uint256 amount);
  event NFTRewardDistributed(uint256 amount);
  event TreasuryDeposit(uint256 amount);

  address public tdao;
  address public nftRewardsVault;
  address public trigRewardsVault;
  address public treasuryVault;

  uint256 public interval = 30 days;
  uint256 public trigFee = 5000;
  uint256 public keeperFee = 10;
  uint256 public constant BASE = 10000;
  uint256 public hodlerRequiredAmount = 1 ether;

  uint256[5] public timestamps;
  uint256[5] public treasuryFees = [9000, 9200, 9400, 9600, 9800];

  modifier onlyHodler() {
    require(
      IERC20(tdao).balanceOf(msg.sender) >= hodlerRequiredAmount,
      'FeeSplitter: You must have at least 1 TDAO to call this function.'
    );
    _;
  }

  modifier onlyTDAO() {
    require(msg.sender == tdao, 'FeeSplitter: Function call not allowed.');
    _;
  }

  constructor(
    address _tdao,
    address _trigRewardsVault,
    address _nftRewardsVault,
    address _treasuryAddress
  ) public {
    tdao = _tdao;
    trigRewardsVault = _trigRewardsVault;
    nftRewardsVault = _nftRewardsVault;
    treasuryVault = _treasuryAddress;

    timestamps = _setTimestamps(
      ILockedLiquidityEvent(ITDAO(tdao).lockedLiquidityEvent())
        .startTradingTime()
    );
  }

  function update() external onlyHodler {
    uint256 amount = IERC20(tdao).balanceOf(address(this));

    if (amount < BASE) {
      return;
    }

    uint256 keeperShare = amount.mul(keeperFee).div(BASE);
    uint256 discounted = amount.sub(keeperShare);

    uint256 trigShare = discounted.mul(trigFee).div(BASE);
    uint256 remaining = discounted.sub(trigShare);
    (uint256 nftRewardsShare, uint256 treasuryShare) =
      _splitRemainingFees(remaining);

    IERC20(tdao).safeTransfer(msg.sender, keeperShare);
    IERC20(tdao).safeTransfer(trigRewardsVault, trigShare);
    IERC20(tdao).safeTransfer(nftRewardsVault, nftRewardsShare);
    IERC20(tdao).safeTransfer(treasuryVault, treasuryShare);

    IVault(trigRewardsVault).update(trigShare);
    IVault(nftRewardsVault).update(nftRewardsShare);
    IVault(treasuryVault).update(treasuryShare);

    emit HodlerMadeWhole(msg.sender, keeperShare);
    emit TrigRewardDistributed(trigShare);
    emit NFTRewardDistributed(nftRewardsShare);
    emit TreasuryDeposit(treasuryShare);
  }

  function setTreasuryVault(address _treasuryVault) external onlyTDAO {
    require(
      _treasuryVault != address(0),
      'FeeSplitter: Treasury must be set to a valid address.'
    );
    treasuryVault = _treasuryVault;
  }

  function setTrigFee(uint256 _trigFee) external onlyTDAO {
    require(
      _trigFee >= 5000 && _trigFee <= 9000,
      'FeeSplitter: Trig fee out of bounds.'
    );
    trigFee = _trigFee;
  }

  function setKeeperFee(uint256 _keeperFee) external onlyTDAO {
    require(_keeperFee <= 10, 'FeeSplitter: Keeper fee is out of bounds.');
    keeperFee = _keeperFee;
  }

  function keeperReward() external view returns (uint256 reward) {
    reward = IERC20(tdao).balanceOf(address(this)).mul(keeperFee).div(BASE);
  }

  function _splitRemainingFees(uint256 _amount)
    internal
    view
    returns (uint256 _nftRewardsAllocation, uint256 _treasuryAllocation)
  {
    uint256 _now = block.timestamp;

    for (uint8 i = uint8(timestamps.length.sub(1)); i >= 0; i--) {
      if (_now > timestamps[i]) {
        _treasuryAllocation = _amount.mul(treasuryFees[i]).div(BASE);
        _nftRewardsAllocation = _amount.sub(_treasuryAllocation);
        break;
      }
    }
  }

  function _setTimestamps(uint256 _startTime)
    internal
    view
    returns (uint256[5] memory)
  {
    uint256[5] memory _timestamps;
    for (uint8 i = 0; i < 5; i++) {
      _timestamps[i] = _startTime.add(interval.mul(i));
    }
    return _timestamps;
  }
}
