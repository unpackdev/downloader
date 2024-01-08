pragma solidity 0.5.16;

import "./Vault.sol";
import "./ICurveDeposit_3token.sol";

contract VaultMigratable_Tricrypto is Vault {
  address public constant __wbtc = address(0x2260FAC5E5542a773Aa44fBCfeDf7C193bc2C599);
  address public constant __weth = address(0xC02aaA39b223FE8D0A0e5C4F27eAD9083C756Cc2);
  address public constant __usdt = address(0xdAC17F958D2ee523a2206206994597C13D831ec7);
  address public constant __minterOld = address(0x80466c64868E1ab14a1Ddf27A676C3fcBE638Fe5);
  address public constant __tricrypto = address(0xcA3d75aC011BF5aD07a98d02f18225F9bD9A6BDF);
  address public constant __minterNew = address(0xD51a44d3FaE010294C616388b506AcdA1bfAAE46);
  address public constant __tricrypto2 = address(0xc4AD29ba4B3c580e6D59105FFf484999997675Ff);
  address public constant __governance = address(0xf00dD244228F51547f0563e60bCa65a30FBF5f7f);

  event Migrated(uint256 v1Liquidity, uint256 v2Liquidity);
  event LiquidityRemoved(uint256 v1Liquidity, uint256 amountUsdt, uint256 amountWbtc, uint256 amountWeth);
  event LiquidityProvided(uint256 amountUsdt, uint256 amountWbtc, uint256 amountWeth, uint256 v2Liquidity);
  event AmountsLeft(uint256 usdtLeft, uint256 wbtcLeft, uint256 wethLeft);

  constructor() public {
  }

  /**
  * Migrates the vault from underlying to new underlying
  */
  function migrateUnderlying(
    uint256 minUsdtOut, uint256 minWbtcOut, uint256 minWethOut,
    uint256 minUsdtContribution, uint256 minWbtcContribution, uint256 minWethContribution,
    uint256 minLiquidityV2Amount, address newStrategy
  ) public onlyControllerOrGovernance {
    require(underlying() == __tricrypto, "Can only migrate if the underlying is tricrypto");
    withdrawAll();

    uint256 v1Liquidity = IERC20(__tricrypto).balanceOf(address(this));
    ICurveDeposit_3token(__minterOld).remove_liquidity(v1Liquidity, [minUsdtOut, minWbtcOut, minWethOut]);
    uint256 usdtBalance = IERC20(__usdt).balanceOf(address(this));
    uint256 wbtcBalance = IERC20(__wbtc).balanceOf(address(this));
    uint256 wethBalance = IERC20(__weth).balanceOf(address(this));

    emit LiquidityRemoved(v1Liquidity, usdtBalance, wbtcBalance, wethBalance);
    require(IERC20(__tricrypto).balanceOf(address(this)) == 0, "Not all underlying was removed");

    IERC20(__usdt).safeApprove(__minterNew, 0);
    IERC20(__wbtc).safeApprove(__minterNew, 0);
    IERC20(__weth).safeApprove(__minterNew, 0);
    IERC20(__usdt).safeApprove(__minterNew, usdtBalance);
    IERC20(__wbtc).safeApprove(__minterNew, wbtcBalance);
    IERC20(__weth).safeApprove(__minterNew, wethBalance);
    ICurveDeposit_3token(__minterNew).add_liquidity(
      [usdtBalance, wbtcBalance, wethBalance], minLiquidityV2Amount
    );
    uint256 v2Liquidity = IERC20(__tricrypto2).balanceOf(address(this));
    emit LiquidityProvided(v2Liquidity, usdtBalance, wbtcBalance, wethBalance);

    _setUnderlying(__tricrypto2);
    require(underlying() == __tricrypto2, "underlying switch failed");
    _setStrategy(newStrategy);
    require(strategy() == newStrategy, "strategy switch failed");

    // some steps that regular setStrategy does
    IERC20(underlying()).safeApprove(address(strategy()), 0);
    IERC20(underlying()).safeApprove(address(strategy()), uint256(~0));

    uint256 wbtcLeft = IERC20(__wbtc).balanceOf(address(this));
    if (wbtcLeft > 0) {
      IERC20(__wbtc).safeTransfer(__governance, wbtcLeft);
    }
    uint256 wethLeft = IERC20(__weth).balanceOf(address(this));
    if (wethLeft > 0) {
      IERC20(__weth).safeTransfer(strategy(), wethLeft);
    }
    uint256 usdtLeft = IERC20(__usdt).balanceOf(address(this));
    if (usdtLeft > 0) {
      IERC20(__usdt).safeTransfer(strategy(), usdtLeft);
    }
    emit AmountsLeft(usdtLeft, wbtcLeft, wethLeft);
    emit Migrated(v1Liquidity, v2Liquidity);
  }
}
