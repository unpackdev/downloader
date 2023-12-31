// SPDX-License-Identifier: MIT

pragma solidity >=0.6.8;

import "./console.sol";

import "./SafeMath.sol";

import "./ERC20.sol";
import "./IERC20.sol";
import "./SafeERC20.sol";

import "./IHegicPoolV2.sol";

import "./ILotManager.sol";

import "./IUniswapV2.sol";
import "./IHegicStaking.sol";
import "./IWETH9.sol";

import "./Governable.sol";
import "./CollectableDust.sol";

import "./LotManagerMetadata.sol";

contract LotManager is
  Governable,
  CollectableDust,
  LotManagerMetadata,
  ILotManager {

  using SafeERC20 for IERC20;
  using SafeMath for uint256;

  uint256 public FEE_PRECISION = 10000;
  uint256 public MAX_FEE = 100 * FEE_PRECISION;
  uint256 public constant LOT_PRICE = 888_000e18;
  uint256 public fee = 10 * FEE_PRECISION;


  address public constant uniswapV2 = address(0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D);

  address public weth;
  address public wbtc;
  IHegicStaking public hegicStakingETH;
  IHegicStaking public hegicStakingWBTC;
  IHegicPoolV2 public pool;
  IERC20 public token;

  constructor(
    address _pool,
    address _weth,
    address _wbtc,
    address _hegicStakingETH,
    address _hegicStakingWBTC
  ) public
    Governable(msg.sender)
    CollectableDust()
    LotManagerMetadata()
  {

    weth = _weth;
    _addProtocolToken(_weth);
    wbtc = _wbtc;
    _addProtocolToken(_wbtc);

    _setPool(_pool);

    _setHegicStaking(_hegicStakingETH, _hegicStakingWBTC);
  }

  receive() external payable {
    emit ETHReceived(msg.sender, msg.value);
  }

  function lotPrice() external override view returns (uint256) {
    return LOT_PRICE;
  }

  function getPool() external override view returns (address) {
    return address(pool);
  }

  function balanceOfUnderlying() public override virtual view returns (uint256 _underlyingBalance) {
    (uint256 _ethLots, uint256 _wbtcLots) = balanceOfLots();
    return _ethLots.add(_wbtcLots).mul(LOT_PRICE);
  }
  function balanceOfLots() public override view returns (uint256 _ethLots, uint256 _wbtcLots) {
    return (
      hegicStakingETH.balanceOf(address(this)),
      hegicStakingWBTC.balanceOf(address(this))
    );
  }

  function setPool(address _pool) external override virtual onlyPool {
    _setPool(_pool);
  }

  function _setPool(address _pool) internal {
    require(_pool != address(0), 'lot-manager/setting-zero-address-pool');
    require(IHegicPoolMetadata(_pool).isHegicPool(), 'hegic-pool/not-setting-a-hegic-pool');

    IHegicPoolV2 _oldPool = pool;

    pool = IHegicPoolV2(_pool);
    address _newToken = pool.getToken();
    token = IERC20(_newToken);

    if (address(_oldPool) != address(0)) {
      _removeProtocolToken(address(_oldPool));
      if (_oldPool.getToken() != _newToken) {
        _removeProtocolToken(_oldPool.getToken());
        _addProtocolToken(_newToken);
      }
    } else {
      _addProtocolToken(_newToken);
    }

    _addProtocolToken(_pool);

    emit PoolSet(_pool, _newToken);
  }

  function setFee(uint256 _fee) external override onlyGovernor {
    require(_fee <= MAX_FEE, 'lot-manager/max-fee');
    fee = _fee;
    emit FeeSet(_fee);
  }

  function setHegicStaking(
    address _hegicStakingETH,
    address _hegicStakingWBTC
  ) external override onlyGovernor {
    _setHegicStaking(_hegicStakingETH, _hegicStakingWBTC);
  }

  function _setHegicStaking(
    address _hegicStakingETH,
    address _hegicStakingWBTC
  ) internal {

    address _currentHegicStakingETH = address(hegicStakingETH);
    if (_currentHegicStakingETH != _hegicStakingETH) {
      if (_currentHegicStakingETH != address(0)) {
        _removeProtocolToken(_currentHegicStakingETH);
      }
      _addProtocolToken(_hegicStakingETH);
    }
    hegicStakingETH = IHegicStaking(_hegicStakingETH);

    address _currentHegicStakingWBTC = address(hegicStakingWBTC);
    if (address(hegicStakingWBTC) != _hegicStakingWBTC) {
      if (_currentHegicStakingWBTC != address(0)) {
        _removeProtocolToken(_currentHegicStakingWBTC);
      }
      _addProtocolToken(_hegicStakingWBTC);
    }
    hegicStakingWBTC = IHegicStaking(_hegicStakingWBTC);

    emit HegicStakingSet(_hegicStakingETH, _hegicStakingWBTC);
  }

  function sellLots(uint256 _ethLots, uint256 _wbtcLots) external override virtual onlyGovernor returns (bool) {
    (uint256 _ownedETHLots, uint256 _ownedWBTCLots) = balanceOfLots();
    require (_ethLots <= _ownedETHLots && _wbtcLots <= _ownedWBTCLots, 'lot-manager/not-enough-lots');
    if (_ethLots > 0) _sellETHLots(_ethLots);
    if (_wbtcLots > 0) _sellWBTCLots(_wbtcLots);

    token.transfer(address(pool), token.balanceOf(address(this)));

    return true;
  }

  function migrate(address _newLotManager) external override virtual onlyGovernor {
    require(_newLotManager != address(0) && ILotManager(_newLotManager).isLotManager(), 'lot-manager/not-a-lot-manager');
    require(ILotManager(_newLotManager).getPool() == address(pool), 'lot-manager/migrate-pool-discrepancy');
    hegicStakingETH.transfer(_newLotManager, hegicStakingETH.balanceOf(address(this)));
    hegicStakingWBTC.transfer(_newLotManager, hegicStakingWBTC.balanceOf(address(this)));
    token.transfer(address(pool), token.balanceOf(address(this)));
    emit LotManagerMigrated(_newLotManager);
  }

  function buyLots(uint256 _ethLots, uint256 _wbtcLots) external override virtual onlyPool returns (bool) {
    uint256 allowance = token.allowance(address(pool), address(this));
    uint256 lotsCosts = _ethLots.add(_wbtcLots).mul(LOT_PRICE);
    require (allowance >= lotsCosts, 'lot-manager/not-enough-allowance');
    token.transferFrom(address(pool), address(this), lotsCosts);

    if (_ethLots > 0) _buyETHLots(_ethLots);
    if (_wbtcLots > 0) _buyWBTCLots(_wbtcLots);

    token.transfer(address(pool), token.balanceOf(address(this)));

    return true;
  }
  function _buyETHLots(uint256 _ethLots) internal {
    token.approve(address(hegicStakingETH), 0);
    token.approve(address(hegicStakingETH), _ethLots * LOT_PRICE);
    hegicStakingETH.buy(_ethLots);
    emit ETHLotBought(_ethLots);
  }
  function _buyWBTCLots(uint256 _wbtcLots) internal {
    token.approve(address(hegicStakingWBTC), 0);
    token.approve(address(hegicStakingWBTC), _wbtcLots * LOT_PRICE);
    hegicStakingWBTC.buy(_wbtcLots);
    emit WBTCLotBought(_wbtcLots);
  }

  function unwind(uint256 _amount) external override virtual onlyPool returns (uint256 _total) {
    return _unwind(_amount);
  }
  function _unwind(uint256 _amount) internal returns (uint256 _total) {
    (uint256 _ethLots, uint256 _wbtcLots) = balanceOfLots();
    require (_ethLots > 0 || _wbtcLots > 0, 'lot-manager/no-lots');

    bool areETHLotsUnlocked = hegicStakingETH.lastBoughtTimestamp(address(this)).add(hegicStakingETH.lockupPeriod()) <= block.timestamp;
    bool areWBTCLotsUnlocked = hegicStakingWBTC.lastBoughtTimestamp(address(this)).add(hegicStakingWBTC.lockupPeriod()) <= block.timestamp;
    require (areETHLotsUnlocked || areWBTCLotsUnlocked, 'lot-manager/no-unlocked-lots');
    _ethLots = areETHLotsUnlocked ? _ethLots : 0;
    _wbtcLots = areWBTCLotsUnlocked ? _wbtcLots : 0;
    uint256 _lotsToSell = _amount.div(LOT_PRICE).add(_amount.mod(LOT_PRICE) == 0 ? 0 : 1); // Only adds 1 lot on remaining
    require (_ethLots.add(_wbtcLots) >= _lotsToSell, 'lot-manager/not-enough-unlocked-lots');

    uint256 _totalSold = 0;

    if (_wbtcLots > 0) {
      _wbtcLots = _wbtcLots <_lotsToSell.sub(_totalSold) ? _wbtcLots : _lotsToSell.sub(_totalSold);
      _sellWBTCLots(_wbtcLots);
      _totalSold = _totalSold.add(_wbtcLots);
    }

    if (_ethLots > 0) {
      _ethLots = _ethLots <_lotsToSell.sub(_totalSold) ? _ethLots : _lotsToSell.sub(_totalSold);
      _sellETHLots(_ethLots);
      _totalSold = _totalSold.add(_ethLots);
    }

    require(_totalSold == _lotsToSell, 'lot-manager/not-enough-lots-sold');

    _total = _lotsToSell.mul(LOT_PRICE);

    token.transfer(address(pool), _total);

    emit Unwound(_total);
  }
  function _sellETHLots(uint256 _eth) internal {
    hegicStakingETH.sell(_eth);
    emit ETHLotSold(_eth);
  }
  function _sellWBTCLots(uint256 _wbtc) internal {
    hegicStakingWBTC.sell(_wbtc);
    emit WBTCLotSold(_wbtc);
  }

  function claimRewards() public override virtual onlyPool returns (uint256 _totalRewards) {
    uint256 _hegicStakingETHProfit = hegicStakingETH.profitOf(address(this));
    uint256 _hegicStakingWBTCProfit = hegicStakingWBTC.profitOf(address(this));
    require(_hegicStakingETHProfit > 0 || _hegicStakingWBTCProfit > 0, 'lot-manager/should-have-profits-to-claim-rewards');

    if (_hegicStakingETHProfit > 0) {
      hegicStakingETH.claimProfit();
      IWETH9(weth).deposit{value:payable(address(this)).balance}();

      _swapRewardForToken(weth, IERC20(weth).balanceOf(address(this)));
    }

    if (_hegicStakingWBTCProfit > 0) {
      hegicStakingWBTC.claimProfit();

      _swapRewardForToken(wbtc, IERC20(wbtc).balanceOf(address(this)));
    }

    _totalRewards = token.balanceOf(address(this));

    uint256 _fee = _totalRewards.mul(fee).div(FEE_PRECISION).div(100);

    token.approve(address(pool), 0);
    token.approve(address(pool), _fee);
    pool.deposit(_fee);

    IERC20 zToken = IERC20(pool.getZToken());
    zToken.transfer(governor, zToken.balanceOf(address(this)));

    token.transfer(address(pool), _totalRewards.sub(_fee));

    emit RewardsClaimed(_totalRewards, _fee);
  }

  function _swapRewardForToken(address _reward, uint256 _amount) internal {
    if (_amount == 0) return;
    require(_reward == weth || _reward == wbtc, 'lot-manager/only-weth-or-wbtc-rewards-allowed');

    IERC20(_reward).safeApprove(uniswapV2, 0);
    IERC20(_reward).safeApprove(uniswapV2, _amount);

    address[] memory path;
    if (_reward == weth) {
      path = new address[](2);
      path[0] = weth;
      path[1] = address(token);
    } else if (_reward == wbtc) {
      path = new address[](3);
      path[0] = wbtc;
      path[1] = weth;
      path[2] = address(token);
    }

    IUniswapV2(uniswapV2).swapExactTokensForTokens(_amount, uint256(0), path, address(this), now.add(1800));
  }

  modifier onlyPool {
    require(msg.sender == address(pool), 'lot-manager/only-pool');
    _;
  }

  function setPendingGovernor(address _pendingGovernor) external override onlyGovernor {
    _setPendingGovernor(_pendingGovernor);
  }

  function acceptGovernor() external override onlyPendingGovernor {
    _acceptGovernor();
  }

  function sendDust(
    address _to,
    address _token,
    uint256 _amount
  ) external override onlyGovernor {
    _sendDust(_to, _token, _amount);
  }
}
