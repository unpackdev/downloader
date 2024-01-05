// SPDX-License-Identifier: MIT
pragma solidity ^0.7.6;
pragma experimental ABIEncoderV2;

// External imports
import "./SafeERC20.sol";
import "./IERC20.sol";
import "./SafeMath.sol";
import "./Context.sol";

// Internal imports
import "./IERC20Approvable.sol";
import "./IExchangeRates.sol";
import "./IBalancerPool.sol";
import "./ISystemStatus.sol";
import "./IExchanger.sol";
import "./ICurve.sol";

/**
 * ▄▄▄▄▄▄▄▄ ..▄▄ · ▄▄▌   ▄▄▄·
 * •██  ▀▄.▀·▐█ ▀. ██•  ▐█ ▀█
 *  ▐█.▪▐▀▀▪▄▄▀▀▀█▄██▪  ▄█▀▀█
 *  ▐█▌·▐█▄▄▌▐█▄▪▐█▐█▌▐▌▐█ ▪▐▌
 *  ▀▀▀  ▀▀▀  ▀▀▀▀ .▀▀▀  ▀  ▀
 */

/// @title Tesla Swap Contract
/// @author Affax
/// @dev Main contract for USDC -> sTSLA swap
/// In Code We Trust.
contract Tesla is Context {
  using SafeERC20 for IERC20Approvable;
  using SafeERC20 for IERC20;
  using SafeMath for uint256;

  // Tokens
  IERC20Approvable public USDC;
  IERC20 public sUSD;
  IERC20 public sTSLA;

  // External
  IExchangeRates public ExchangeRates;
  IBalancerPool public BalancerPool;
  IBalancerPool public TestnetPool;
  ISystemStatus public SystemStatus;
  IExchanger public Exchanger;
  ICurve public constant Curve = ICurve(0xA5407eAE9Ba41422680e2e00537571bcC53efBfD);

  bool public isTestnet;

  // Synthetix asset keys
  bytes32 public constant sTSLAKey = bytes32(0x7354534c41000000000000000000000000000000000000000000000000000000);
  bytes32 public constant sUSDKey = bytes32(0x7355534400000000000000000000000000000000000000000000000000000000);
  bytes32 public constant trackingCode = bytes32(0x53544f4e4b535741500000000000000000000000000000000000000000000000);

  receive() external payable {}

  event Swap(address indexed from, uint256 usdcIn, uint256 tslaOut);

  constructor(
    address _usdcAddress,
    address _susdAddress,
    address _stslaAddress,
    address _exchangeRatesAddress,
    address _poolAddress,
    address _tesnetPoolAddress,
    address _systemStatusAddress,
    address _synthetixAddress,
    bool _isTestnet
  ) {
    USDC = IERC20Approvable(_usdcAddress);
    sUSD = IERC20(_susdAddress);
    sTSLA = IERC20(_stslaAddress);

    ExchangeRates = IExchangeRates(_exchangeRatesAddress);
    BalancerPool = IBalancerPool(_poolAddress);
    TestnetPool = IBalancerPool(_tesnetPoolAddress);
    SystemStatus = ISystemStatus(_systemStatusAddress);
    Exchanger = IExchanger(_synthetixAddress);

    isTestnet = _isTestnet;

    USDC.safeApprove(address(Curve), uint256(-1));
    sUSD.safeApprove(_poolAddress, uint256(-1));

    if (_isTestnet) {
      USDC.safeApprove(_tesnetPoolAddress, uint256(-1));
    }
  }

  function exchange(
    uint256 _sourceAmount,
    bool _balancer,
    uint256 _deadline,
    uint8 _v,
    bytes32 _r,
    bytes32 _s
  ) external returns (uint256 amountReceived) {
    USDC.permit(_msgSender(), address(this), _sourceAmount, _deadline, _v, _r, _s);

    // Transfer in USDC
    USDC.safeTransferFrom(_msgSender(), address(this), _sourceAmount);

    if (isTestnet) {
      // Swap USDC for sUSDC on Balancer
      TestnetPool.swapExactAmountIn(address(USDC), _sourceAmount, address(sUSD), 0, uint256(-1));
    } else {
      // Exchange USDC to sUSD on Curve
      Curve.exchange(
        1, // USDC
        3, // sUSD
        _sourceAmount,
        0
      );
    }

    uint256 exchangedAmount = sUSD.balanceOf(address(this));

    if (exchangedAmount == 0) return 0;

    if (_balancer) {
      // Swap sUSD for sTSLA on Balancer
      (amountReceived, ) = BalancerPool.swapExactAmountIn(
        address(sUSD),
        exchangedAmount,
        address(sTSLA),
        0,
        uint256(-1)
      );

      sTSLA.safeTransfer(_msgSender(), sTSLA.balanceOf(address(this)));
    } else {
      // Swap sUSD for sTSLA on Synthetix exchange
      sUSD.safeTransfer(_msgSender(), exchangedAmount);

      amountReceived = Exchanger.exchangeOnBehalfWithTracking(
        _msgSender(),
        sUSDKey,
        exchangedAmount,
        sTSLAKey,
        _msgSender(),
        trackingCode
      );
    }

    emit Swap(_msgSender(), _sourceAmount, amountReceived);
  }

  function marketClosed() public view returns (bool closed) {
    (closed, ) = SystemStatus.synthExchangeSuspension(sTSLAKey);
  }

  function balancerOut(uint256 _amountIn) public view returns (uint256 amount) {
    uint256 susd = susdOut(_amountIn);

    uint256 sUSDAmount = BalancerPool.getBalance(address(sUSD));
    uint256 sTSLAAmount = BalancerPool.getBalance(address(sTSLA));
    uint256 sUSDWeight = BalancerPool.getDenormalizedWeight(address(sUSD));
    uint256 sTSLAWeight = BalancerPool.getDenormalizedWeight(address(sTSLA));
    uint256 fee = BalancerPool.getSwapFee();

    amount = BalancerPool.calcOutGivenIn(sUSDAmount, sUSDWeight, sTSLAAmount, sTSLAWeight, susd, fee);
  }

  function syntheticsOut(uint256 _amountIn) public view returns (uint256 amount) {
    if (marketClosed()) return 0;

    uint256 susd = susdOut(_amountIn);

    bytes32[] memory keys = new bytes32[](2);
    keys[0] = sUSDKey;
    keys[1] = sTSLAKey;

    uint256[] memory rates = ExchangeRates.ratesForCurrencies(keys);
    return susd.mul(rates[0]).div(rates[1]);
  }

  function susdOut(uint256 _amountIn) public view returns (uint256 amount) {
    if (isTestnet) {
      uint256 usdcAmount = TestnetPool.getBalance(address(USDC));
      uint256 sUSDAmount = TestnetPool.getBalance(address(sUSD));
      uint256 usdcWeight = TestnetPool.getDenormalizedWeight(address(USDC));
      uint256 sUSDWeight = TestnetPool.getDenormalizedWeight(address(sUSD));
      uint256 fee = BalancerPool.getSwapFee();

      amount = BalancerPool.calcOutGivenIn(usdcAmount, usdcWeight, sUSDAmount, sUSDWeight, _amountIn, fee);
    } else {
      amount = Curve.get_dy(
        1, // USDC
        3, // sUSD,
        _amountIn
      );
    }
  }
}
