// SPDX-License-Identifier: MIT
// Fork of EthAnchor's ConversionPool.sol
pragma solidity >=0.6.0 <0.8.0;

import "./Initializable.sol";

import "./IERC20.sol";
import "./SafeERC20.sol";
import "./SafeMath.sol";
import "./Math.sol";

import "./Context.sol";
import "./OwnableUpgradeable.sol";

import "./ConversionPool.sol";
import "./ExchangeRateFeeder.sol";

import "./ERC20Controlled.sol";
import "./RouterV2.sol";

contract SwaplessConversionPool is IConversionPool, OwnableUpgradeable {
    using Math for uint256;
    using SafeMath for uint256;
    using SafeERC20 for IERC20;
    using SafeERC20 for IERC20Controlled;

     // pool token settings
    IERC20 public inputToken;
    IERC20Controlled public outputToken;  // vaUST

    // proxy settings
    IERC20 public proxyInputToken;   // For compatibility purposes. Equals to inputToken.
    IERC20 public proxyOutputToken;  // aUST
    uint256 public proxyReserve;     // aUST reserve

    uint256 public inputToken10PowDecimals;  // 10^decimals for inputToken, i.e. amount equals to $1

    address public optRouter;

    // implementation of IExchangeRateFeeder required to access feeder.tokens[inputToken].weight
    ExchangeRateFeeder public feeder;

    // flags
    bool public isDepositAllowed;
    bool public isRedemptionAllowed;

    function initialize(
      // ===== tokens
      string memory _outputTokenName,
      string memory _outputTokenSymbol,
      address _inputToken,
      address _proxyOutputToken,
      // ===== others
      address _optRouter,
      address _exchangeRateFeeder,
      // =====
      uint32 _inputTokenDecimals
    ) public virtual initializer {
      require(_inputTokenDecimals <= 70);

      OwnableUpgradeable.__Ownable_init();

      inputToken = IERC20(_inputToken);
      outputToken = new ERC20Controlled(_outputTokenName, _outputTokenSymbol);

      proxyInputToken = IERC20(_inputToken);          //
      proxyOutputToken = IERC20(_proxyOutputToken);
      proxyReserve = 0;

      inputToken10PowDecimals = 10 ** _inputTokenDecimals;

      setOperationRouter(_optRouter);
      setExchangeRateFeeder(_exchangeRateFeeder);

      isDepositAllowed = true;
      isRedemptionAllowed = true;
    }

    function setOperationRouter(address _optRouter) public onlyOwner {
      require(_optRouter != address(0), "Invalid zero address");

      optRouter = _optRouter;
      proxyInputToken.safeApprove(optRouter, type(uint256).max);
      proxyOutputToken.safeApprove(optRouter, type(uint256).max);
    }

    function setExchangeRateFeeder(address _exchangeRateFeeder) public onlyOwner {
      require(_exchangeRateFeeder != address(0), "Invalid zero address");

      feeder = ExchangeRateFeeder(_exchangeRateFeeder);
    }

    function setDepositAllowance(bool _allow) public onlyOwner {
      isDepositAllowed = _allow;
    }

    function setRedemptionAllowance(bool _allow) public onlyOwner {
      isRedemptionAllowed = _allow;
    }

    // migrate
    function migrate(address _to) public onlyOwner {
        require(
            !(isDepositAllowed && isRedemptionAllowed),
            "ConversionPool: invalid status"
        );
        require(_to != address(0), "Invalid zero address");

        proxyOutputToken.transfer(
            _to,
            proxyOutputToken.balanceOf(address(this))
        );
    }

    // reserve

    function provideReserve(uint256 _amount) public {
      proxyReserve = proxyReserve.add(_amount);
      proxyOutputToken.safeTransferFrom(
          super._msgSender(),
          address(this),
          _amount
      );
    }

    function removeReserve(uint256 _amount) public onlyOwner {
      proxyReserve = proxyReserve.sub(_amount);
      proxyOutputToken.safeTransfer(super._msgSender(), _amount);
    }

    // operations

    modifier _updateExchangeRate {
      feeder.update(address(inputToken));

      _;
    }

    function getShuttleFee(uint256 _amount) internal view returns(uint256) {
      // max($1, 0.1% * _amount)
      return _amount.div(1000).max(inputToken10PowDecimals);
    }

    function getFeederRate() internal view returns(uint256) {
      (/* ExchangeRateFeeder.Status status */,
       /* uint256 exchangeRate */,
       /* uint256 period */,
       uint256 weight,
       /* uint256 lastUpdatedAt */) = feeder.tokens(address(inputToken));

      require(weight > 1e18);  // rate > 1.0

      return weight;
    }

    function deposit(uint256 _amount) public override _updateExchangeRate {
      require(isDepositAllowed, "ConversionPool: deposit not stopped");

      inputToken.safeTransferFrom(super._msgSender(), address(this), _amount);

      IRouterV2(optRouter).depositStable(_amount);

      uint256 pER = feeder.exchangeRateOf(address(inputToken), false);
      uint256 pERRecentEpoch = pER.mul(getFeederRate()).div(1e18);

      uint256 amountWithoutFee = _amount.sub(getShuttleFee(_amount));
      outputToken.mint(super._msgSender(), amountWithoutFee.mul(1e18).div(pERRecentEpoch));
    }

    function deposit(uint256 _amount, uint256 _minAmountOut) public override {
      deposit(_amount);
    }

    function redeem(uint256 _amount) public override _updateExchangeRate {
      require(isRedemptionAllowed, "ConversionPool: redemption not allowed");

      outputToken.burnFrom(super._msgSender(), _amount);

      IRouterV2(optRouter).redeemStable(super._msgSender(), _amount);
    }

    function redeem(uint256 _amount, uint256 _minAmountOut) public override {
      redeem(_amount);
    }

    function profitAmount() public view returns (uint256) {
      uint256 proxyOutputTokenBalance = proxyOutputToken.balanceOf(address(this));

      if (proxyReserve >= proxyOutputTokenBalance) return 0;

      // total output token amount - proxy output token amount (this pool) - proxyReserve = earnable amount
      uint256 outputTokenTotal = outputToken.totalSupply();
      uint256 available = proxyOutputTokenBalance.sub(proxyReserve);

      if (available < outputTokenTotal) return 0;

      return available - outputTokenTotal;
    }

    function takeProfit(address _receiver) public onlyOwner {
      require(_receiver != address(0), "Invalid zero address");

      uint256 proxyOutputTokenBalance = proxyOutputToken.balanceOf(address(this));

      require(proxyReserve < proxyOutputTokenBalance, "ConversionPool: not enough balance");

      // total output token amount - proxy output token amount (this pool) - proxyReserve = earnable amount
      uint256 outputTokenTotal = outputToken.totalSupply();
      uint256 available = proxyOutputTokenBalance.sub(proxyReserve);

      require(available > outputTokenTotal, "ConversionPool: no funds available to take a profit");

      uint256 earnAmount = available.sub(outputTokenTotal);
      proxyOutputToken.safeTransfer(_receiver, earnAmount);
    }
}
