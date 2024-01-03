// SPDX-License-Identifier: Apache-2.0-with-puul-exception
pragma solidity >=0.6.12;
import "./SafeMath.sol";
import "./Address.sol";
import "./IERC20.sol";
import "./SafeERC20.sol";
import "./IUniswapV2Pair.sol";
import "./IUniswapV2Router02.sol";
import "./EarnPool.sol";
import "./IPoolFarmExtended.sol";
import "./UniswapPoolHelper.sol";
import "./IFarm.sol";
import "./UniswapHelper.sol";

contract UniswapPool is EarnPool, IPoolFarmExtended {
  using Address for address;
  using SafeMath for uint256;
  using SafeERC20 for IERC20;

  IERC20 private _token0;
  IERC20 private _token1;
  IUniswapV2Pair private _pair;
  UniswapHelper private _helper;

  uint256 MAX_UINT = 2**256 - 1;
  uint256 MAX_SLIPPAGE = 10000;

  constructor (string memory name, string memory symbol, address pair, bool allowAll, address fees) public EarnPool(name, symbol, allowAll, fees) {
    require(pair != address(0), 'pair == 0');
    _pair = IUniswapV2Pair(pair);
    _token0 = IERC20(_pair.token0());
    _token1 = IERC20(_pair.token1());
  }

  function setHelper(address helper) onlyAdmin external {
    require(helper != address(0));
    _helper = UniswapHelper(helper);
  }

  function _initialize() internal override returns(bool success) {
    _token0.safeApprove(address(UniswapPoolHelper.UNI_ROUTER), 0);
    _token0.safeApprove(address(UniswapPoolHelper.UNI_ROUTER), MAX_UINT);
    _token1.safeApprove(address(UniswapPoolHelper.UNI_ROUTER), 0);
    _token1.safeApprove(address(UniswapPoolHelper.UNI_ROUTER), MAX_UINT);
    return true;
  }

  function getPair() external view returns (address) {
    return address(_pair);
  }

  function depositFromToken(address token, uint256 amountA, uint256 amountB, uint256 minSwapA, uint256 minSwapB, uint256 slippageA, uint256 slippageB, uint256 slippageRemA, uint256 slippageRemB) onlyMember nonReentrant external {
    uint256 liquidity = UniswapPoolHelper.depositFromToken(address(_helper), token, amountA, amountB, _pair, minSwapA, minSwapB, slippageA, slippageB, slippageRemA, slippageRemB);
    _deposit(liquidity);
  }

  function depositPair(uint256 amount0, uint256 amount1, uint256 minA, uint256 minB) onlyMember nonReentrant external {
    uint256 liquidity = UniswapPoolHelper.depositPair(amount0, amount1, _pair, minA, minB);
    _deposit(liquidity);
  }

  function depositSingleSided(address token, uint256 amountA, uint256 amountB, uint256 minSwapB, uint256 slippageA, uint256 slippageB, uint256 slippageRemA, uint256 slippageRemB) onlyMember nonReentrant external {
    uint256 liquidity = UniswapPoolHelper.depositSingleSided(address(_helper), token, amountA, amountB, _pair, minSwapB, slippageA, slippageB, slippageRemA, slippageRemB);
    _deposit(liquidity);
  }

  function depositLPToken(uint256 amount) onlyMember nonReentrant external {
    uint256 liquidity = UniswapPoolHelper.depositLPToken(_pair, amount);
    _deposit(liquidity);
  }

  function getUsableBalance() internal view returns(uint256 balance) {
    balance = _pair.balanceOf(address(this));
  }

  function _harvestRewards() internal override {
    if (address(_farm) != address(0)) {
      _farm.harvest();
    }
  }

  function _earn() internal override {
    if (address(_farm) != address(0)) {
      uint256 amount = getUsableBalance();
      _pair.transfer(address(_farm), amount);
      _farm.earn();
    }
  }

  function unearn() onlyHarvester nonReentrant override virtual external {
    _unearnAll();
  }

  function liquidate() onlyHarvester nonReentrant virtual external {
    _unearnAll();
    // TODO
  }

  function _unearnAll() virtual internal {
    _unearn(totalSupply().sub(getUsableBalance(), 'unearn<0'));

  }

  function _unearn(uint256 amount) internal override {
    if (address(_farm) != address(0)) {
      uint256 balance = getUsableBalance();
      if (amount > balance) {
        _farm.withdraw(amount - balance);
      }
    }
  }

  function claimToToken(address token, uint[] memory amounts, uint[] memory mins) external override nonReentrant {
    _updateRewards(msg.sender, balanceOf(msg.sender), true);
    UniswapPoolHelper.claimToToken(_helper, token, amounts, mins, _owedRewards, _rewards, _rewardTotals);
  }

  function withdrawToToken(uint256 amount, address token, uint256 minA, uint256 minB, uint256 slippageA, uint256 slippageB) external nonReentrant {
    require(amount > 0 && amount <= balanceOf(msg.sender), '!amount');
    uint afterFee = _burnWithFee(msg.sender, amount);
    _unearn(afterFee);
    IERC20(address(_pair)).safeTransfer(address(_helper), afterFee);
    _helper.withdrawToToken(token, afterFee, msg.sender, _pair, minA, minB, slippageA, slippageB);
    emit Withdraw(msg.sender, amount);
  }

  function withdrawFees(uint256 amount, uint256 minA, uint256 minB) onlyWithdrawal nonReentrant virtual external nonReentrant {
    _withdrawFees(amount, minA, minB);
  }

  function _withdrawFees(uint256 amount, uint256 minA, uint256 minB) virtual internal returns(uint256) {
    address withdrawer = _fees.withdrawal();
    uint256 bal = balanceOf(withdrawer);
    require(amount > 0 && amount <= bal, '0<amount<bal');
    _unearn(amount);
    _removeLiquidity(IERC20(address(_pair)), amount, msg.sender, minA, minB);
    _burn(withdrawer, amount);
    return amount;
  }

  function withdrawFeesToToken(uint256 amount, address token, uint256 minA, uint256 minB, uint256 slippageA, uint256 slippageB) onlyWithdrawal nonReentrant external {
    address withdrawer = _fees.withdrawal();
    require(withdrawer != address(0), '!withdrawer');
    uint256 bal = balanceOf(withdrawer);
    require(amount > 0 && amount <= bal, '0<amount<bal');
    _unearn(amount);
    _burn(withdrawer, amount);
    IERC20(address(_pair)).safeTransfer(address(_helper), amount);
    _helper.withdrawToToken(token, amount, msg.sender, _pair, minA, minB, slippageA, slippageB);
    emit Withdraw(msg.sender, amount);
  }

  function withdrawLP(uint256 amount) nonReentrant external virtual {
    require(amount <= balanceOf(msg.sender));
    _withdraw(amount);
  }

  function _withdraw(uint256 amount) virtual override internal returns(uint256 afterFee) {
    afterFee = _burnWithFee(msg.sender, amount);
    _unearn(afterFee);
    IERC20(address(_pair)).safeTransfer(msg.sender, afterFee);
    emit Withdraw(msg.sender, amount);
  }

  function _withdrawFees() override internal returns(uint256 /*amount*/) {
  }

  function withdrawAll(uint256 minA, uint256 minB) nonReentrant external virtual {
    _withdraw(balanceOf(msg.sender), minA, minB);
  }

  function withdrawPair(uint256 amount, uint256 minA, uint256 minB) nonReentrant external virtual {
    require(amount <= balanceOf(msg.sender));
    _withdraw(amount, minA, minB);
  }

  function _withdraw(uint256 amount, uint256 minA, uint256 minB) virtual internal returns(uint256 afterFee) {
    afterFee = _burnWithFee(msg.sender, amount);
    _unearn(afterFee);
    _removeLiquidity(IERC20(address(_pair)), afterFee, msg.sender, minA, minB);
    emit Withdraw(msg.sender, amount);
}

  function _removeLiquidity(IERC20 pair, uint256 amount, address to, uint256 minA, uint256 minB) internal virtual returns(uint256 token0, uint256 token1) {
    pair.safeApprove(address(UniswapPoolHelper.UNI_ROUTER), 0);
    pair.safeApprove(address(UniswapPoolHelper.UNI_ROUTER), amount * 2);
    (token0, token1) = UniswapPoolHelper.UNI_ROUTER.removeLiquidity(address(_token0), address(_token1), amount, minA, minB, to, now.add(1800));
  }

  function _tokenInUse(address token) override virtual internal view returns(bool) {
    return token == address(_pair) || EarnPool._tokenInUse(token);
  }

}
