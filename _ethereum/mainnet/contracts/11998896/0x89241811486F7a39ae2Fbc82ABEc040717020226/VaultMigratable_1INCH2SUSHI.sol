pragma solidity 0.5.16;

import "./Vault.sol";

import "./IUniswapV2Router02.sol";
import "./IUniswapV2Router02.sol";
import "./IMooniswap.sol";
import "./IStrategy.sol";
import "./IInvestmentVaultStrategy.sol";
import "./console.sol";

contract VaultMigratable_1INCH2SUSHI is Vault {
  event LiquidityRemoved(uint256 v1Liquidity, uint256 actualTokenAmount, uint256 actualEthAmount);
  event LiquidityProvided(uint256 v2Liquidity, uint256 actualTokenAmount, uint256 actualEthAmount);
  event Remainders(uint256 tokenLeft, uint256 ethLeft);

  address public constant wbtc = 0x2260FAC5E5542a773Aa44fBCfeDf7C193bc2C599;
  address public constant usdt = 0xdAC17F958D2ee523a2206206994597C13D831ec7;
  address public constant usdc = 0xA0b86991c6218b36c1d19D4a2e9Eb0cE3606eB48;
  address public constant dai = 0x6B175474E89094C44Da98b954EedeAC495271d0F;

  address public constant wbtcVaultSushi = 0x5C0A3F55AAC52AA320Ff5F280E77517cbAF85524;
  address public constant usdtVaultSushi = 0x64035b583c8c694627A199243E863Bb33be60745;
  address public constant usdcVaultSushi = 0x01bd09A1124960d9bE04b638b142Df9DF942b04a;
  address public constant daiVaultSushi = 0x203E97aa6eB65A1A02d9E80083414058303f241E;

  address public constant wbtcVaultOneInch = 0x859222DD0B249D0ea960F5102DaB79B294d6874a;
  address public constant daiVaultOneInch = 0x8e53031462E930827a8d482e7d80603B1f86e32d;
  address public constant usdcVaultOneInch = 0xD162395C21357b126C5aFED6921BC8b13e48D690;
  address public constant usdtVaultOneInch = 0x4bf633A09bd593f6fb047Db3B4C25ef5B9C5b99e;

  address public constant wbtcOneInchUnderlying = 0x6a11F3E5a01D129e566d783A7b6E8862bFD66CcA;
  address public constant daiOneInchUnderlying = 0x7566126f2fD0f2Dddae01Bb8A6EA49b760383D5A;
  address public constant usdcOneInchUnderlying = 0xb4dB55a20E0624eDD82A0Cf356e3488B4669BD27;
  address public constant usdtOneInchUnderlying = 0xbBa17b81aB4193455Be10741512d0E71520F43cB;

  address public constant sushiswap = 0xd9e1cE17f2641f24aE83637ab66a2cca9C378B9F;
  uint256 public constant base = 10000;

  mapping (address => address) public originalUnderlying;
  mapping (address => address) public targetVault;

  constructor() public {
  }

  /**
  * Migrates the vault from the old 1inch underlying to the new Sushi underlying
  */
  function migrateUnderlying(
    uint256 minTokenOut, uint256 minEthOut,
    uint256 maxDepositSlippage // 10000 = 100%
  ) public onlyControllerOrGovernance {

    // approve sushiswap for adding liquidity
    IERC20(wbtc).safeApprove(sushiswap, uint256(-1));
    IERC20(usdt).safeApprove(sushiswap, uint256(-1));
    IERC20(usdc).safeApprove(sushiswap, uint256(-1));
    IERC20(dai).safeApprove(sushiswap, uint256(-1));

    originalUnderlying[wbtcVaultOneInch] = wbtcOneInchUnderlying;
    originalUnderlying[daiVaultOneInch] = daiOneInchUnderlying;
    originalUnderlying[usdcVaultOneInch] = usdcOneInchUnderlying;
    originalUnderlying[usdtVaultOneInch] = usdtOneInchUnderlying;

    targetVault[wbtcVaultOneInch] = wbtcVaultSushi;
    targetVault[daiVaultOneInch] = daiVaultSushi;
    targetVault[usdtVaultOneInch] = usdtVaultSushi;
    targetVault[usdcVaultOneInch] = usdcVaultSushi;

    require(underlying() == originalUnderlying[address(this)], "Already migrated");

    // withdrawing all from strategy
    withdrawAll();

    // removing liquidity from Mooniswap
    {
      uint256[] memory mins = new uint256[](2);
      mins[0] = minEthOut;
      mins[1] = minTokenOut;
      uint256 v1Liquidity = IERC20(underlying()).balanceOf(address(this));
      uint256[2] memory withdrawnAmounts = IMooniswap(underlying()).withdraw(v1Liquidity, mins);

      emit LiquidityRemoved(v1Liquidity, withdrawnAmounts[1], withdrawnAmounts[0]);
    }

    // adding liquidity to Uniswap
    {
      uint256 ethAmount = address(this).balance;
      uint256 tokenAmount = IERC20(IMooniswap(underlying()).token1()).balanceOf(address(this));
      uint256 actualTokenAmount;
      uint256 actualEthAmount;
      uint256 v2Liquidity;

      (actualTokenAmount, actualEthAmount, v2Liquidity) = IUniswapV2Router02(sushiswap).addLiquidityETH.value(ethAmount)(
        IMooniswap(underlying()).token1(),
        tokenAmount,
        tokenAmount.mul(base.sub(maxDepositSlippage)).div(base),
        ethAmount.mul(base.sub(maxDepositSlippage)).div(base),
        address(this),
        block.timestamp
      );

      emit LiquidityProvided(v2Liquidity, actualTokenAmount, actualEthAmount);
    }

    {
      address token = IMooniswap(underlying()).token1();

      // deposit to the new vault and send left overs
      uint256 tokenLeft = IERC20(token).balanceOf(address(this));
      if (tokenLeft > 0) {
        IERC20(token).safeTransfer(msg.sender, tokenLeft);
      }
      uint256 ethLeft = address(this).balance;
      if (ethLeft > 0) {
        msg.sender.transfer(ethLeft);
      }

      emit Remainders(tokenLeft, ethLeft);
    }

    require(IERC20(underlying()).balanceOf(address(this)) == 0, "Not all underlying was converted");

    _setUnderlying(IVault(targetVault[address(this)]).underlying());
    require(underlying() == IVault(targetVault[address(this)]).underlying(), "underlying switch failed");

    _setStrategy(address(0));
    require(strategy() == address(0), "strategy clearing failed");
  }

  function() external payable {}

  function salvageEth(address payable recipient, uint256 amount) public onlyGovernance {
    recipient.transfer(amount);
  }

  /*
  * Deposits are disabled for migrated vaults.
  */
  function deposit(uint256 amount) external {
    require(amount > 0, "amount must be greater than 0"); // to silence the warning
    revert("Deposits are disabled for migrated vaults. Withdrawals are allowed");
  }

  // the code has to be cloned from Vault.sol instead of super.withdraw()
  // as withdraw was defined as external in Vault.sol
  function withdraw(uint256 numberOfShares) external {
    require(totalSupply() > 0, "Vault has no shares");
    require(numberOfShares > 0, "numberOfShares must be greater than 0");
    uint256 totalSupply = totalSupply();
    _burn(msg.sender, numberOfShares);

    uint256 underlyingAmountToWithdraw = underlyingBalanceWithInvestment()
        .mul(numberOfShares)
        .div(totalSupply);
    if (underlyingAmountToWithdraw > underlyingBalanceInVault()) {
      // withdraw everything from the strategy to accurately check the share value
      if (numberOfShares == totalSupply) {
        IStrategy(strategy()).withdrawAllToVault();
      } else {
        uint256 missing = underlyingAmountToWithdraw.sub(underlyingBalanceInVault());
        IStrategy(strategy()).withdrawToVault(missing);
      }
      // recalculate to improve accuracy
      underlyingAmountToWithdraw = Math.min(underlyingBalanceWithInvestment()
          .mul(numberOfShares)
          .div(totalSupply), underlyingBalanceInVault());
    }

    IERC20(underlying()).safeTransfer(msg.sender, underlyingAmountToWithdraw);

    // skip if there is no active strategy
    if(strategy() != address(0)) {
      // require that the underlying strategy is a strategy that invests to another vault
      require(IInvestmentVaultStrategy(strategy()).hodlApproved(), "strategy doesn't invest in other fvaults");

      // get all the rewards then loop through them to distribute to the user.
      IInvestmentVaultStrategy(strategy()).getAllRewards();
      for(uint256 i = 0; i < IInvestmentVaultStrategy(strategy()).rewardTokensLength(); i = i.add(1)){
        address rt = IInvestmentVaultStrategy(strategy()).rewardTokens(i);
        uint256 rtBalanceInStrategy = IERC20(rt).balanceOf(strategy());
        uint256 rtToWithdraw = rtBalanceInStrategy.mul(numberOfShares).div(totalSupply);
        IERC20(rt).safeTransferFrom(strategy(), msg.sender, rtToWithdraw);
      }
    }

    // update the withdrawal amount for the holder
    emit Withdraw(msg.sender, underlyingAmountToWithdraw);
  }
}
