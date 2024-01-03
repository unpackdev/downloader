// SPDX-License-Identifier: MIT

pragma solidity >=0.6.8;

import "./IERC20.sol";

import "./IHegicPoolV2.sol";
import "./IHegicStaking.sol";

import "./IZTreasuryV2.sol";
import "./ILotManagerV2ProtocolParameters.sol";

abstract
contract LotManagerV2ProtocolParameters is ILotManagerV2ProtocolParameters {

  uint256 public constant override LOT_PRICE = 888_000e18;

  uint256 public constant override FEE_PRECISION = 10000;
  uint256 public constant override MAX_PERFORMANCE_FEE = 50 * FEE_PRECISION;
  
  address public override uniswapV2 = address(0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D);

  uint256 public override performanceFee;
  IZTreasuryV2 public override zTreasury;

  address public override weth;
  address public override wbtc;
  IHegicStaking public override hegicStakingETH;
  IHegicStaking public override hegicStakingWBTC;

  IHegicPoolV2 public override pool;
  IERC20 public override token;

  constructor(
    uint256 _performanceFee,
    address _zTreasury,
    address _pool,
    address _weth,
    address _wbtc,
    address _hegicStakingETH,
    address _hegicStakingWBTC
  ) public {
    _setPerformanceFee(_performanceFee);
    _setZTreasury(_zTreasury);
    _setPool(_pool);
    _setWETH(_weth);
    _setWBTC(_wbtc);
    _setHegicStaking(_hegicStakingETH, _hegicStakingWBTC);
  }

  function lotPrice() external override view returns (uint256) {
    return LOT_PRICE;
  }

  function getPool() external override view returns (address) {
    return address(pool);
  }

  function _setPerformanceFee(uint256 _performanceFee) internal {
    require(_performanceFee <= MAX_PERFORMANCE_FEE, 'LotManagerV2ProtocolParameters::_setPerformanceFee::bigger-than-max');
    performanceFee = _performanceFee;
    emit PerformanceFeeSet(_performanceFee);
  }
  
  function _setZTreasury(address _zTreasury) internal {
    require(_zTreasury != address(0), 'LotManagerV2ProtocolParameters::_setZTreasury::not-zero-address');
    require(IZTreasuryV2(_zTreasury).isZTreasury(), 'LotManagerV2ProtocolParameters::_setZTreasury::not-treasury');
    zTreasury = IZTreasuryV2(_zTreasury);
    emit ZTreasurySet(_zTreasury);
  }

  function _setPool(address _pool) internal {
    require(_pool != address(0), 'LotManagerV2ProtocolParameters::_setPool::not-zero-address');
    require(IHegicPoolMetadata(_pool).isHegicPool(), 'LotManagerV2ProtocolParameters::_setPool::not-setting-a-hegic-pool');
    pool = IHegicPoolV2(_pool);
    token = IERC20(pool.getToken());
    emit PoolSet(_pool, address(token));
  }

  function _setWETH(address _weth) internal {
    require(_weth != address(0), 'LotManagerV2ProtocolParameters::_setWETH::not-zero-address');
    weth = _weth;
    emit WETHSet(_weth);
  }

  function _setWBTC(address _wbtc) internal {
    require(_wbtc != address(0), 'LotManagerV2ProtocolParameters::_setWBTC::not-zero-address');
    wbtc = _wbtc;
    emit WBTCSet(_wbtc);
  }

  function _setHegicStaking(
    address _hegicStakingETH,
    address _hegicStakingWBTC
  ) internal {
    require(
      _hegicStakingETH != address(0) && 
      _hegicStakingWBTC != address(0), 
      'LotManagerV2ProtocolParameters::_setHegicStaking::not-zero-addresses'
    );

    hegicStakingETH = IHegicStaking(_hegicStakingETH);
    hegicStakingWBTC = IHegicStaking(_hegicStakingWBTC);

    emit HegicStakingSet(_hegicStakingETH, _hegicStakingWBTC);
  }
}