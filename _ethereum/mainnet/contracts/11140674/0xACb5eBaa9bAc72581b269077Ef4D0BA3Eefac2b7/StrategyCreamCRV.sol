// SPDX-License-Identifier: GPL-3.0
pragma solidity 0.6.12;
pragma experimental ABIEncoderV2;

import "./BaseStrategy.sol";
import "./IERC20.sol";
import "./SafeMath.sol";
import "./Address.sol";
import "./SafeERC20.sol";

import "./Controller.sol";
import "./cToken.sol";
import "./Uni.sol";

import "./IController.sol";

interface Uniswap {
    function getAmountsOut(uint256 amountIn, address[] memory path) external view returns (uint256[] memory amounts);
}

interface UniswapPair {
    function token0() external view returns (address);

    function token1() external view returns (address);

    function getReserves()
        external
        view
        returns (
            uint112 reserve0,
            uint112 reserve1,
            uint32 blockTimestampLast
        );
}

/*
 * Strategy For CRV using Cream Finance
 */

contract StrategyCreamCRV is BaseStrategy {
    using SafeERC20 for IERC20;
    using Address for address;
    using SafeMath for uint256;

    // want is CRV
    address public constant CRV = address(0xD533a949740bb3306d119CC777fa900bA034cd52);

    Creamtroller public constant creamtroller = Creamtroller(0x3d5BC3c8d13dcB8bF317092d84783c2697AE9258);

    address public constant crCRV = address(0xc7Fd8Dcee4697ceef5a2fd4608a7BD6A94C77480);
    address public constant cream = address(0x2ba592F78dB6436527729929AAf6c908497cB200);

    address public constant uni = address(0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D);
    address public constant weth = address(0xC02aaA39b223FE8D0A0e5C4F27eAD9083C756Cc2); // used for cream <> weth <> crv route

    uint256 public gasFactor = 10;

    constructor(address _vault) public BaseStrategy(_vault) {
        //only accept CRV vault
        require(vault.token() == CRV, "!NOT_CRV");
    }

    // ******** OVERRIDE METHODS FROM BASE CONTRACT ********************

    /*
     * Provide an accurate expected value for the return this strategy
     * would provide to the Vault if `report()` was called right now
     */
    function expectedReturn() public override view returns (uint256) {
        //expected return = expected total assets (Total supplied CREAM + some want) - core postion (totalDebt)
        StrategyParams memory params = vault.strategies(address(this));

        return estimatedTotalAssets() - params.totalDebt;
    }

    function name() external override pure returns (string memory) {
        return "StrategyCreamCRV";
    }

    /*
     * Perform any adjustments to the core position(s) of this strategy given
     * what change the Vault made in the "investable capital" available to the
     * strategy. Note that all "free capital" in the strategy after the report
     * was made is available for reinvestment. Also note that this number could
     * be 0, and you should handle that scenario accordingly.
     */

    function adjustPosition() internal override {
        // NOTE: deposit any outstanding want token into CREAM
        uint256 _want = IERC20(want).balanceOf(address(this));
        if (_want > 0) {
            IERC20(want).safeApprove(crCRV, 0);
            IERC20(want).safeApprove(crCRV, _want);
            cToken(crCRV).mint(_want);
        }
    }

    /*
     * Provide a signal to the keeper that `harvest()` should be called. The keeper will provide
     * the estimated gas cost that they would pay to call `harvest()`, and this function should
     * use that estimate to make a determination if calling it is "worth it" for the keeper.
     * This is not the only consideration into issuing this trigger, for example if the position
     * would be negatively affected if `harvest()` is not called shortly, then this can return `true`
     * even if the keeper might be "at a loss" (keepers are always reimbursed by yEarn)
     *
     * NOTE: this call and `tendTrigger` should never return `true` at the same time.
     */
    function harvestTrigger(uint256 gasCost) public override view returns (bool) {
        // NOTE: if the vault has creditAvailable we can pull funds in harvest
        uint256 _credit = vault.creditAvailable();
        if (_credit > 0) {
            uint256 _creditAvailable = quote(address(want), weth, _credit);
            // ethvalue of credit available is  greater than gas Cost * gas factor
            if (_creditAvailable > gasCost.mul(gasFactor)) {
                return true;
            }
        }
        uint256 _debtOutstanding = vault.debtOutstanding();
        if (_debtOutstanding > 0) {
            return true;
        }

        return false;
    }

    /*
     * Provide an accurate estimate for the total amount of assets (principle + return)
     * that this strategy is currently managing, denominated in terms of `want` tokens.
     * This total should be "realizable" e.g. the total value that could *actually* be
     * obtained from this strategy if it were to divest it's entire position based on
     * current on-chain conditions.
     *
     * NOTE: care must be taken in using this function, since it relies on external
     *       systems, which could be manipulated by the attacker to give an inflated
     *       (or reduced) value produced by this function, based on current on-chain
     *       conditions (e.g. this function is possible to influence through flashloan
     *       attacks, oracle manipulations, or other DeFi attack mechanisms).
     *
     * NOTE: It is up to governance to use this function in order to correctly order
     *       this strategy relative to its peers in order to minimize losses for the
     *       Vault based on sudden withdrawals. This value should be higher than the
     *       total debt of the strategy and higher than it's expected value to be "safe".
     */
    function estimatedTotalAssets() public override view returns (uint256) {
        return IERC20(want).balanceOf(address(this)).add(_balanceCInToken());
    }

    /*
     * Make as much capital as possible "free" for the Vault to take. Some slippage
     * is allowed, since when this method is called the strategist is no longer receiving
     * their performance fee. The goal is for the strategy to divest as quickly as possible
     * while not suffering exorbitant losses. This function is used during emergency exit
     * instead of `prepareReturn()`
     */
    function exitPosition() internal override {
        _withdrawAll();
    }

    /*
     * Perform any strategy unwinding or other calls necessary to capture
     * the "free return" this strategy has generated since the last time it's
     * core position(s) were adusted. Examples include unwrapping extra rewards.
     * This call is only used during "normal operation" of a Strategy, and should
     * be optimized to minimize losses as much as possible. It is okay to report
     * "no returns", however this will affect the credit limit extended to the
     * strategy and reduce it's overall position if lower than expected returns
     * are sustained for long periods of time.
     */
    function prepareReturn() internal override {
        // Note: in case of CREAM liquidity mining
        Creamtroller(creamtroller).claimComp(address(this));
        // NOTE: in case of CREAM liquidity mining
        uint256 _cream = IERC20(cream).balanceOf(address(this));
        if (_cream > 0) {
            IERC20(cream).safeApprove(uni, 0);
            IERC20(cream).safeApprove(uni, _cream);

            address[] memory path = new address[](3);
            path[0] = cream;
            path[1] = weth;
            // NOTE: need to cast it since BaseStrategy wraps IERC20 interface
            path[2] = address(want);

            Uni(uni).swapExactTokensForTokens(_cream, uint256(0), path, address(this), now.add(1800));
        }

        uint256 _expectedReturnFromCream = expectedReturn();
        if (_expectedReturnFromCream > 0) {
            // realize profits from cream
            liquidatePosition(_expectedReturnFromCream);
        }
    }

    /*
     * Provide a signal to the keeper that `tend()` should be called. The keeper will provide
     * the estimated gas cost that they would pay to call `tend()`, and this function should
     * use that estimate to make a determination if calling it is "worth it" for the keeper.
     * This is not the only consideration into issuing this trigger, for example if the position
     * would be negatively affected if `tend()` is not called shortly, then this can return `true`
     * even if the keeper might be "at a loss" (keepers are always reimbursed by yEarn)
     *
     * NOTE: this call and `harvestTrigger` should never return `true` at the same time.
     * NOTE: if `tend()` is never intended to be called, it should always return `false`
     */
    function tendTrigger(uint256 gasCost) public override view returns (bool) {
        // NOTE: this strategy does not need tending

        gasCost; // Shh

        return false;
    }

    /*
     * Liquidate as many assets as possible to `want`, irregardless of slippage,
     * up to `_amount`. Any excess should be re-invested here as well.
     */
    function liquidatePosition(uint256 _amount) internal override {
        _withdrawSome(_amount);
    }

    /*
     * Do anything necesseary to prepare this strategy for migration, such
     * as transfering any reserve or LP tokens, CDPs, or other tokens or stores of value.
     */
    function prepareMigration(address _newStrategy) internal override {
        exitPosition();
        want.transfer(_newStrategy, want.balanceOf(address(this)));
    }

    // Overriden method
    // NOTE: Must inclide `want` token
    function protectedTokens() internal override view returns (address[] memory) {
        address[] memory protected = new address[](2);
        protected[0] = address(want);
        protected[1] = address(crCRV);
        return protected;
    }

    // ******* HELPER METHODS *********

    function quote(
        address token_in,
        address token_out,
        uint256 amount_in
    ) public view returns (uint256) {
        bool is_weth = token_in == weth || token_out == weth;
        address[] memory path = new address[](is_weth ? 2 : 3);
        path[0] = token_in;
        if (is_weth) {
            path[1] = token_out;
        } else {
            path[1] = weth;
            path[2] = token_out;
        }
        uint256[] memory amounts = Uniswap(uni).getAmountsOut(amount_in, path);
        return amounts[amounts.length - 1];
    }

    function setGasFactor(uint256 _gasFactor) external {
        require(msg.sender == strategist || msg.sender == governance(), "!governance");
        gasFactor = _gasFactor;
    }

    function _withdrawAll() internal {
        uint256 amount = _balanceC();
        if (amount > 0) {
            _withdrawSome(_balanceCInToken().sub(1));
        }
    }

    function _withdrawSome(uint256 _amount) internal returns (uint256) {
        uint256 b = _balanceC();
        uint256 bT = _balanceCInToken();
        // can have unintentional rounding errors
        uint256 amount = (b.mul(_amount)).div(bT).add(1);
        uint256 _before = IERC20(want).balanceOf(address(this));
        // 0=success else fails with error code
        require(cToken(crCRV).redeem(amount) == 0, "cToken redeem failed!");
        uint256 _after = IERC20(want).balanceOf(address(this));
        uint256 _withdrew = _after.sub(_before);
        return _withdrew;
    }

    // ******** BALANCE METHODS ********************
    function _balanceCInToken() internal view returns (uint256) {
        // Mantisa 1e18 to decimals
        uint256 b = _balanceC();
        if (b > 0) {
            b = b.mul(cToken(crCRV).exchangeRateStored()).div(1e18);
        }
        return b;
    }

    function _balanceC() internal view returns (uint256) {
        return IERC20(crCRV).balanceOf(address(this));
    }
}
