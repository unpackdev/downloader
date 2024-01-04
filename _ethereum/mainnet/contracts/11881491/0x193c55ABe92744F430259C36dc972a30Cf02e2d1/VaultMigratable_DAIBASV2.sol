pragma solidity 0.5.16;

import "./Vault.sol";

import "./IUniswapV2Router02.sol";

interface IBASSwap {
  function swap(uint256 amount) external;
}

contract VaultMigratable_DAIBASV2 is Vault {
  address public constant __dai = address(0x6B175474E89094C44Da98b954EedeAC495271d0F);
  address public constant __bas = address(0xa7ED29B253D8B4E3109ce07c80fc570f81B63696);
  address public constant __basv2 = address(0x106538CC16F938776c7c180186975BCA23875287);
  address public constant __dai_bas = address(0x0379dA7a5895D13037B6937b109fA8607a659ADF);
  address public constant __dai_basv2 = address(0x3E78F2E7daDe07ea685F8612F00477FD97162F1e);
  address public constant __dai_basv2_strategy = address(0x1adAfE68f46e0aEcd5364b85966C8C16D4079361);
  address public constant __uniswap = address(0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D);
  address public constant __governance = address(0xf00dD244228F51547f0563e60bCa65a30FBF5f7f);

  address public constant __bas_swap = address(0xBBEE5349F1F564B6638d6723125877cb48B86fd1);

  event Migrated(uint256 v1Liquidity, uint256 v2Liquidity);
  event LiquidityRemoved(uint256 v1Liquidity, uint256 amountDai, uint256 amountBas);
  event LiquidityProvided(uint256 basV2Contributed, uint256 daiContributed, uint256 v2Liquidity);

  constructor() public {
  }

  /**
  * Migrates the vault from the BAS/DAI underlying to BASV2/DAI underlying
  */
  function migrateUnderlying(
    uint256 minDaiOut, uint256 minBasOut,
    uint256 minBasV2Contribution, uint256 minDaiContribution
  ) public onlyControllerOrGovernance {
    require(underlying() == __dai_bas, "Can only migrate if the underlying is BAS/DAI");
    withdrawAll();

    uint256 v1Liquidity = IERC20(__dai_bas).balanceOf(address(this));
    IERC20(__dai_bas).safeApprove(__uniswap, 0);
    IERC20(__dai_bas).safeApprove(__uniswap, v1Liquidity);

    (uint256 amountDai, uint256 amountBas) = IUniswapV2Router02(__uniswap).removeLiquidity(
      __dai,
      __bas,
      v1Liquidity,
      minDaiOut,
      minBasOut,
      address(this),
      block.timestamp
    );
    emit LiquidityRemoved(v1Liquidity, amountDai, amountBas);

    require(IERC20(__dai_bas).balanceOf(address(this)) == 0, "Not all underlying was converted");

    IERC20(__bas).safeApprove(__bas_swap, 0);
    IERC20(__bas).safeApprove(__bas_swap, uint256(-1));
    IBASSwap(__bas_swap).swap(amountBas);
    uint256 basV2Balance = IERC20(__basv2).balanceOf(address(this));

    IERC20(__basv2).safeApprove(__uniswap, 0);
    IERC20(__basv2).safeApprove(__uniswap, basV2Balance);
    IERC20(__dai).safeApprove(__uniswap, 0);
    IERC20(__dai).safeApprove(__uniswap, amountDai);

    (uint256 basV2Contributed,
      uint256 daiContributed,
      uint256 v2Liquidity) = IUniswapV2Router02(__uniswap).addLiquidity(
        __basv2,
        __dai,
        basV2Balance, // amountADesired
        amountDai, // amountBDesired
        minBasV2Contribution, // amountAMin
        minDaiContribution, // amountBMin
        address(this),
        block.timestamp);

    emit LiquidityProvided(basV2Contributed, daiContributed, v2Liquidity);

    _setUnderlying(__dai_basv2);
    require(underlying() == __dai_basv2, "underlying switch failed");
    _setStrategy(__dai_basv2_strategy);
    require(strategy() == __dai_basv2_strategy, "strategy switch failed");

    // some steps that regular setStrategy does
    IERC20(underlying()).safeApprove(address(strategy()), 0);
    IERC20(underlying()).safeApprove(address(strategy()), uint256(~0));

    uint256 daiLeft = IERC20(__dai).balanceOf(address(this));
    if (daiLeft > 0) {
      IERC20(__dai).transfer(__governance, daiLeft);
    }
    uint256 basV2Left = IERC20(__basv2).balanceOf(address(this));
    if (basV2Left > 0) {
      IERC20(__basv2).transfer(strategy(), basV2Left);
    }

    emit Migrated(v1Liquidity, v2Liquidity);
  }
}
