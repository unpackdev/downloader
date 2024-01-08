// SPDX-License-Identifier: None
pragma solidity 0.6.12;

import "./BoilerplateStrategy.sol";

import "./IUniswapV2Router02.sol";
import "./ICurveFi_Gauge.sol";
import "./ICurveFi_Minter.sol";
import "./ICurveFiWbtc.sol";


contract CRVStrategyWRenBTCMix is IStrategy, BoilerplateStrategy {
    enum TokenIndex {REN_BTC, WBTC}

    using SafeERC20 for IERC20;
    using SafeMath for uint256;

    // the matching enum record used to determine the index
    TokenIndex tokenIndex;
    // the address of the Curve protocol's pool for REN + WBTC
    address public curve; //aka Swap

    // the wbtc gauge in Curve
    address public gauge;

    // the reward minter
    address public mintr;

    // the address for the CRV token
    address public crv;

    // uniswap router address
    address public uniswapRouter;

    // the address of the second asset(wBTC or renBTC). Depends on the underlying
    address public secondAsset;

    // liquidation path to be used
    address[] public uniswap_CRV2WBTC;

    event Liquidating(uint256 amount);
    event NotLiquidating(uint256 amount);
    event ProfitsNotCollected();

    constructor(
        address _vault,
        address _underlying, // aka WBTC or RenBTC
        address _strategist,
        uint256 _tokenIndex,
        address _curvePool,
        address _gauge,
        address _uniswap,
        address _secondAsset
    ) public  BoilerplateStrategy(_vault,_underlying,_strategist) {
        require(IVault(_vault).token() == _underlying, "vault does not support underlying");
        require(_secondAsset != _underlying, "second asset and underlying can not be equal");
        tokenIndex = TokenIndex(_tokenIndex);

        gauge = _gauge;
        secondAsset = _secondAsset;

        mintr = ICurveFi_Gauge(gauge).minter();
        crv = ICurveFi_Gauge(gauge).crv_token();

        curve = _curvePool;

        uniswapRouter = _uniswap;

        uniswap_CRV2WBTC = [crv, IUniswapV2Router02(uniswapRouter).WETH(), underlying];

        // set these tokens to be not salvageable
        unsalvageableTokens[underlying] = true;
        unsalvageableTokens[crv] = true;
    }

    /*****
     * VIEW INTERFACE
     *****/

    /// @notice Returns the name of the strategy
    /// @dev The name is set when the strategy is deployed
    /// @return Returns the name of the strategy
    function getNameStrategy() external view override returns (string memory) {
        return "CRVStrategyWRenBTCMix";
    }

    /// @notice Returns the want address of the strategy
    /// @dev The want is set when the strategy is deployed
    /// @return Returns the name of the strategy
    function want() external view override returns (address) {
        return address(underlying);
    }

    /// @notice Shows the balance of the strategy.
    function balanceOf() external view override returns (uint256) {
        return investedUnderlyingBalance().add(IERC20(underlying).balanceOf(address(this)));
    }

    /*****
    * DEPOSIT/WITHDRAW/HARVEST EXTERNAL
    *****/
    
    /// @notice Transfers tokens for earnings
    function deposit() public override restricted {
        mixFromWBTC();
        investMixedCoin();
    }

    /**
    * Withdraws the yCRV tokens from the pool in the specified amount.
    */
    function withdraw(uint256 amountUnderlying) public override restricted {
        require(amountUnderlying > 0, "Incorrect amount");
        if (harvestOnWithdraw && liquidationAllowed) {
            claimAndLiquidateCrv();
        }

        uint256 balanceUnderlying = investedUnderlyingBalance();
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
        withdrawMixTokens(calcLPAmount(toWithdraw));

        uint256 balance = IERC20(underlying).balanceOf(address(this));
        IERC20(underlying).safeTransfer(vault, balance);
    }

    /// @notice Controller | Vault role - withdraw should always return to Vault
    function withdrawAll() external override {
        if (harvestOnWithdraw && liquidationAllowed) {
                claimAndLiquidateCrv();
            }
        
        uint256 gaugeBalance = ICurveFi_Gauge(gauge).balanceOf(address(this));
        withdrawMixTokens(gaugeBalance);

        uint256 balance = IERC20(underlying).balanceOf(address(this));
        IERC20(underlying).safeTransfer(vault, balance);
    }

    function emergencyExit() external onlyGovernance {
        claimAndLiquidateCrv();

        uint256 gaugeBalance = ICurveFi_Gauge(gauge).balanceOf(address(this));
        withdrawMixTokens(gaugeBalance);

        uint256 looseBalance = IERC20(underlying).balanceOf(address(this));
        IERC20(underlying).safeTransfer(IVault(vault).governance(), looseBalance);
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

    /**
     * Uses the Curve protocol to convert the wbtc asset into to mixed renwbtc token.
     */
    function mixFromWBTC() internal {
        uint256 underlyingBalance = IERC20(underlying).balanceOf(address(this));
        if (underlyingBalance > 0) {
            // Buy second asset so that we can add liquidity
            int128 i = int128(tokenIndex);
            int128 j = tokenIndex == TokenIndex.REN_BTC ? 1 : 0;

            uint256 underlyingToExchange = underlyingBalance.div(2);
            IERC20(underlying).safeApprove(curve, 0);
            IERC20(underlying).safeApprove(curve, underlyingToExchange);
            
            ICurveFiWbtc(curve).exchange(i, j, underlyingToExchange, 0);
            // Now we have both renBTC and wBTC
            uint256 secondAssetBalance = IERC20(secondAsset).balanceOf(address(this)); 
            underlyingBalance = IERC20(underlying).balanceOf(address(this));

            IERC20(underlying).safeApprove(curve, 0);
            IERC20(underlying).safeApprove(curve, underlyingBalance);
            IERC20(secondAsset).safeApprove(curve, 0);
            IERC20(secondAsset).safeApprove(curve, secondAssetBalance);
            // we can accept 0 as minimum because this is called only by a trusted role
            uint256 minimum = 0;
                  
            uint256[2] memory coinAmounts = wrapCoinAmount(underlyingBalance, secondAssetBalance);
            ICurveFiWbtc(curve).add_liquidity(coinAmounts, minimum);
        }
        // now we have the mixed token
    }

    /**
     * Invests all wbtc-pool LP-tokens into our underlying vault.
     */
    function investMixedCoin() internal {
        address mixedToken = ICurveFi_Gauge(gauge).lp_token();
        // then deposit into the underlying vault
        uint256 mixedBalance = IERC20(mixedToken).balanceOf(address(this));
        if (mixedBalance > 0) {
            IERC20(mixedToken).safeApprove(gauge, 0);
            IERC20(mixedToken).safeApprove(gauge, mixedBalance);
            ICurveFi_Gauge(gauge).deposit(mixedBalance);
        }
    }

    /**
     * Withdraws an wbtc asset from the strategy to the vault in the specified amount by asking
     * by removing imbalanced liquidity from the Curve protocol. The rest is deposited back to the
     * Curve protocol pool. If the amount requested cannot be obtained, the method will get as much
     * as we have.
     */
    function withdrawMixTokens(uint256 lpAmount) internal {
        address mixedToken = ICurveFi_Gauge(gauge).lp_token();
        // withdraw from gauge
        ICurveFi_Gauge(gauge).withdraw(lpAmount);

        // we can withdraw underlying
        uint256 actualShares = IERC20(mixedToken).balanceOf(address(this));
        ICurveFiWbtc(curve).remove_liquidity_one_coin(actualShares, int128(tokenIndex), 0);
    }

    /**
     * Returns the wbtc invested balance. The is the wbtc amount in this stragey, plus the gauge
     * amount of the mixed token converted back to wbtc.
     */
    function investedUnderlyingBalance() internal view returns (uint256) {
        address mixedToken = ICurveFi_Gauge(gauge).lp_token();
        uint256 gaugeBalance = ICurveFi_Gauge(gauge).balanceOf(address(this));
        gaugeBalance = gaugeBalance.add(IERC20(mixedToken).balanceOf(address(this)));
        
        int128 tokenIdx = int128(tokenIndex);
        if(gaugeBalance > 0 ) {
            return ICurveFiWbtc(curve).calc_withdraw_one_coin(gaugeBalance, tokenIdx);
        }
        return 0;
    }

    /**
     * Wraps the coin amount in the array for interacting with the Curve protocol
     */
    function wrapCoinAmount(uint256 underlyingAmount, uint256 secondAssetAmount)
     internal view returns (uint256[2] memory) {
        uint256[2] memory amounts = [uint256(0), uint256(0)];
        amounts[uint256(tokenIndex)] = underlyingAmount;

        amounts[tokenIndex == TokenIndex.REN_BTC ? 1 : 0] = secondAssetAmount;

        return amounts;
    }

    /**
    * Claims the CRV crop, converts it to DAI on Uniswap, and then uses DAI to mint yCRV using the
    * Curve protocol.
    */
    function claimAndLiquidateCrv() public {
        ICurveFi_Minter(mintr).mint(gauge);
        // claiming rewards and sending them to the master strategy

        uint256 crvBalance = IERC20(crv).balanceOf(address(this));

        if (crvBalance > sellFloor) {
            uint256 wbtcBalanceBefore = IERC20(underlying).balanceOf(address(this));
            IERC20(crv).safeApprove(uniswapRouter, 0);
            IERC20(crv).safeApprove(uniswapRouter, crvBalance);
            // we can accept 1 as the minimum because this will be called only by a trusted worker
            IUniswapV2Router02(uniswapRouter).swapExactTokensForTokens(
              crvBalance, 1, uniswap_CRV2WBTC, address(this), block.timestamp + 10
            );
            // now we have BTC
            // pay fee before making LP-token
            _profitSharing(IERC20(underlying).balanceOf(address(this)) - wbtcBalanceBefore);
        }
    }

    function calcLPAmount(uint256 amountUnderlying) internal view returns(uint256) {
        uint256[2] memory coinAmounts = wrapCoinAmount(amountUnderlying, 0);
        return ICurveFiWbtc(curve).calc_token_amount(coinAmounts, false);
    }


    function convert(address) external override returns (uint256) {
        return 0;
    }

    function skim() external override {
        revert("Can't skim");
    }
}
