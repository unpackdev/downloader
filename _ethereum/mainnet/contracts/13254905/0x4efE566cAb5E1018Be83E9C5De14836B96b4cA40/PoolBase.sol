// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity 0.7.6;
pragma abicoder v2;

/******************************************************************************\
* Author: Evert Kors <dev@sherlock.xyz> (https://twitter.com/evert0x)
* Sherlock Protocol: https://sherlock.xyz
/******************************************************************************/

import "./IPoolBase.sol";

import "./GovStorage.sol";

import "./LibPool.sol";

contract PoolBase is IPoolBase {
  using SafeMath for uint256;
  using SafeERC20 for IERC20;
  using SafeERC20 for ILock;

  //
  // View methods
  //

  function getCooldownFee(IERC20 _token) external view override returns (uint32) {
    return baseData(_token).activateCooldownFee;
  }

  function getSherXWeight(IERC20 _token) external view override returns (uint16) {
    return baseData(_token).sherXWeight;
  }

  function getGovPool(IERC20 _token) external view override returns (address) {
    return baseData(_token).govPool;
  }

  function isPremium(IERC20 _token) external view override returns (bool) {
    return baseData(_token).premiums;
  }

  function isStake(IERC20 _token) external view override returns (bool) {
    return baseData(_token).stakes;
  }

  function getProtocolBalance(bytes32 _protocol, IERC20 _token)
    external
    view
    override
    returns (uint256)
  {
    return baseData(_token).protocolBalance[_protocol];
  }

  function getProtocolPremium(bytes32 _protocol, IERC20 _token)
    external
    view
    override
    returns (uint256)
  {
    return baseData(_token).protocolPremium[_protocol];
  }

  function getLockToken(IERC20 _token) external view override returns (ILock) {
    return baseData(_token).lockToken;
  }

  function isProtocol(bytes32 _protocol, IERC20 _token) external view override returns (bool) {
    return baseData(_token).isProtocol[_protocol];
  }

  function getProtocols(IERC20 _token) external view override returns (bytes32[] memory) {
    return baseData(_token).protocols;
  }

  function getUnstakeEntry(
    address _staker,
    uint256 _id,
    IERC20 _token
  ) external view override returns (PoolStorage.UnstakeEntry memory) {
    return baseData(_token).unstakeEntries[_staker][_id];
  }

  function getTotalAccruedDebt(IERC20 _token) external view override returns (uint256) {
    baseData(_token);
    return LibPool.getTotalAccruedDebt(_token);
  }

  function getFirstMoneyOut(IERC20 _token) external view override returns (uint256) {
    return baseData(_token).firstMoneyOut;
  }

  function getAccruedDebt(bytes32 _protocol, IERC20 _token)
    external
    view
    override
    returns (uint256)
  {
    baseData(_token);
    return LibPool.accruedDebt(_protocol, _token);
  }

  function getTotalPremiumPerBlock(IERC20 _token) external view override returns (uint256) {
    return baseData(_token).totalPremiumPerBlock;
  }

  function getPremiumLastPaid(IERC20 _token) external view override returns (uint40) {
    return baseData(_token).totalPremiumLastPaid;
  }

  function getSherXUnderlying(IERC20 _token) external view override returns (uint256) {
    return baseData(_token).sherXUnderlying;
  }

  function getUnstakeEntrySize(address _staker, IERC20 _token)
    external
    view
    override
    returns (uint256)
  {
    return baseData(_token).unstakeEntries[_staker].length;
  }

  function getInitialUnstakeEntry(address _staker, IERC20 _token)
    external
    view
    override
    returns (uint256)
  {
    PoolStorage.Base storage ps = baseData(_token);
    GovStorage.Base storage gs = GovStorage.gs();
    for (uint256 i = 0; i < ps.unstakeEntries[_staker].length; i++) {
      if (ps.unstakeEntries[_staker][i].blockInitiated == 0) {
        continue;
      }
      if (
        ps.unstakeEntries[_staker][i].blockInitiated + gs.unstakeCooldown + gs.unstakeWindow <
        uint40(block.number)
      ) {
        continue;
      }
      return i;
    }
    return ps.unstakeEntries[_staker].length;
  }

  function getUnactivatedStakersPoolBalance(IERC20 _token)
    external
    view
    override
    returns (uint256)
  {
    return baseData(_token).stakeBalance;
  }

  function getStakersPoolBalance(IERC20 _token) public view override returns (uint256) {
    return LibPool.stakeBalance(baseData(_token));
  }

  function getStakerPoolBalance(address _staker, IERC20 _token)
    external
    view
    override
    returns (uint256)
  {
    PoolStorage.Base storage ps = baseData(_token);
    if (ps.lockToken.totalSupply() == 0) {
      return 0;
    }
    return
      ps.lockToken.balanceOf(_staker).mul(getStakersPoolBalance(_token)).div(
        ps.lockToken.totalSupply()
      );
  }

  function getTotalUnmintedSherX(IERC20 _token) external view override returns (uint256) {
    baseData(_token);
    return LibPool.getTotalUnmintedSherX(_token);
  }

  function getUnallocatedSherXStored(IERC20 _token) public view override returns (uint256) {
    return baseData(_token).unallocatedSherX;
  }

  function getUnallocatedSherXTotal(IERC20 _token) external view override returns (uint256) {
    return getUnallocatedSherXStored(_token).add(LibPool.getTotalUnmintedSherX(_token));
  }

  function getUnallocatedSherXFor(address _user, IERC20 _token)
    external
    view
    override
    returns (uint256)
  {
    baseData(_token);
    return LibPool.getUnallocatedSherXFor(_user, _token);
  }

  function getTotalSherXPerBlock(IERC20 _token) public view override returns (uint256) {
    return SherXStorage.sx().sherXPerBlock.mul(baseData(_token).sherXWeight).div(type(uint16).max);
  }

  function getSherXPerBlock(IERC20 _token) external view override returns (uint256) {
    return getSherXPerBlock(msg.sender, _token);
  }

  function getSherXPerBlock(address _user, IERC20 _token) public view override returns (uint256) {
    PoolStorage.Base storage ps = baseData(_token);
    if (ps.lockToken.totalSupply() == 0) {
      return 0;
    }
    return
      getTotalSherXPerBlock(_token).mul(ps.lockToken.balanceOf(_user)).div(
        ps.lockToken.totalSupply()
      );
  }

  function getSherXPerBlock(uint256 _lock, IERC20 _token) external view override returns (uint256) {
    // simulates staking (adding lock)
    if (_lock == 0) {
      return 0;
    }
    return
      getTotalSherXPerBlock(_token).mul(_lock).div(
        baseData(_token).lockToken.totalSupply().add(_lock)
      );
  }

  function getSherXLastAccrued(IERC20 _token) external view override returns (uint40) {
    return baseData(_token).sherXLastAccrued;
  }

  function LockToTokenXRate(IERC20 _token) external view override returns (uint256) {
    return LockToToken(10**18, _token);
  }

  function LockToToken(uint256 _amount, IERC20 _token) public view override returns (uint256) {
    PoolStorage.Base storage ps = baseData(_token);
    uint256 balance = LibPool.stakeBalance(ps);
    uint256 totalLock = ps.lockToken.totalSupply();
    if (totalLock == 0 || balance == 0) {
      revert('NO_DATA');
    }
    return balance.mul(_amount).div(totalLock);
  }

  function TokenToLockXRate(IERC20 _token) external view override returns (uint256) {
    return TokenToLock(10**18, _token);
  }

  function TokenToLock(uint256 _amount, IERC20 _token) public view override returns (uint256) {
    PoolStorage.Base storage ps = baseData(_token);
    uint256 balance = LibPool.stakeBalance(ps);
    uint256 totalLock = ps.lockToken.totalSupply();
    if (totalLock == 0 || balance == 0) {
      return 10**18;
    }
    return totalLock.mul(_amount).div(balance);
  }

  //
  // State changing methods
  //

  function setCooldownFee(uint32 _fee, IERC20 _token) external override {
    require(msg.sender == GovStorage.gs().govMain, 'NOT_GOV_MAIN');

    baseData(_token).activateCooldownFee = _fee;
  }

  function depositProtocolBalance(
    bytes32 _protocol,
    uint256 _amount,
    IERC20 _token
  ) external override {
    require(_amount != 0, 'AMOUNT');
    require(GovStorage.gs().protocolIsCovered[_protocol], 'PROTOCOL');
    PoolStorage.Base storage ps = baseData(_token);
    require(ps.isProtocol[_protocol], 'NO_DEPOSIT');

    _token.safeTransferFrom(msg.sender, address(this), _amount);
    ps.protocolBalance[_protocol] = ps.protocolBalance[_protocol].add(_amount);
  }

  function withdrawProtocolBalance(
    bytes32 _protocol,
    uint256 _amount,
    address _receiver,
    IERC20 _token
  ) external override {
    require(msg.sender == GovStorage.gs().protocolAgents[_protocol], 'SENDER');
    require(_amount != 0, 'AMOUNT');
    require(_receiver != address(0), 'RECEIVER');
    PoolStorage.Base storage ps = baseData(_token);

    LibPool.payOffDebtAll(_token);

    if (_amount == type(uint256).max) {
      _amount = ps.protocolBalance[_protocol];
    }

    _token.safeTransfer(_receiver, _amount);
    ps.protocolBalance[_protocol] = ps.protocolBalance[_protocol].sub(_amount);
  }

  function activateCooldown(uint256 _amount, IERC20 _token) external override returns (uint256) {
    require(_amount != 0, 'AMOUNT');
    PoolStorage.Base storage ps = baseData(_token);

    ps.lockToken.safeTransferFrom(msg.sender, address(this), _amount);
    uint256 fee = _amount.mul(ps.activateCooldownFee).div(type(uint32).max);
    if (fee != 0) {
      // stake of user gets burned
      // representative amount token get added to first money out pool
      uint256 tokenAmount = fee.mul(LibPool.stakeBalance(ps)).div(ps.lockToken.totalSupply());
      ps.firstMoneyOut = ps.firstMoneyOut.add(tokenAmount);

      ps.lockToken.burn(address(this), fee);
    }

    ps.unstakeEntries[msg.sender].push(
      PoolStorage.UnstakeEntry(uint40(block.number), _amount.sub(fee))
    );

    return ps.unstakeEntries[msg.sender].length - 1;
  }

  function cancelCooldown(uint256 _id, IERC20 _token) external override {
    PoolStorage.Base storage ps = baseData(_token);
    GovStorage.Base storage gs = GovStorage.gs();

    PoolStorage.UnstakeEntry memory withdraw = ps.unstakeEntries[msg.sender][_id];
    require(withdraw.blockInitiated != 0, 'WITHDRAW_NOT_ACTIVE');

    require(
      withdraw.blockInitiated + gs.unstakeCooldown >= uint40(block.number),
      'COOLDOWN_EXPIRED'
    );
    delete ps.unstakeEntries[msg.sender][_id];
    ps.lockToken.safeTransfer(msg.sender, withdraw.lock);
  }

  function unstakeWindowExpiry(
    address _account,
    uint256 _id,
    IERC20 _token
  ) external override {
    PoolStorage.Base storage ps = baseData(_token);
    GovStorage.Base storage gs = GovStorage.gs();

    PoolStorage.UnstakeEntry memory withdraw = ps.unstakeEntries[_account][_id];
    require(withdraw.blockInitiated != 0, 'WITHDRAW_NOT_ACTIVE');

    require(
      withdraw.blockInitiated + gs.unstakeCooldown + gs.unstakeWindow < uint40(block.number),
      'UNSTAKE_WINDOW_NOT_EXPIRED'
    );
    delete ps.unstakeEntries[_account][_id];
    ps.lockToken.safeTransfer(_account, withdraw.lock);
  }

  function unstake(
    uint256 _id,
    address _receiver,
    IERC20 _token
  ) external override returns (uint256 amount) {
    PoolStorage.Base storage ps = baseData(_token);
    require(_receiver != address(0), 'RECEIVER');
    GovStorage.Base storage gs = GovStorage.gs();
    PoolStorage.UnstakeEntry memory withdraw = ps.unstakeEntries[msg.sender][_id];
    require(withdraw.blockInitiated != 0, 'WITHDRAW_NOT_ACTIVE');
    // period is including
    require(withdraw.blockInitiated + gs.unstakeCooldown < uint40(block.number), 'COOLDOWN_ACTIVE');
    require(
      withdraw.blockInitiated + gs.unstakeCooldown + gs.unstakeWindow >= uint40(block.number),
      'UNSTAKE_WINDOW_EXPIRED'
    );
    amount = withdraw.lock.mul(LibPool.stakeBalance(ps)).div(ps.lockToken.totalSupply());

    ps.stakeBalance = ps.stakeBalance.sub(amount);
    delete ps.unstakeEntries[msg.sender][_id];
    ps.lockToken.burn(address(this), withdraw.lock);
    _token.safeTransfer(_receiver, amount);
  }

  function payOffDebtAll(IERC20 _token) external override {
    baseData(_token);
    LibPool.payOffDebtAll(_token);
  }

  function cleanProtocol(
    bytes32 _protocol,
    uint256 _index,
    bool _forceDebt,
    address _receiver,
    IERC20 _token
  ) external override {
    require(msg.sender == GovStorage.gs().govMain, 'NOT_GOV_MAIN');
    require(_receiver != address(0), 'RECEIVER');

    PoolStorage.Base storage ps = baseData(_token);
    require(ps.protocols[_index] == _protocol, 'INDEX');

    // If protocol has 0 accrued debt, the premium should also be 0
    // If protocol has >0 accrued debt, needs to be bigger then balance
    // Otherwise just update premium to 0 for the protocol first and then delete
    uint256 accrued = LibPool.accruedDebt(_protocol, _token);
    if (accrued == 0) {
      require(ps.protocolPremium[_protocol] == 0, 'CAN_NOT_DELETE');
    } else {
      require(accrued > ps.protocolBalance[_protocol], 'CAN_NOT_DELETE2');
    }

    // send the remainder of the protocol balance to the sherx underlying
    if (_forceDebt && accrued != 0) {
      ps.sherXUnderlying = ps.sherXUnderlying.add(ps.protocolBalance[_protocol]);
      delete ps.protocolBalance[_protocol];
    }

    // send any leftovers back to the protocol receiver
    if (ps.protocolBalance[_protocol] != 0) {
      _token.safeTransfer(_receiver, ps.protocolBalance[_protocol]);
      delete ps.protocolBalance[_protocol];
    }

    // move last index to index of _protocol
    ps.protocols[_index] = ps.protocols[ps.protocols.length - 1];
    // remove last index
    ps.protocols.pop();
    ps.isProtocol[_protocol] = false;
    // could still be >0, if accrued more debt than needed.
    if (ps.protocolPremium[_protocol] != 0) {
      ps.totalPremiumPerBlock = ps.totalPremiumPerBlock.sub(ps.protocolPremium[_protocol]);
      delete ps.protocolPremium[_protocol];
    }
  }

  function baseData(IERC20 _token) internal view returns (PoolStorage.Base storage ps) {
    ps = PoolStorage.ps(_token);
    require(ps.govPool != address(0), 'INVALID_TOKEN');
  }
}
