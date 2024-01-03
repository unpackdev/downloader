// SPDX-License-Identifier: MIT

pragma solidity >=0.6.8;

import "./console.sol";

import "./SafeMath.sol";
import "./IERC20.sol";
import "./SafeERC20.sol";

import "./IHegicPoolV2.sol";

import "./ILotManager.sol";

import "./HegicPoolMetadata.sol";
import "./HegicPoolProtocolParameters.sol";

import "./Governable.sol";
import "./Manageable.sol";
import "./CollectableDust.sol";
import "./zHEGIC.sol";

contract HegicPoolV2 is
  Governable,
  Manageable,
  CollectableDust,
  HegicPoolMetadata,
  HegicPoolProtocolParameters,
  IHegicPoolV2 {

  using SafeERC20 for IERC20;
  using SafeMath for uint256;

  IERC20 public token;
  zHEGIC public zToken;
  ILotManager public lotManager;
  mapping (address => uint256) public userCooldown;

  constructor(
    address _token,
    address _zToken,
    uint256 _minTokenReserves,
    uint256 _withdrawCooldown,
    uint256 _withdrawFee
  ) public
    Governable(msg.sender)
    Manageable(msg.sender)
    HegicPoolProtocolParameters (_minTokenReserves, _withdrawCooldown, _withdrawFee)
  {
    token = IERC20(_token);
    zToken = zHEGIC(_zToken);
    _addProtocolToken(_token);
    _addProtocolToken(_zToken);
  }

  function getToken() external view override returns (address) {
    return address(token);
  }

  function getZToken() external view override returns (address) {
    return address(zToken);
  }

  function getLotManager() external view override returns (address) {
    return address(lotManager);
  }

  // Pool functions

  function migrate(address _newPool) external override onlyGovernor {
    require(IHegicPoolMetadata(_newPool).isHegicPool(), 'hegic-pool/not-setting-a-hegic-pool');
    if (address(lotManager) != address(0)) {
      lotManager.setPool(_newPool);
    }
    zToken.setPool(_newPool);
    uint poolBalance = token.balanceOf(address(this));
    token.transfer(_newPool, poolBalance);

    require(IHegicPoolV2(_newPool).getLotManager() == address(lotManager), 'hegic-pool/migrate-lot-manager-discrepancy');
    emit PoolMigrated(_newPool, poolBalance);
  }

  /** Deposit
   *  User should deposit approved amount of HEGIC erc20 tokens into the pool and receive zHEGIC (pool stake) back
   *
   */
  function deposit(uint256 _amount) public override returns (uint256 _shares) {
    userCooldown[msg.sender] = now.add(withdrawCooldown);
    uint256 _pool = totalUnderlying();
    uint256 _before = unusedUnderlyingBalance();
    token.safeTransferFrom(msg.sender, address(this), _amount);
    uint256 _after = unusedUnderlyingBalance();
    _amount = _after.sub(_before); // Additional check for deflationary tokens
    if (zToken.totalSupply() == 0) {
      _shares = _amount;
    } else {
      _shares = (_amount.mul(zToken.totalSupply())).div(_pool);
    }
    zToken.mint(msg.sender, _shares);
    emit Deposited(msg.sender, _amount, _shares);
  }

  function depositAll() external override returns (uint256 _shares) {
    return deposit(token.balanceOf(msg.sender));
  }

  /** Withdraw
   *  User should withdraw amount of HEGIC erc20 tokens into the pool and receive zHEGIC (pool stake) back
   *
   */

  function withdraw(uint256 _shares) public override returns (uint256 _underlyingToWithdraw) {
    _underlyingToWithdraw = (totalUnderlying().mul(_shares)).div(zToken.totalSupply());
    zToken.burn(msg.sender, _shares);

    // Check balance
    uint256 _unusedUnderlyingBalance = unusedUnderlyingBalance();
    if (_underlyingToWithdraw > _unusedUnderlyingBalance) {
      uint256 _missingUnderlying = _underlyingToWithdraw.sub(_unusedUnderlyingBalance);

      // Check if we can close a lot to repay withdraw
      lotManager.unwind(_missingUnderlying);

      uint256 _underlyingAfterLotClosure = unusedUnderlyingBalance();

      // Revert if we still haven't got enough underlying.
      require(_underlyingAfterLotClosure >= _underlyingToWithdraw, 'hegic-pool/not-enough-to-unwind');
    }

    uint256 _withdrawFee;
    if (now < userCooldown[msg.sender]) { // user on cooldown, charging withdrawal fee
      _withdrawFee = _underlyingToWithdraw.mul(withdrawFee).div(WITHDRAW_FEE_PRECISION).div(100);
      _underlyingToWithdraw = _underlyingToWithdraw.sub(_withdrawFee);
      token.safeTransfer(governor, _withdrawFee);
    }

    token.safeTransfer(msg.sender, _underlyingToWithdraw);
    emit Withdrew(msg.sender, _shares, _underlyingToWithdraw, _withdrawFee);
  }

  function withdrawAll() external override returns (uint256 _underlyingToWithdraw) {
    return withdraw(zToken.balanceOf(msg.sender));
  }

  // Balance trackers
  function unusedUnderlyingBalance() public override view returns (uint256) {
    return token.balanceOf(address(this));
  }

  function totalUnderlying() public override view returns (uint256) {
    if (address(lotManager) == address(0)) return unusedUnderlyingBalance();
    return unusedUnderlyingBalance().add(lotManager.balanceOfUnderlying());
  }

  function getPricePerFullShare() public override view returns (uint256) {
    return totalUnderlying().mul(1e18).div(zToken.totalSupply());
  }

  // LotManager

  function claimRewards() public override onlyManager returns (uint _rewards) {
    _rewards = lotManager.claimRewards();
    emit RewardsClaimed(_rewards);
  }

  function buyLots(uint256 _eth, uint256 _wbtc) public override onlyManager returns (bool) {
    uint _totalLots = _eth.add(_wbtc);
    require(unusedUnderlyingBalance() >= minTokenReserves.add(_totalLots.mul(lotManager.lotPrice())), 'hegic-pool/not-enough-reserves');
    // Gets available underlying. unused - reserves
    uint256 availableUnderlying = unusedUnderlyingBalance().sub(minTokenReserves);
    // Check and approve underlyingBalace to LotManager
    token.approve(address(lotManager), availableUnderlying);
    // Calls LotManager to buyLots
    require(lotManager.buyLots(_eth, _wbtc), 'hegic-pool/error-while-buying-lots');
    emit LotsBought(_eth, _wbtc);
    return true;
  }

  // Governable
  function setPendingGovernor(address _pendingGovernor) external override onlyGovernor {
    _setPendingGovernor(_pendingGovernor);
  }

  function acceptGovernor() external override onlyPendingGovernor {
    _acceptGovernor();
  }


  // Manageable
  function setPendingManager(address _pendingManager) external override onlyManager {
    _setPendingManager(_pendingManager);
  }

  function acceptManager() external override onlyPendingManager {
    _acceptManager();
  }

  // Protocol parameters
  function setMinTokenReserves(uint256 _minTokenReserves) external override onlyGovernor {
    _setMinTokenReserves(_minTokenReserves);
  }

  function setWithdrawCooldown(uint256 _withdrawCooldown) external override onlyGovernor {
    _setWithdrawCooldown(_withdrawCooldown);
  }

  function setWithdrawFee(uint256 _withdrawFee) external override onlyGovernor {
    _setWithdrawFee(_withdrawFee);
  }

  //
  function setLotManager(address _lotManager) external override onlyGovernor {
    require(ILotManager(_lotManager).isLotManager(), 'hegic-pool/invalid-lot-manager');
    lotManager = ILotManager(_lotManager);
    emit LotManagerSet(_lotManager);
  }

  // Collectable Dust
  function sendDust(
    address _to,
    address _token,
    uint256 _amount
  ) external override onlyGovernor {
    _sendDust(_to, _token, _amount);
  }
}