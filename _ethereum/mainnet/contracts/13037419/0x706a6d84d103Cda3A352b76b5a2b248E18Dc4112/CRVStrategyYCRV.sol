// SPDX-License-Identifier: None
pragma solidity 0.6.12;

import "./BoilerplateStrategy.sol";

import "./ICurveFi_Gauge.sol";
import "./ICurveFi_Minter.sol";
import "./ICurveFi_DepositY.sol";
import "./IYERC20.sol";
import "./IUniswapV2Router02.sol";

/**
* This strategy is for the yCRV vault, i.e., the underlying token is yCRV. It is not to accept
* stable coins. It will farm the CRV crop. For liquidation, it swaps CRV into DAI and uses DAI
* to produce yCRV.
*/

contract CRVStrategyYCRV is IStrategy, BoilerplateStrategy {
    using SafeERC20 for IERC20;
    using SafeMath for uint256;

    // yDAIyUSDCyUSDTyTUSD (yCRV)
    address public pool; //aka Gauge
    address public mintr;
    address public crv;

    address public curve; // aka DepositY
    address public dai;

    address public uniswapRouter;

    address[] public uniswap_CRV2DAI;

    constructor(
        address _vault,
        address _underlying,
        address _strategist,
        address _pool,
        address _curve,
        address _dai,
        address _uniswap
    ) public BoilerplateStrategy(_vault, _underlying, _strategist) {
        require(IVault(_vault).token() == _underlying, "vault does not support underlying");
        pool = _pool;
        require(ICurveFi_Gauge(pool).lp_token() == _underlying, "Incorrect Gauge");

        mintr = ICurveFi_Gauge(pool).minter();
        crv = ICurveFi_Gauge(pool).crv_token();
        curve = _curve;
        dai = _dai;

        uniswapRouter = _uniswap;
        uniswap_CRV2DAI = [crv, IUniswapV2Router02(uniswapRouter).WETH(), dai];

        // set these tokens to be not salvageable
        unsalvageableTokens[underlying] = true;
        unsalvageableTokens[crv] = true;
    }

    /*****
    * VIEW INTERFACE
    *****/

    function getNameStrategy() external override view returns(string memory){
        return "CRVStrategyYCRV";
    }

    function want() external override view returns(address){
        return address(underlying);
    }

    /**
    * Balance of invested.
    */
    function balanceOf() public override view returns (uint256) {
        return ICurveFi_Gauge(pool).balanceOf(address(this)).add(
            IERC20(underlying).balanceOf(address(this))
        );
    }

    /*****
    * DEPOSIT/WITHDRAW/HARVEST EXTERNAL
    *****/

    /**
    * Invests all the underlying yCRV into the pool that mints crops (CRV_.
    */
    function deposit() public override restricted {
        uint256 underlyingBalance = IERC20(underlying).balanceOf(address(this));
        if (underlyingBalance > 0) {
            IERC20(underlying).safeApprove(pool, 0);
            IERC20(underlying).safeApprove(pool, underlyingBalance);
            ICurveFi_Gauge(pool).deposit(underlyingBalance);
        }
    }

    /**
    * Withdraws the yCRV tokens from the pool in the specified amount.
    */
    function withdraw(uint256 amountUnderlying) public override restricted {
        require(amountUnderlying > 0, "Incorrect amount");
        if (harvestOnWithdraw && liquidationAllowed) {
            claimAndLiquidateCrv();
        }
        uint256 balanceUnderlying = ICurveFi_Gauge(pool).balanceOf(address(this));
        uint256 looseBalance = IERC20(underlying).balanceOf(address(this));
        uint256 total = balanceUnderlying.add(looseBalance);

        if (amountUnderlying > total) {
            //cant withdraw more than we own
            amountUnderlying = total;
        }

        if (looseBalance >= amountUnderlying) {
            IERC20(underlying).safeTransfer(vault, amountUnderlying);
            return;
        }

        uint256 toWithdraw = amountUnderlying.sub(looseBalance);
        withdrawYCrvFromPool(toWithdraw);

        looseBalance = IERC20(underlying).balanceOf(address(this));
        IERC20(underlying).safeTransfer(vault, looseBalance);
    }

    /**
    * Withdraws all the yCRV tokens to the pool.
    */
    function withdrawAll() external override restricted {
      if (harvestOnWithdraw && liquidationAllowed) {
          claimAndLiquidateCrv();
      }
      uint256 balanceUnderlying = ICurveFi_Gauge(pool).balanceOf(address(this));
      withdrawYCrvFromPool(balanceUnderlying);

      uint256 balance = IERC20(underlying).balanceOf(address(this));
      IERC20(underlying).safeTransfer(vault, balance);
    }

    function emergencyExit() external onlyGovernance {
        claimAndLiquidateCrv();

        uint256 balanceUnderlying = ICurveFi_Gauge(pool).balanceOf(address(this));
        withdrawYCrvFromPool(balanceUnderlying);

        uint256 balance = IERC20(underlying).balanceOf(address(this));
        IERC20(underlying).safeTransfer(IVault(vault).governance(), balance);
    }

  /**
  * Claims and liquidates CRV into yCRV, and then invests all underlying.
  */
  function earn() public restricted {
      if (liquidationAllowed) {
          claimAndLiquidateCrv();
      }

      deposit();
  }


    function convert(address) external override returns(uint256){
        return 0;
    }

    function skim()  override external {
        revert("Can't skim");
    }


    /**
    * Claims the CRV crop, converts it to DAI on Uniswap, and then uses DAI to mint yCRV using the
    * Curve protocol.
    */
    function claimAndLiquidateCrv() public {
        ICurveFi_Minter(mintr).mint(pool);
        // claiming rewards and sending them to the master strategy

        uint256 crvBalance = IERC20(crv).balanceOf(address(this));

        if (crvBalance > sellFloor) {
            uint256 daiBalanceBefore = IERC20(dai).balanceOf(address(this));
            IERC20(crv).safeApprove(uniswapRouter, 0);
            IERC20(crv).safeApprove(uniswapRouter, crvBalance);
            // we can accept 1 as the minimum because this will be called only by a trusted worker
            IUniswapV2Router02(uniswapRouter).swapExactTokensForTokens(
              crvBalance, 1, uniswap_CRV2DAI, address(this), block.timestamp + 10
            );
            // now we have DAI
            // pay fee before making yCRV
            _profitSharing(IERC20(dai).balanceOf(address(this)) - daiBalanceBefore);

            // liquidate if there is any DAI left
            yCurveFromDai();
            // now we have yCRV
        }
    }

  /**
  * Withdraws yCRV from the investment pool that mints crops.
  */
  function withdrawYCrvFromPool(uint256 amount) internal {
      Gauge(pool).withdraw(amount);
  }

  /**
  * Converts all DAI to yCRV using the CRV protocol.
  */
  function yCurveFromDai() internal {
    uint256 daiBalance = IERC20(dai).balanceOf(address(this));
    if (daiBalance > 0) {
        IERC20(dai).safeApprove(curve, 0);
        IERC20(dai).safeApprove(curve, daiBalance);
        uint256 minimum = 0;
        ICurveFi_DepositY(curve).add_liquidity([daiBalance, 0, 0, 0], minimum);
    }
    // now we have yCRV
  }

  function _profitSharing(uint256 amount) internal override {
      if (profitSharingNumerator == 0) {
          return;
      }
      uint256 feeAmount = amount.mul(profitSharingNumerator).div(profitSharingDenominator);
      emit ProfitShared(amount, feeAmount, block.timestamp);

      if(feeAmount > 0) {
        IERC20(dai).safeTransfer(controller, feeAmount);
      }
  }
}