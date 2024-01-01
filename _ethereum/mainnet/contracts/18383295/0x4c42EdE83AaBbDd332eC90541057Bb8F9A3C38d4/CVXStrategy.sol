// SPDX-License-Identifier: AGPL-3.0

pragma solidity ^0.8.18;

import "./BaseStrategy.sol";
import "./ERC20.sol";
import "./Math.sol";
import "./SafeERC20.sol";
import "./OracleLibrary.sol";

import "./IBalancerPriceOracle.sol";
import "./ICurve.sol";
import "./IConvexRewards.sol";
import "./IConvexDeposit.sol";

import "./Utils.sol";
import "./CVXRewards.sol";

contract CVXStrategy is BaseStrategy {
    using SafeERC20 for IERC20;

    address internal constant USDC_ETH_UNI_V3_POOL =
        0x88e6A0c2dDD26FEEb64F039a2c41296FcB3f5640;
    address internal constant CRV_USDC_UNI_V3_POOL =
        0x9445bd19767F73DCaE6f2De90e6cd31192F62589;
    address internal constant CVX_USDC_UNI_V3_POOL =
        0x575e96f61656b275CA1e0a67d9B68387ABC1d09C;
    address internal constant WETH = 0xC02aaA39b223FE8D0A0e5C4F27eAD9083C756Cc2;
    address internal constant CRV = 0xD533a949740bb3306d119CC777fa900bA034cd52;
    address internal constant CVX = 0x4e3FBD56CD56c3e72c1403e103b45Db9da5B9D2B;

    address internal constant CURVE_SWAP_ROUTER =
        0x99a58482BD75cbab83b27EC03CA68fF489b5788f;
    address internal constant CURVE_CVX_ETH_POOL =
        0xB576491F1E6e5E62f1d8F26062Ee822B40B0E0d4;
    address internal constant CURVE_CVX_ETH_LP =
        0x3A283D9c08E8b55966afb64C515f5143cf907611;
    address internal constant ETH_CVX_CONVEX_DEPOSIT =
        0xF403C135812408BFbE8713b5A23a04b3D48AAE31;
    address internal constant ETH_CVX_CONVEX_CRV_REWARDS =
        0xb1Fb0BA0676A1fFA83882c7F4805408bA232C1fA;
    address internal constant CONVEX_CVX_REWARD_POOL =
        0x834B9147Fd23bF131644aBC6e557Daf99C5cDa15;

    uint32 internal constant TWAP_RANGE_SECS = 1800;
    uint256 public slippage;

    uint256 private WANT_DECIMALS;

    constructor(address _vault) BaseStrategy(_vault) {}

    function initialize(address _vault, address _strategist) external {
        _initialize(_vault, _strategist, _strategist, _strategist);

        want.safeApprove(CURVE_SWAP_ROUTER, type(uint256).max);
        IERC20(CRV).safeApprove(CURVE_SWAP_ROUTER, type(uint256).max);
        IERC20(CVX).safeApprove(CURVE_SWAP_ROUTER, type(uint256).max);
        IERC20(CURVE_CVX_ETH_LP).safeApprove(
            ETH_CVX_CONVEX_DEPOSIT,
            type(uint256).max
        );
        IERC20(CURVE_CVX_ETH_LP).safeApprove(
            CURVE_CVX_ETH_POOL,
            type(uint256).max
        );
        WANT_DECIMALS = ERC20(address(want)).decimals();
        slippage = 9800; // 2%
    }

    function setSlippage(uint256 _slippage) external onlyStrategist {
        require(_slippage < 10_000, "!_slippage");
        slippage = _slippage;
    }

    function name() external pure override returns (string memory) {
        return "StrategyCVX";
    }

    function balanceOfWant() public view returns (uint256) {
        return want.balanceOf(address(this));
    }

    function balanceOfCurveLPUnstaked() public view returns (uint256) {
        return ERC20(CURVE_CVX_ETH_LP).balanceOf(address(this));
    }

    function balanceOfCurveLPStaked() public view returns (uint256) {
        return
            IConvexRewards(ETH_CVX_CONVEX_CRV_REWARDS).balanceOf(address(this));
    }

    function balanceOfCrvRewards() public view virtual returns (uint256) {
        return IConvexRewards(ETH_CVX_CONVEX_CRV_REWARDS).earned(address(this));
    }

    function balanceOfCvxRewards(
        uint256 crvRewards
    ) public view virtual returns (uint256) {
        return
            IConvexRewards(CONVEX_CVX_REWARD_POOL).earned(address(this)) +
            CVXRewardsMath.convertCrvToCvx(crvRewards);
    }

    function curveLPToWant(uint256 _lpTokens) public view returns (uint256) {
        uint256 ethAmount = (
            _lpTokens > 0
                ? (ICurve(CURVE_CVX_ETH_POOL).lp_price() * _lpTokens) / 1e18
                : 0
        );
        return ethToWant(ethAmount);
    }

    function wantToCurveLP(
        uint256 _want
    ) public view virtual returns (uint256) {
        uint256 oneCurveLPPrice = curveLPToWant(1e18);
        return (_want * 1e18) / oneCurveLPPrice;
    }

    function _withdrawSome(uint256 _amountNeeded) internal {
        if (_amountNeeded == 0) {
            return;
        }
        uint256 earnedCrv = balanceOfCrvRewards();
        uint256 earnedCvx = balanceOfCvxRewards(earnedCrv);
        uint256 totalCrv = earnedCrv + ERC20(CRV).balanceOf(address(this));
        uint256 totalCvx = earnedCvx + ERC20(CVX).balanceOf(address(this));
        uint256 rewardsTotal = crvToWant(totalCrv) + cvxToWant(totalCvx);

        if (rewardsTotal >= _amountNeeded) {
            IConvexRewards(ETH_CVX_CONVEX_CRV_REWARDS).getReward(
                address(this),
                true
            );
            _sellCrvAndCvx(
                ERC20(CRV).balanceOf(address(this)),
                ERC20(CVX).balanceOf(address(this))
            );
        } else {
            uint256 lpTokensToWithdraw = Math.min(
                wantToCurveLP(_amountNeeded - rewardsTotal),
                balanceOfCurveLPStaked()
            );
            _exitPosition(lpTokensToWithdraw);
        }
    }

    function ethToWant(
        uint256 _amtInWei
    ) public view override returns (uint256) {
        uint256 scaledPrice = (ICurve(
            0x7F86Bf177Dd4F3494b841a37e810A34dD56c829B
        ).price_oracle(1) * _amtInWei) / 1e18;
        return
            Utils.scaleDecimals(scaledPrice, ERC20(WETH), ERC20(address(want)));
    }

    function crvToWant(uint256 crvTokens) public view returns (uint256) {
        uint256 scaledPrice = (ICurve(
            0x4eBdF703948ddCEA3B11f675B4D1Fba9d2414A14
        ).price_oracle(1) * crvTokens) / 1e18;
        return
            Utils.scaleDecimals(scaledPrice, ERC20(CRV), ERC20(address(want)));
    }

    function cvxToWant(uint256 cvxTokens) public view returns (uint256) {
        uint256 scaledPrice = (ICurve(
            0xB576491F1E6e5E62f1d8F26062Ee822B40B0E0d4
        ).price_oracle() * cvxTokens) / 1e18;
        return ethToWant(scaledPrice);
    }

    function estimatedTotalAssets()
        public
        view
        virtual
        override
        returns (uint256 _wants)
    {
        _wants = balanceOfWant();
        _wants += curveLPToWant(
            balanceOfCurveLPStaked() + balanceOfCurveLPUnstaked()
        );

        uint256 earnedCrv = balanceOfCrvRewards();
        uint256 earnedCvx = balanceOfCvxRewards(earnedCrv);
        uint256 totalCrv = earnedCrv + ERC20(CRV).balanceOf(address(this));
        uint256 totalCvx = earnedCvx + ERC20(CVX).balanceOf(address(this));

        _wants += crvToWant(totalCrv);
        _wants += cvxToWant(totalCvx);
    }

    function prepareReturn(
        uint256 _debtOutstanding
    )
        internal
        override
        returns (uint256 _profit, uint256 _loss, uint256 _debtPayment)
    {
        uint256 _totalAssets = estimatedTotalAssets();
        uint256 _totalDebt = vault.strategies(address(this)).totalDebt;

        if (_totalAssets >= _totalDebt) {
            _profit = _totalAssets - _totalDebt;
            _loss = 0;
        } else {
            _profit = 0;
            _loss = _totalDebt - _totalAssets;
        }
        uint256 _liquidWant = balanceOfWant();
        uint256 _amountNeeded = _debtOutstanding + _profit;
        if (_liquidWant <= _amountNeeded) {
            _withdrawSome(_amountNeeded - _liquidWant);
            _liquidWant = balanceOfWant();
        }
        // enough to pay profit (partial or full) only
        if (_liquidWant <= _profit) {
            _profit = _liquidWant;
            _debtPayment = 0;
            // enough to pay for all profit and _debtOutstanding (partial or full)
        } else {
            _debtPayment = Math.min(_liquidWant - _profit, _debtOutstanding);
        }
    }

    function adjustPosition(uint256 _debtOutstanding) internal override {
        if (emergencyExit) {
            return;
        }
        IConvexRewards(ETH_CVX_CONVEX_CRV_REWARDS).getReward(
            address(this),
            true
        );
        _sellCrvAndCvx(
            ERC20(CRV).balanceOf(address(this)),
            ERC20(CVX).balanceOf(address(this))
        );

        uint256 _wantBal = balanceOfWant();
        if (_wantBal > _debtOutstanding) {
            uint256 _excessWant = _wantBal - _debtOutstanding;
            uint256 _ethExpected = (_excessWant * (10 ** WANT_DECIMALS)) /
                ethToWant(1 ether);
            uint256 _ethExpectedScaled = Utils.scaleDecimals(
                _ethExpected,
                ERC20(address(want)),
                ERC20(WETH)
            );

            address[9] memory _route = [
                address(want),
                0xbEbc44782C7dB0a1A60Cb6fe97d0b483032FF1C7, // 3pool
                0xdAC17F958D2ee523a2206206994597C13D831ec7, // USDT
                0xD51a44d3FaE010294C616388b506AcdA1bfAAE46, // tricrypto2 pool
                0xEeeeeEeeeEeEeeEeEeEeeEEEeeeeEeeeeeeeEEeE, // ETH
                address(0),
                address(0),
                address(0),
                address(0)
            ];
            uint256[3][4] memory _swap_params = [
                [uint256(1), uint256(2), uint256(1)], // USDC -> USDT, stable swap exchange
                [uint256(0), uint256(2), uint256(3)], // USDT -> ETH, cryptoswap exchange
                [uint256(0), uint256(0), uint256(0)],
                [uint256(0), uint256(0), uint256(0)]
            ];
            ICurveSwapRouter(CURVE_SWAP_ROUTER).exchange_multiple(
                _route,
                _swap_params,
                _excessWant,
                (_ethExpectedScaled * slippage) / 10000
            );
        }

        if (address(this).balance > 0) {
            uint256 ethPrice = ethToWant(address(this).balance);
            uint256 lpPrice = curveLPToWant(1e18);
            uint256 lpTokensExpectedUnscaled = (ethPrice *
                (10 ** WANT_DECIMALS)) / lpPrice;
            uint256 lpTokensExpectedScaled = Utils.scaleDecimals(
                lpTokensExpectedUnscaled,
                ERC20(address(want)),
                ERC20(CURVE_CVX_ETH_LP)
            );

            uint256[2] memory amounts = [address(this).balance, uint256(0)];
            ICurve(CURVE_CVX_ETH_POOL).add_liquidity{
                value: address(this).balance
            }(amounts, (lpTokensExpectedScaled * slippage) / 10000, true);
        }
        if (balanceOfCurveLPUnstaked() > 0) {
            require(
                IConvexDeposit(ETH_CVX_CONVEX_DEPOSIT).depositAll(
                    uint256(64),
                    true
                ),
                "Convex staking failed"
            );
        }
    }

    function _cvxToCrv(uint256 cvxTokens) internal view returns (uint256) {
        uint256 wantAmount = cvxToWant(cvxTokens);
        uint256 oneCrv = crvToWant(1 ether);
        return (wantAmount * (10 ** WANT_DECIMALS)) / oneCrv;
    }

    function _sellCrvAndCvx(uint256 _crvAmount, uint256 _cvxAmount) internal {
        if (_cvxAmount > 0) {
            address[9] memory _route = [
                CVX, // CVX
                0xB576491F1E6e5E62f1d8F26062Ee822B40B0E0d4, // cvxeth pool
                0xEeeeeEeeeEeEeeEeEeEeeEEEeeeeEeeeeeeeEEeE, // ETH
                0x4eBdF703948ddCEA3B11f675B4D1Fba9d2414A14, // TriCRV pool
                CRV, // CRV
                address(0),
                address(0),
                address(0),
                address(0)
            ];
            uint256[3][4] memory _swap_params = [
                [uint256(1), uint256(0), uint256(3)], // CVX -> WETH, cryptoswap exchange
                [uint256(1), uint256(2), uint256(3)], // WETH -> CRV, cryptoswap exchange
                [uint256(0), uint256(0), uint256(0)],
                [uint256(0), uint256(0), uint256(0)]
            ];
            uint256 _expected = (_cvxToCrv(_cvxAmount) * slippage) / 10000;

            _crvAmount += ICurveSwapRouter(CURVE_SWAP_ROUTER).exchange_multiple(
                _route,
                _swap_params,
                _cvxAmount,
                _expected
            );
        }

        if (_crvAmount > 0) {
            address[9] memory _route = [
                0xD533a949740bb3306d119CC777fa900bA034cd52, // CRV
                0x4eBdF703948ddCEA3B11f675B4D1Fba9d2414A14, // TriCRV pool
                0xf939E0A03FB07F59A73314E73794Be0E57ac1b4E, // crvUSD
                0x4DEcE678ceceb27446b35C672dC7d61F30bAD69E, // crvUSD/USDC pool
                address(want),
                address(0),
                address(0),
                address(0),
                address(0)
            ];
            uint256[3][4] memory _swap_params = [
                [uint256(2), uint256(0), uint256(3)], // CRV -> crvUSD, cryptoswap exchange
                [uint256(1), uint256(0), uint256(1)], // crvUSD -> USDC, stable swap exchange
                [uint256(0), uint256(0), uint256(0)],
                [uint256(0), uint256(0), uint256(0)]
            ];
            uint256 _expected = (crvToWant(_crvAmount) * slippage) / 10000;

            ICurveSwapRouter(CURVE_SWAP_ROUTER).exchange_multiple(
                _route,
                _swap_params,
                _crvAmount,
                _expected
            );
        }
    }

    function _exitPosition(uint256 _stakedLpTokens) internal {
        IConvexRewards(ETH_CVX_CONVEX_CRV_REWARDS).withdrawAndUnwrap(
            _stakedLpTokens,
            true
        );

        _sellCrvAndCvx(
            ERC20(CRV).balanceOf(address(this)),
            ERC20(CVX).balanceOf(address(this))
        );

        uint256 lpTokens = ERC20(CURVE_CVX_ETH_LP).balanceOf(address(this));
        uint256 withdrawAmount = ICurve(CURVE_CVX_ETH_POOL)
            .calc_withdraw_one_coin(lpTokens, 0);
        ICurve(CURVE_CVX_ETH_POOL).remove_liquidity_one_coin(
            lpTokens,
            0,
            (withdrawAmount * slippage) / 10000,
            true
        );

        uint256 ethAmount = address(this).balance;
        if (ethAmount > 0) {
            address[9] memory _route = [
                0xEeeeeEeeeEeEeeEeEeEeeEEEeeeeEeeeeeeeEEeE, // ETH
                0xD51a44d3FaE010294C616388b506AcdA1bfAAE46, // tricrypto2 pool
                0xdAC17F958D2ee523a2206206994597C13D831ec7, // USDT
                0xbEbc44782C7dB0a1A60Cb6fe97d0b483032FF1C7, // 3pool
                address(want), // USDC
                address(0),
                address(0),
                address(0),
                address(0)
            ];
            uint256[3][4] memory _swap_params = [
                [uint256(2), uint256(0), uint256(3)], // ETH -> USDT, cryptoswap exchange
                [uint256(2), uint256(1), uint256(1)], // USDT -> USDC, stable swap exchange
                [uint256(0), uint256(0), uint256(0)],
                [uint256(0), uint256(0), uint256(0)]
            ];
            uint256 _expected = (ethToWant(ethAmount) * slippage) / 10000;
            ICurveSwapRouter(CURVE_SWAP_ROUTER).exchange_multiple{
                value: ethAmount
            }(_route, _swap_params, ethAmount, _expected);
        }
    }

    function liquidateAllPositions() internal override returns (uint256) {
        _exitPosition(balanceOfCurveLPStaked());
        return want.balanceOf(address(this));
    }

    function liquidatePosition(
        uint256 _amountNeeded
    ) internal override returns (uint256 _liquidatedAmount, uint256 _loss) {
        uint256 _wantBal = want.balanceOf(address(this));
        if (_wantBal >= _amountNeeded) {
            return (_amountNeeded, 0);
        }

        _withdrawSome(_amountNeeded - _wantBal);
        _wantBal = want.balanceOf(address(this));

        if (_amountNeeded > _wantBal) {
            _liquidatedAmount = _wantBal;
            _loss = _amountNeeded - _wantBal;
        } else {
            _liquidatedAmount = _amountNeeded;
        }
    }

    function prepareMigration(address _newStrategy) internal override {
        IConvexRewards(ETH_CVX_CONVEX_CRV_REWARDS).withdrawAndUnwrap(
            balanceOfCurveLPStaked(),
            true
        );
        IERC20(CRV).safeTransfer(
            _newStrategy,
            IERC20(CRV).balanceOf(address(this))
        );
        IERC20(CVX).safeTransfer(
            _newStrategy,
            IERC20(CVX).balanceOf(address(this))
        );
        IERC20(CURVE_CVX_ETH_LP).safeTransfer(
            _newStrategy,
            IERC20(CURVE_CVX_ETH_LP).balanceOf(address(this))
        );
        uint256 ethBal = address(this).balance;
        if (ethBal > 0) {
            payable(_newStrategy).transfer(ethBal);
        }
    }

    function protectedTokens()
        internal
        pure
        override
        returns (address[] memory)
    {
        address[] memory protected = new address[](3);
        protected[0] = CVX;
        protected[1] = CRV;
        protected[2] = CURVE_CVX_ETH_LP;
        return protected;
    }

    receive() external payable {}
}
