pragma solidity 0.7.3;

import "./Math.sol";
import "./SafeMath.sol";
import "./SafeERC20.sol";
import "./IStrategy.sol";
import "./IVault.sol";
import "./IStorage.sol";
import "./IUniswapV2Router02.sol";
import "./IdleToken.sol";
import "./IIdleTokenHelper.sol";
import "./ControllableInit.sol";

contract IdleFinanceStrategy is ControllableInit {

  using SafeMath for uint256;
  using SafeERC20 for IERC20;

  event ProfitsNotCollected(address);
  event Liquidating(address, uint256);

  address public referral;
  IERC20 public underlying;
  address public idleUnderlying;
  uint256 public virtualPrice;
  IIdleTokenHelper public idleTokenHelper;

  address public mainUnderlying;

  address public vault;
  address public storageAddress;
  address public comp;
  address public idle;

  address[] public uniswapComp;
  address[] public uniswapIdle;

  address public uniswapRouterV2;

  bool public sellComp;
  bool public sellIdle;
  bool public claimAllowed;
  bool public protected;

  mapping (address => bool) public unsalvagableTokens;

  address[] public path;

  modifier restricted() {
    require(msg.sender == vault || msg.sender == address(controller()) || msg.sender == address(governance()),
      "The sender has to be the controller or vault or governance");
    _;
  }

  modifier updateVirtualPrice() {
    if (protected) {
      require(virtualPrice <= idleTokenHelper.getRedeemPrice(idleUnderlying), "virtual price is higher than needed");
    }
    _;
    virtualPrice = idleTokenHelper.getRedeemPrice(idleUnderlying);
  }

  constructor(
    address _storage,
    address _underlying,
    address _idleUnderlying,
    address _vault,
    address _comp,
    address _idle,
    address _weth,
    address _uniswap
  ) public {
    comp = _comp;
    idle = _idle;
    underlying = IERC20(_underlying);
    idleUnderlying = _idleUnderlying;
    vault = _vault;
    storageAddress = _storage;
    uniswapRouterV2 = _uniswap;
    protected = true;

    ControllableInit.initialize(_storage);

    // set these tokens to be not salvagable
    unsalvagableTokens[_underlying] = true;
    unsalvagableTokens[_idleUnderlying] = true;
    unsalvagableTokens[_comp] = true;
    unsalvagableTokens[_idle] = true;

    uniswapComp = [_comp, _weth, _idle];
    uniswapIdle = [_idle, _weth, _underlying];
    referral = address(0xf00dD244228F51547f0563e60bCa65a30FBF5f7f);
    sellComp = true;
    sellIdle = true;
    claimAllowed = true;

    idleTokenHelper = IIdleTokenHelper(0x04Ce60ed10F6D2CfF3AA015fc7b950D13c113be5);
    virtualPrice = idleTokenHelper.getRedeemPrice(idleUnderlying);

    mainUnderlying = IStorage(_storage).mainUnderlying();
  }

  function depositArbCheck() public view returns(bool) {
    return true;
  }

  function setReferral(address _newRef) public onlyGovernance {
    referral = _newRef;
  }

  function swapAllMainUnderlyingToUnderlying() public restricted {
    uint256 _mainUnderlyingBalance = IERC20(mainUnderlying).balanceOf(address(this));

    IERC20(mainUnderlying).safeApprove(uniswapRouterV2, 0);
    IERC20(mainUnderlying).safeApprove(uniswapRouterV2, _mainUnderlyingBalance);

    path = [mainUnderlying, address(underlying)];

    if (mainUnderlying != address(underlying)) {
      IUniswapV2Router02(uniswapRouterV2).swapExactTokensForTokens(
        _mainUnderlyingBalance,
        0,
        path,
        address(this),
        block.timestamp.add(60)
      );
    }
  }

  function swapAllUnderlyingToMainUnderlying() public restricted {
    uint256 _underlyingBalance = IERC20(underlying).balanceOf(address(this));

    IERC20(underlying).safeApprove(uniswapRouterV2, 0);
    IERC20(underlying).safeApprove(uniswapRouterV2, _underlyingBalance);

    path = [address(underlying), mainUnderlying];

    if (mainUnderlying != address(underlying)) {
      IUniswapV2Router02(uniswapRouterV2).swapExactTokensForTokens(
        _underlyingBalance,
        0,
        path,
        address(this),
        block.timestamp.add(60)
      );
    }
  }

  function swapUnderlyingToMainUnderlying(uint256 amount) public restricted returns (uint256) {
    uint256 _underlyingBalance = IERC20(underlying).balanceOf(address(this));
    if (amount > _underlyingBalance) {
      amount = _underlyingBalance;
    }

    IERC20(underlying).safeApprove(uniswapRouterV2, 0);
    IERC20(underlying).safeApprove(uniswapRouterV2, amount);

    path = [address(underlying), mainUnderlying];
    uint256[] memory amounts;

    if (mainUnderlying != address(underlying)) {
      amounts = IUniswapV2Router02(uniswapRouterV2).swapExactTokensForTokens(
        amount,
        0,
        path,
        address(this),
        block.timestamp.add(60)
      );
      return amounts[1];
    }
    return amount;
  }

  /**
  * The strategy invests by supplying the underlying token into IDLE.
  */
  function investAllUnderlying() public restricted updateVirtualPrice {
    uint256 balance = underlying.balanceOf(address(this));
    swapAllMainUnderlyingToUnderlying();
    underlying.safeApprove(address(idleUnderlying), 0);
    underlying.safeApprove(address(idleUnderlying), balance);
    IIdleTokenV3_1(idleUnderlying).mintIdleToken(balance, true, referral);
  }

  /**
  * Exits IDLE and transfers everything to the vault.
  */
  function withdrawAllToVault() external restricted updateVirtualPrice {
    withdrawAll();
    swapAllUnderlyingToMainUnderlying();
    IERC20(mainUnderlying).safeTransfer(vault, IERC20(mainUnderlying).balanceOf(address(this)));
  }

  /**
  * Withdraws all from IDLE
  */
  function withdrawAll() internal {
    uint256 balance = IERC20(idleUnderlying).balanceOf(address(this));

    // this automatically claims the crops
    IIdleTokenV3_1(idleUnderlying).redeemIdleToken(balance);

    liquidateComp();
    liquidateIdle();
  }

  function withdrawToVault(uint256 amountUnderlying) public restricted {
    // this method is called when the vault is missing funds
    // we will calculate the proportion of idle LP tokens that matches
    // the underlying amount requested
    uint256 balanceBefore = underlying.balanceOf(address(this));
    uint256 totalIdleLpTokens = IERC20(idleUnderlying).balanceOf(address(this));
    uint256 totalUnderlyingBalance = totalIdleLpTokens.mul(virtualPrice).div(1e18);
    uint256 ratio = amountUnderlying.mul(1e18).div(totalUnderlyingBalance);
    uint256 toRedeem = totalIdleLpTokens.mul(ratio).div(1e18);
    IIdleTokenV3_1(idleUnderlying).redeemIdleToken(toRedeem);
    uint256 balanceAfter = underlying.balanceOf(address(this));

    uint256 balanceToWithdraw = balanceAfter.sub(balanceBefore);
    swapUnderlyingToMainUnderlying(balanceToWithdraw);

    IERC20(mainUnderlying).safeTransfer(vault, balanceAfter.sub(balanceBefore));
  }

  /**
  * Withdraws all assets, liquidates COMP, and invests again in the required ratio.
  */
  function doHardWork() public restricted updateVirtualPrice {
    if (claimAllowed) {
      claim();
    }
    liquidateComp();
    liquidateIdle();

    // this updates the virtual price
    investAllUnderlying();

    // state of supply/loan will be updated by the modifier
  }

  /**
  * Salvages a token.
  */
  function salvage(address recipient, address token, uint256 amount) public onlyGovernance {
    // To make sure that governance cannot come in and take away the coins
    require(!unsalvagableTokens[token], "token is defined as not salvagable");
    IERC20(token).safeTransfer(recipient, amount);
  }

  function claim() internal {
    IIdleTokenV3_1(idleUnderlying).redeemIdleToken(0);
  }

  function liquidateComp() internal {
    if (!sellComp) {
      // Profits can be disabled for possible simplified and rapid exit
      emit ProfitsNotCollected(comp);
      return;
    }

    // no profit notification, comp is liquidated to IDLE and will be notified there

    uint256 compBalance = IERC20(comp).balanceOf(address(this));
    if (compBalance > 0) {
      emit Liquidating(address(comp), compBalance);
      IERC20(comp).safeApprove(uniswapRouterV2, 0);
      IERC20(comp).safeApprove(uniswapRouterV2, compBalance);
      // we can accept 1 as the minimum because this will be called only by a trusted worker
      IUniswapV2Router02(uniswapRouterV2).swapExactTokensForTokens(
        compBalance, 1, uniswapComp, address(this), block.timestamp
      );
    }
  }

  function liquidateIdle() internal {
    if (!sellIdle) {
      // Profits can be disabled for possible simplified and rapid exit
      emit ProfitsNotCollected(idle);
      return;
    }

    uint256 rewardBalance = IERC20(idle).balanceOf(address(this));

    uint256 idleBalance = IERC20(idle).balanceOf(address(this));
    if (idleBalance > 0) {
      emit Liquidating(address(idle), idleBalance);
      IERC20(idle).safeApprove(uniswapRouterV2, 0);
      IERC20(idle).safeApprove(uniswapRouterV2, idleBalance);
      // we can accept 1 as the minimum because this will be called only by a trusted worker
      IUniswapV2Router02(uniswapRouterV2).swapExactTokensForTokens(
        idleBalance, 1, uniswapIdle, address(this), block.timestamp
      );
    }
  }

  /**
  * Returns the current balance. Ignores COMP that was not liquidated and invested.
  */
  function investedUnderlyingBalance() public view returns (uint256) {
    // NOTE: The use of virtual price is okay for appreciating assets inside IDLE,
    // but would be wrong and exploitable if funds were lost by IDLE, indicated by
    // the virtualPrice being greater than the token price.
    if (protected) {
      require(virtualPrice <= idleTokenHelper.getRedeemPrice(idleUnderlying), "virtual price is higher than needed");
    }
    uint256 invested = IERC20(idleUnderlying).balanceOf(address(this)).mul(virtualPrice).div(1e18);
    return invested.add(IERC20(underlying).balanceOf(address(this))).add(IERC20(mainUnderlying).balanceOf(address(this)));
  }

  function setLiquidation(bool _sellComp, bool _sellIdle, bool _claimAllowed) public onlyGovernance {
    sellComp = _sellComp;
    sellIdle = _sellIdle;
    claimAllowed = _claimAllowed;
  }

  function setProtected(bool _protected) public onlyGovernance {
    protected = _protected;
  }
}
