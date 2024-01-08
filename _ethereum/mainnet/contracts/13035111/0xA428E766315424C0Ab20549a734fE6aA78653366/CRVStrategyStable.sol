// SPDX-License-Identifier: None
pragma solidity 0.6.12;

import "./BoilerplateStrategy.sol";

import "./IYERC20.sol";
import "./ICurveFi_DepositY.sol";
import "./ICurveFi_SwapY.sol";
import "./IUniswapV2Router02.sol";

/**
 * The goal of this strategy is to take a stable asset (DAI, USDC, USDT), turn it into ycrv using
 * the curve mechanisms, and supply ycrv into the ycrv vault. The ycrv vault will likely not have
 * a reward token distribution pool to avoid double dipping. All the calls to functions from this
 * strategy will be routed to the controller which should then call the respective methods on the
 * ycrv vault. This strategy will not be liquidating any yield crops (CRV), because the strategy
 * of the ycrv vault will do that for us.
 */

contract CRVStrategyStable is IStrategy, BoilerplateStrategy {
    enum TokenIndex {DAI, USDC, USDT, TUSD}

    using SafeERC20 for IERC20;
    using SafeMath for uint256;

    // the matching enum record used to determine the index
    TokenIndex tokenIndex;

    // the y-asset corresponding to our asset
    address public yToken;

    // the address of yCRV token
    address public ycrv;

    address public yycrv;

    // the address of the Curve protocol(DepositY, SwapY)
    address public curve;
    
    address public swap;

    constructor(
        address _vault,
        address _underlying,
        address _strategist,
        address _curve,
        address _swap,
        address _ycrv,
        address _yycrv,
        address _yToken,
        uint256 _tokenIndex
    ) public BoilerplateStrategy(_vault, _underlying, _strategist) {
        require(IVault(_vault).token() == _underlying, "vault does not support underlying");

        tokenIndex = TokenIndex(_tokenIndex);
        yycrv = _yycrv;
        ycrv = _ycrv;
        curve = _curve;
        swap = _swap;
        yToken = _yToken;

        // set these tokens to be not salvageable
        unsalvageableTokens[underlying] = true;
        unsalvageableTokens[yycrv] = true;
        unsalvageableTokens[ycrv] = true;
        unsalvageableTokens[yToken] = true;
    }

    /*****
     * VIEW INTERFACE
     *****/

    function getNameStrategy() external view override returns (string memory) {
        return "CRVStrategyStable";
    }

    function want() external view override returns (address) {
        return underlying;
    }

    /**
     * Returns the underlying invested balance. This is the amount of yCRV that we are entitled to
     * from the yCRV vault (based on the number of shares we currently have), converted to the
     * underlying assets by the Curve protocol, plus the current balance of the underlying assets.
     */
    function balanceOf() public view override returns (uint256) {
        uint256 stableBal = balanceOfUnderlying();
        return stableBal.add(IERC20(underlying).balanceOf(address(this)));
    }

    function balanceOfUnderlying() public view returns(uint256) {
        uint256 yycrvShares = IERC20(yycrv).balanceOf(address(this));
        uint256 ycrvBal = yycrvShares.mul(IYERC20(yycrv).getPricePerFullShare()).div(1e18);

        int128 tokenIdx = int128(tokenIndex);
        if(ycrvBal > 0) {
            return ICurveFi_DepositY(curve).calc_withdraw_one_coin(ycrvBal, tokenIdx);
        }
        return 0;
    }

    /*****
    * DEPOSIT/WITHDRAW/HARVEST EXTERNAL
    *****/

    /**
     * Invests all underlying assets into our yCRV vault.
     */
    function deposit() public override {
        // convert the entire balance not yet invested into yCRV first
        yCurveFromUnderlying();
        
        // then deposit into the yCRV vault
        uint256 ycrvBalance = IERC20(ycrv).balanceOf(address(this));
        if (ycrvBalance > 0) {
            IERC20(ycrv).safeApprove(yycrv, 0);
            IERC20(ycrv).safeApprove(yycrv, ycrvBalance);
            // deposits the entire balance and also asks the vault to invest it (public function)
            IYERC20(yycrv).deposit(ycrvBalance);
        }
    }

    /**
     * Withdraws an underlying asset from the strategy to the vault in the specified amount by asking
     * the yCRV vault for yCRV (currently all of it), and then removing imbalanced liquidity from
     * the Curve protocol. The rest is deposited back to the yCRV vault. If the amount requested cannot
     * be obtained, the method will get as much as we have.
     */
    function withdraw(uint256 amountUnderlying) public override restricted {
        require(amountUnderlying > 0, "Incorrect amount");

        uint256 balanceUnderlying = balanceOfUnderlying();
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
        _withdrawSome(toWithdraw);
        looseBalance = IERC20(underlying).balanceOf(address(this));
        IERC20(underlying).safeTransfer(vault, looseBalance);
    }

    /**
    * Withdraws all the yCRV tokens to the pool.
    */
    function withdrawAll() external override restricted {
        _withdrawAll();
        uint256 looseBalance = IERC20(underlying).balanceOf(address(this));
        IERC20(underlying).safeTransfer(vault, looseBalance);
    }

    function emergencyExit() external onlyGovernance {
        _withdrawAll();

        uint256 looseBalance = IERC20(underlying).balanceOf(address(this));
        IERC20(underlying).safeTransfer(IVault(vault).governance(), looseBalance);
    }

    /**
    * Claims and liquidates CRV into yCRV, and then invests all underlying.
    */
    function earn() public restricted {
        deposit();
    }

    /**
     * Uses the Curve protocol to convert the underlying asset into yAsset and then to yCRV.
     */
    function yCurveFromUnderlying() internal {
        // convert underlying asset to yAsset
        uint256 underlyingBalance = IERC20(underlying).balanceOf(address(this));
        IERC20(underlying).safeApprove(curve, 0);
        IERC20(underlying).safeApprove(curve, underlyingBalance);
        uint256 minimum = 0;
        uint256[4] memory amounts = wrapCoinAmount(underlyingBalance);
        ICurveFi_DepositY(curve).add_liquidity(amounts, minimum);
        // now we have yCRV
    }

    function _withdrawSome(uint256 _amount) internal returns (uint256) {
        // calculate amount of ycrv to withdraw for amount of _want_
        uint256 _ycrv = _amount.mul(1e18).div(ICurveFi_SwapY(swap).get_virtual_price());
        // calculate amount of yycrv to withdraw for amount of _ycrv_
        uint256 _yycrv = _ycrv.mul(1e18).div(IYERC20(yycrv).getPricePerFullShare());

        uint256 _before = IERC20(ycrv).balanceOf(address(this));
        IYERC20(yycrv).withdraw(_yycrv);
        uint256 _after = IERC20(ycrv).balanceOf(address(this));

        return withdrawUnderlying(_after.sub(_before));
    }

    function _withdrawAll() internal returns(uint256) {
        uint256 _yycrv = IERC20(yycrv).balanceOf(address(this));
        IYERC20(yycrv).withdraw(_yycrv);

        return withdrawUnderlying(_yycrv);
    }

    function withdrawUnderlying(uint256 _amount) internal returns (uint256) {
        IERC20(ycrv).safeApprove(curve, 0);
        IERC20(ycrv).safeApprove(curve, _amount);

        uint256 _before = IERC20(underlying).balanceOf(address(this));
        ICurveFi_DepositY(curve).remove_liquidity_one_coin(_amount, int128(tokenIndex), 0);
        uint256 _after = IERC20(underlying).balanceOf(address(this));
        
        return _after.sub(_before);
    }

    /**
     * Wraps the coin amount in the array for interacting with the Curve protocol
     */
    function wrapCoinAmount(uint256 amount) internal view returns (uint256[4] memory) {
        uint256[4] memory amounts = [uint256(0), uint256(0), uint256(0), uint256(0)];
        amounts[uint56(tokenIndex)] = amount;
        return amounts;
    }

    function convert(address) external override returns (uint256) {
        revert("Can't convert");
        return 0;
    }

    function skim() external override {
        revert("Can't skim");
    }

}
