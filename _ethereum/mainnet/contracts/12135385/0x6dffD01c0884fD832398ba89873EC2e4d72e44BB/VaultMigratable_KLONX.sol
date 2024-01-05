pragma solidity 0.5.16;

import "./Vault.sol";

import "./IUniswapV2Router02.sol";
import "./console.sol";

interface Swap {
  function swap(uint256 amount) external;
}

contract VaultMigratable_KLONX is Vault {
  address public constant __wbtc = address(0x2260FAC5E5542a773Aa44fBCfeDf7C193bc2C599);
  address public constant __klon = address(0xB97D5cF2864FB0D08b34a484FF48d5492B2324A0);
  address public constant __klonx = address(0xbf15797BB5E47F6fB094A4abDB2cfC43F77179Ef);
  address public constant __wbtc_klon = address(0x734e48A1FfEA1cdF4F5172210C322f3990d6D760);
  address public constant __wbtc_klonx = address(0x69Cda6eDa9986f7fCa8A5dBa06c819B535F4Fc50);
  address public constant __wbtc_klonx_strategy = address(0);
  address public constant __uniswap = address(0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D);
  address public constant __governance = address(0xf00dD244228F51547f0563e60bCa65a30FBF5f7f);

  address public constant __klon_swap = address(0xAbD6341fc597031Ba698c481ABEDbA3C9a1aB587);

  event Migrated(uint256 v1Liquidity, uint256 v2Liquidity);
  event LiquidityRemoved(uint256 v1Liquidity, uint256 amountWbtc, uint256 amountKlon);
  event LiquidityProvided(uint256 wbtcContributed, uint256 klonxContributed, uint256 v2Liquidity);
  event AmountsLeft(uint256 wbtc, uint256 klonx);

  constructor() public {
  }

  /**
  * Migrates the vault from the WBTC/KLON underlying to WBTC/KLONX underlying
  */
  function migrateUnderlying(
    uint256 minWbtcOut, uint256 minKlonOut,
    uint256 minKlonXContribution, uint256 minWbtcContribution
  ) public onlyControllerOrGovernance {
    console.log("Here");
    require(underlying() == __wbtc_klon, "Can only migrate if the underlying is WBTC/KLON");
    withdrawAll();

    uint256 v1Liquidity = IERC20(__wbtc_klon).balanceOf(address(this));
    IERC20(__wbtc_klon).safeApprove(__uniswap, 0);
    IERC20(__wbtc_klon).safeApprove(__uniswap, v1Liquidity);

    (uint256 amountWbtc, uint256 amountKlon) = IUniswapV2Router02(__uniswap).removeLiquidity(
      __wbtc,
      __klon,
      v1Liquidity,
      minWbtcOut,
      minKlonOut,
      address(this),
      block.timestamp
    );
    emit LiquidityRemoved(v1Liquidity, amountWbtc, amountKlon);

    require(IERC20(__wbtc_klon).balanceOf(address(this)) == 0, "Not all underlying was converted");

    IERC20(__klon).safeApprove(__klon_swap, 0);
    IERC20(__klon).safeApprove(__klon_swap, uint256(-1));
    Swap(__klon_swap).swap(amountKlon);
    uint256 klonxBalance = IERC20(__klonx).balanceOf(address(this));

    IERC20(__klonx).safeApprove(__uniswap, 0);
    IERC20(__klonx).safeApprove(__uniswap, klonxBalance);
    IERC20(__wbtc).safeApprove(__uniswap, 0);
    IERC20(__wbtc).safeApprove(__uniswap, amountWbtc);

    (uint256 wbtcContributed,
      uint256 klonxContributed,
      uint256 v2Liquidity) = IUniswapV2Router02(__uniswap).addLiquidity(
        __wbtc,
        __klonx,
        amountWbtc, // amountADesired
        klonxBalance, // amountBDesired
        minWbtcContribution, // amountAMin
        minKlonXContribution, // amountBMin
        address(this),
        block.timestamp);

    emit LiquidityProvided(wbtcContributed, klonxContributed, v2Liquidity);

    _setUnderlying(__wbtc_klonx);
    require(underlying() == __wbtc_klonx, "underlying switch failed");
    _setStrategy(__wbtc_klonx_strategy);
    require(strategy() == __wbtc_klonx_strategy, "strategy switch failed");

    // some steps that regular setStrategy does
    IERC20(underlying()).safeApprove(address(strategy()), 0);
    IERC20(underlying()).safeApprove(address(strategy()), uint256(~0));

    uint256 wbtcLeft = IERC20(__wbtc).balanceOf(address(this));
    if (wbtcLeft > 0) {
      IERC20(__wbtc).transfer(__governance, wbtcLeft);
    }
    uint256 klonxLeft = IERC20(__klonx).balanceOf(address(this));
    if (klonxLeft > 0) {
      IERC20(__klonx).transfer(strategy(), klonxLeft);
    }
    emit AmountsLeft(wbtcLeft, klonxLeft);
    emit Migrated(v1Liquidity, v2Liquidity);
  }
}
