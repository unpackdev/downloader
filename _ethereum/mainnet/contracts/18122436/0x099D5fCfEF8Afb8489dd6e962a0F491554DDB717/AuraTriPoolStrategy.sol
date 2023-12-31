// SPDX-License-Identifier: AGPL-3.0

pragma solidity ^0.8.18;

import "./BaseStrategy.sol";

import "./Math.sol";
import "./Address.sol";
import "./IERC20.sol";
import "./ERC20.sol";
import "./SafeERC20.sol";
import "./OracleLibrary.sol";
import "./Initializable.sol";

import "./ICurve.sol";
import "./IBalancerV2Vault.sol";
import "./IBalancerPool.sol";
import "./IBalancerPriceOracle.sol";
import "./IConvexDeposit.sol";
import "./IConvexRewards.sol";
import "./IWSTEth.sol";

import "./AuraMath.sol";
import "./Utils.sol";

contract AuraTriPoolStrategy is BaseStrategy, Initializable {
    using SafeERC20 for IERC20;
    using Address for address;
    using AuraMath for uint256;

    IBalancerV2Vault internal constant balancerVault =
        IBalancerV2Vault(0xBA12222222228d8Ba445958a75a0704d566BF2C8);

    address internal constant AURA = 0xC0c293ce456fF0ED870ADd98a0828Dd4d2903DBF;
    address internal constant BAL = 0xba100000625a3754423978a60c9317c58a424e3D;
    address internal constant AURA_BOOSTER =
        0xA57b8d98dAE62B26Ec3bcC4a365338157060B234;
    address internal constant CURVE_SWAP_ROUTER =
        0x99a58482BD75cbab83b27EC03CA68fF489b5788f;

    address internal constant STETH =
        0xae7ab96520DE3A18E5e111B5EaAb095312D7fE84;
    address internal constant WSTETH =
        0x7f39C581F595B53c5cb19bD0b3f8dA6c935E2Ca0;

    address internal constant TRIPOOL_BALANCER_POOL =
        0x42ED016F826165C2e5976fe5bC3df540C5aD0Af7;
    bytes32 internal constant TRIPOOL_BALANCER_POOL_ID =
        0x42ed016f826165c2e5976fe5bc3df540c5ad0af700000000000000000000058b;

    bytes32 internal constant BAL_ETH_BALANCER_POOL_ID =
        bytes32(
            0x5c6ee304399dbdb9c8ef030ab642b10820db8f56000200000000000000000014
        );
    bytes32 internal constant AURA_ETH_BALANCER_POOL_ID =
        bytes32(
            0xc29562b045d80fd77c69bec09541f5c16fe20d9d000200000000000000000251
        );

    uint32 internal constant TWAP_RANGE_SECS = 1800;
    uint256 public slippage;
    uint256 public rewardsSlippage;

    uint256 public AURA_PID;
    address public AURA_TRIPOOL_REWARDS;

    constructor(address _vault) BaseStrategy(_vault) {}

    function initialize(
        address _vault,
        address _strategist
    ) public initializer {
        _initialize(_vault, _strategist, _strategist, _strategist);

        want.safeApprove(CURVE_SWAP_ROUTER, type(uint256).max);
        IERC20(STETH).safeApprove(CURVE_SWAP_ROUTER, type(uint256).max);
        IERC20(BAL).safeApprove(address(balancerVault), type(uint256).max);
        IERC20(AURA).safeApprove(address(balancerVault), type(uint256).max);
        IERC20(STETH).safeApprove(WSTETH, type(uint256).max);
        IERC20(WSTETH).safeApprove(address(balancerVault), type(uint256).max);
        IERC20(TRIPOOL_BALANCER_POOL).safeApprove(
            AURA_BOOSTER,
            type(uint256).max
        );

        slippage = 9850; // 1.5%
        rewardsSlippage = 9700; // 3%
        AURA_PID = 139;
        AURA_TRIPOOL_REWARDS = 0x032B676d5D55e8ECbAe88ebEE0AA10fB5f72F6CB;
    }

    function name() external pure override returns (string memory) {
        return "StrategyAuraTriPool";
    }

    function setSlippage(uint256 _slippage) external onlyStrategist {
        require(_slippage < 10_000, "!_slippage");
        slippage = _slippage;
    }

    function setRewardsSlippage(uint256 _slippage) external onlyStrategist {
        require(_slippage < 10_000, "!_slippage");
        rewardsSlippage = _slippage;
    }

    function setAuraPid(uint256 _pid) external onlyStrategist {
        AURA_PID = _pid;
    }

    function setAuraTriPoolRewards(
        address _auraTriPoolRewards
    ) external onlyStrategist {
        AURA_TRIPOOL_REWARDS = _auraTriPoolRewards;
    }

    function balanceOfWant() public view returns (uint256) {
        return want.balanceOf(address(this));
    }

    function balanceOfUnstakedBpt() public view returns (uint256) {
        return IERC20(TRIPOOL_BALANCER_POOL).balanceOf(address(this));
    }

    function balRewards() public view returns (uint256) {
        return IConvexRewards(AURA_TRIPOOL_REWARDS).earned(address(this));
    }

    function balanceOfAuraBpt() public view returns (uint256) {
        return IERC20(AURA_TRIPOOL_REWARDS).balanceOf(address(this));
    }

    function auraRewards(uint256 balTokens) public view returns (uint256) {
        return AuraRewardsMath.convertCrvToCvx(balTokens);
    }

    function auraToWant(uint256 auraTokens) public view returns (uint256) {
        uint unscaled = auraTokens.mul(getAuraPrice()).div(1e18);
        return Utils.scaleDecimals(unscaled, ERC20(AURA), ERC20(address(want)));
    }

    function balToWant(uint256 balTokens) public view returns (uint256) {
        uint unscaled = balTokens.mul(getBalPrice()).div(1e18);
        return Utils.scaleDecimals(unscaled, ERC20(BAL), ERC20(address(want)));
    }

    function wstethTokenRate()
        public
        view
        ensureNotInVaultContext
        returns (uint256)
    {
        uint256 rate = IBalancerPool(TRIPOOL_BALANCER_POOL).getRate();
        uint256 wstRate = IBalancerPool(TRIPOOL_BALANCER_POOL).getTokenRate(
            WSTETH
        );
        return (wstRate * 1e18) / rate;
    }

    function wstEthToBpt(uint256 wstEthTokens) public view returns (uint256) {
        uint256 tokenRate = bptToWstEth(1 ether);
        return (wstEthTokens * 1e18) / tokenRate;
    }

    function bptToWstEth(uint256 bptTokens) public view returns (uint256) {
        uint256 tokenRate = wstethTokenRate();
        return (bptTokens * 1e18) / tokenRate;
    }

    function wantToBpt(
        uint _amountWant
    ) public view virtual returns (uint _amount) {
        return wstEthToBpt(IWSTEth(WSTETH).getWstETHByStETH(_amountWant));
    }

    function bptToWant(uint bptTokens) public view returns (uint _amount) {
        return IWSTEth(WSTETH).getStETHByWstETH(bptToWstEth(bptTokens));
    }

    function estimatedTotalAssets()
        public
        view
        virtual
        override
        returns (uint256 _wants)
    {
        _wants = balanceOfWant();

        uint256 bptTokens = balanceOfUnstakedBpt() + balanceOfAuraBpt();
        _wants += bptToWant(bptTokens);
        uint256 balRewardTokens = balRewards();
        uint256 balTokens = balRewardTokens +
            ERC20(BAL).balanceOf(address(this));
        if (balTokens > 0) {
            _wants += balToWant(balTokens);
        }

        uint256 auraTokens = auraRewards(balRewardTokens) +
            ERC20(AURA).balanceOf(address(this));
        if (auraTokens > 0) {
            _wants += auraToWant(auraTokens);
        }

        return _wants;
    }

    function getBalPrice() public view returns (uint256 price) {
        address priceOracle = 0x5c6Ee304399DBdB9C8Ef030aB642B10820DB8F56;
        IBalancerPriceOracle.OracleAverageQuery[] memory queries;
        queries = new IBalancerPriceOracle.OracleAverageQuery[](1);
        queries[0] = IBalancerPriceOracle.OracleAverageQuery({
            variable: IBalancerPriceOracle.Variable.PAIR_PRICE,
            secs: 1800,
            ago: 0
        });
        uint256[] memory results = IBalancerPriceOracle(priceOracle)
            .getTimeWeightedAverage(queries);
        price = 1e36 / results[0];
    }

    function getAuraPrice() public view returns (uint256 price) {
        address priceOracle = 0xc29562b045D80fD77c69Bec09541F5c16fe20d9d;
        IBalancerPriceOracle.OracleAverageQuery[] memory queries;
        queries = new IBalancerPriceOracle.OracleAverageQuery[](1);
        queries[0] = IBalancerPriceOracle.OracleAverageQuery({
            variable: IBalancerPriceOracle.Variable.PAIR_PRICE,
            secs: 1800,
            ago: 0
        });
        uint256[] memory results;
        results = IBalancerPriceOracle(priceOracle).getTimeWeightedAverage(
            queries
        );
        price = results[0];
    }

    modifier ensureNotInVaultContext() {
        (, bytes memory revertData) = address(balancerVault).staticcall{
            gas: 10_000
        }(abi.encodeWithSelector(balancerVault.manageUserBalance.selector, 0));
        require(
            revertData.length == 0,
            "AuraWETHStrategy::ensureNotInVaultContext"
        );

        _;
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
            withdrawSome(_amountNeeded - _liquidWant);
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

        if (balRewards() > 0) {
            IConvexRewards(AURA_TRIPOOL_REWARDS).getReward(address(this), true);
        }
        _sellBalAndAura(
            IERC20(BAL).balanceOf(address(this)),
            IERC20(AURA).balanceOf(address(this))
        );

        uint256 _wantBal = want.balanceOf(address(this));
        if (_wantBal > _debtOutstanding) {
            uint256 _excessWant = _wantBal - _debtOutstanding;

            address[9] memory _route = [
                address(want), // WETH
                address(want), // no pool for WETH -> ETH,
                0xEeeeeEeeeEeEeeEeEeEeeEEEeeeeEeeeeeeeEEeE, // ETH
                0xDC24316b9AE028F1497c275EB9192a3Ea0f67022, // steth pool
                0xae7ab96520DE3A18E5e111B5EaAb095312D7fE84, // stETH
                address(0),
                address(0),
                address(0),
                address(0)
            ];
            uint256[3][4] memory _swap_params = [
                [uint256(0), uint256(0), uint256(15)],
                [uint256(0), uint256(1), uint256(1)], // WETH -> stETH, cryptoswap exchange
                [uint256(0), uint256(0), uint256(0)],
                [uint256(0), uint256(0), uint256(0)]
            ];

            ICurveSwapRouter(CURVE_SWAP_ROUTER).exchange_multiple(
                _route,
                _swap_params,
                _excessWant,
                (_excessWant * slippage) / 10_000
            );
        }

        uint256 stethBalance = IERC20(STETH).balanceOf(address(this));
        if (stethBalance > 0) {
            IWSTEth(WSTETH).wrap(stethBalance);
        }

        uint256 wstethBalance = IERC20(WSTETH).balanceOf(address(this));
        if (wstethBalance > 0) {
            uint256[] memory _amountsIn = new uint256[](3);
            _amountsIn[0] = wstethBalance;
            _amountsIn[1] = 0;
            _amountsIn[2] = 0;

            address[] memory _assets = new address[](4);
            _assets[0] = TRIPOOL_BALANCER_POOL;
            _assets[1] = WSTETH;
            _assets[2] = 0xac3E018457B222d93114458476f3E3416Abbe38F; // sfrxETH
            _assets[3] = 0xae78736Cd615f374D3085123A210448E74Fc6393; // rETH

            uint256[] memory _maxAmountsIn = new uint256[](4);
            _maxAmountsIn[0] = 0;
            _maxAmountsIn[1] = wstethBalance;
            _maxAmountsIn[2] = 0;
            _maxAmountsIn[3] = 0;

            uint256 expected = (wstEthToBpt(wstethBalance) * slippage) / 10000;
            bytes memory _userData = abi.encode(
                IBalancerV2Vault.JoinKind.EXACT_TOKENS_IN_FOR_BPT_OUT,
                _amountsIn,
                expected
            );
            IBalancerV2Vault.JoinPoolRequest memory _request;
            _request = IBalancerV2Vault.JoinPoolRequest({
                assets: _assets,
                maxAmountsIn: _maxAmountsIn,
                userData: _userData,
                fromInternalBalance: false
            });

            balancerVault.joinPool({
                poolId: TRIPOOL_BALANCER_POOL_ID,
                sender: address(this),
                recipient: payable(address(this)),
                request: _request
            });
        }

        if (balanceOfUnstakedBpt() > 0) {
            bool auraSuccess = IConvexDeposit(AURA_BOOSTER).depositAll(
                AURA_PID, // PID
                true // stake
            );
            require(auraSuccess, "Aura deposit failed");
        }
    }

    function _sellBalAndAura(uint256 _balAmount, uint256 _auraAmount) internal {
        if (_balAmount == 0) return;

        IBalancerV2Vault.BatchSwapStep[] memory swaps;
        if (_auraAmount == 0) {
            swaps = new IBalancerV2Vault.BatchSwapStep[](1);
        } else {
            swaps = new IBalancerV2Vault.BatchSwapStep[](2);
            swaps[1] = IBalancerV2Vault.BatchSwapStep({
                poolId: AURA_ETH_BALANCER_POOL_ID,
                assetInIndex: 1,
                assetOutIndex: 2,
                amount: _auraAmount,
                userData: abi.encode(0)
            });
        }

        // bal to weth
        swaps[0] = IBalancerV2Vault.BatchSwapStep({
            poolId: BAL_ETH_BALANCER_POOL_ID,
            assetInIndex: 0,
            assetOutIndex: 2,
            amount: _balAmount,
            userData: abi.encode(0)
        });

        address[] memory assets = new address[](3);
        assets[0] = BAL;
        assets[1] = AURA;
        assets[2] = address(want);

        int estimatedRewards = int(
            balToWant(_balAmount) + auraToWant(_auraAmount)
        );
        int[] memory limits = new int[](3);
        limits[0] = int(_balAmount);
        limits[1] = int(_auraAmount);
        limits[2] = (-1) * ((estimatedRewards * int(rewardsSlippage)) / 10000);

        balancerVault.batchSwap(
            IBalancerV2Vault.SwapKind.GIVEN_IN,
            swaps,
            assets,
            getFundManagement(),
            limits,
            block.timestamp
        );
    }

    function withdrawSome(uint256 _amountNeeded) internal {
        if (_amountNeeded == 0) {
            return;
        }

        uint256 balRewardTokens = balRewards();
        uint256 balTokens = balRewardTokens +
            ERC20(BAL).balanceOf(address(this));
        uint256 auraTokens = auraRewards(balRewardTokens) +
            ERC20(AURA).balanceOf(address(this));
        uint256 rewardsTotal = balToWant(balTokens) + auraToWant(auraTokens);

        if (rewardsTotal >= _amountNeeded) {
            IConvexRewards(AURA_TRIPOOL_REWARDS).getReward(address(this), true);
            _sellBalAndAura(
                IERC20(BAL).balanceOf(address(this)),
                IERC20(AURA).balanceOf(address(this))
            );
        } else {
            uint256 bptToUnstake = Math.min(
                wantToBpt(_amountNeeded - rewardsTotal),
                balanceOfAuraBpt()
            );

            if (bptToUnstake > 0) {
                _exitPosition(bptToUnstake);
            }
        }
    }

    function liquidatePosition(
        uint256 _amountNeeded
    ) internal override returns (uint256 _liquidatedAmount, uint256 _loss) {
        uint256 _wantBal = want.balanceOf(address(this));
        if (_wantBal < _amountNeeded) {
            withdrawSome(_amountNeeded - _wantBal);
            _wantBal = balanceOfWant();
        }

        if (_amountNeeded > _wantBal) {
            _liquidatedAmount = _wantBal;
            _loss = _amountNeeded - _wantBal;
        } else {
            _liquidatedAmount = _amountNeeded;
        }
    }

    function liquidateAllPositions() internal override returns (uint256) {
        _exitPosition(IERC20(AURA_TRIPOOL_REWARDS).balanceOf(address(this)));
        return want.balanceOf(address(this));
    }

    function _exitPosition(uint256 bptAmount) internal {
        IConvexRewards(AURA_TRIPOOL_REWARDS).withdrawAndUnwrap(bptAmount, true);

        _sellBalAndAura(
            IERC20(BAL).balanceOf(address(this)),
            IERC20(AURA).balanceOf(address(this))
        );

        address[] memory _assets = new address[](4);
        _assets[0] = TRIPOOL_BALANCER_POOL;
        _assets[1] = WSTETH;
        _assets[2] = 0xac3E018457B222d93114458476f3E3416Abbe38F;
        _assets[3] = 0xae78736Cd615f374D3085123A210448E74Fc6393;

        uint256[] memory _minAmountsOut = new uint256[](4);
        _minAmountsOut[0] = 0;
        _minAmountsOut[1] = (bptToWstEth(bptAmount) * slippage) / 10_000;
        _minAmountsOut[2] = 0;
        _minAmountsOut[3] = 0;

        bytes memory userData = abi.encode(
            IBalancerV2Vault.ExitKind.EXACT_BPT_IN_FOR_ONE_TOKEN_OUT,
            bptAmount,
            0 // exitTokenIndex
        );

        IBalancerV2Vault.ExitPoolRequest memory request;
        request = IBalancerV2Vault.ExitPoolRequest({
            assets: _assets,
            minAmountsOut: _minAmountsOut,
            userData: userData,
            toInternalBalance: false
        });

        balancerVault.exitPool({
            poolId: TRIPOOL_BALANCER_POOL_ID,
            sender: address(this),
            recipient: payable(address(this)),
            request: request
        });

        uint256 wstethBalance = IERC20(WSTETH).balanceOf(address(this));
        if (wstethBalance > 0) {
            IWSTEth(WSTETH).unwrap(wstethBalance);
        }

        uint256 stethBalance = IERC20(STETH).balanceOf(address(this));
        if (stethBalance > 0) {
            address[9] memory _route = [
                STETH,
                0xDC24316b9AE028F1497c275EB9192a3Ea0f67022, // steth pool
                0xEeeeeEeeeEeEeeEeEeEeeEEEeeeeEeeeeeeeEEeE, // ETH
                address(want), // no pool for WETH -> ETH,
                address(want), // WETH
                address(0),
                address(0),
                address(0),
                address(0)
            ];
            uint256[3][4] memory _swap_params = [
                [uint256(1), uint256(0), uint256(1)], // stETH -> WETH, stable swap exchange
                [uint256(0), uint256(0), uint256(15)],
                [uint256(0), uint256(0), uint256(0)],
                [uint256(0), uint256(0), uint256(0)]
            ];

            ICurveSwapRouter(CURVE_SWAP_ROUTER).exchange_multiple(
                _route,
                _swap_params,
                stethBalance,
                (stethBalance * slippage) / 10_000
            );
        }
    }

    function prepareMigration(address _newStrategy) internal override {
        IConvexRewards auraPool = IConvexRewards(AURA_TRIPOOL_REWARDS);
        auraPool.withdrawAndUnwrap(auraPool.balanceOf(address(this)), true);

        uint256 auraBal = IERC20(AURA).balanceOf(address(this));
        if (auraBal > 0) {
            IERC20(AURA).safeTransfer(_newStrategy, auraBal);
        }
        uint256 balancerBal = IERC20(BAL).balanceOf(address(this));
        if (balancerBal > 0) {
            IERC20(BAL).safeTransfer(_newStrategy, balancerBal);
        }
        uint256 bptBal = IERC20(TRIPOOL_BALANCER_POOL).balanceOf(address(this));
        if (bptBal > 0) {
            IERC20(TRIPOOL_BALANCER_POOL).safeTransfer(_newStrategy, bptBal);
        }
    }

    function ethToWant(
        uint256 _amtInWei
    ) public pure override returns (uint256) {
        return _amtInWei;
    }

    function protectedTokens()
        internal
        view
        override
        returns (address[] memory)
    {
        address[] memory protected = new address[](4);
        protected[0] = AURA_TRIPOOL_REWARDS;
        protected[1] = TRIPOOL_BALANCER_POOL;
        protected[2] = BAL;
        protected[3] = AURA;
        return protected;
    }

    function getFundManagement()
        internal
        view
        returns (IBalancerV2Vault.FundManagement memory fundManagement)
    {
        fundManagement = IBalancerV2Vault.FundManagement({
            sender: address(this),
            fromInternalBalance: false,
            recipient: payable(address(this)),
            toInternalBalance: false
        });
    }

    receive() external payable {}

    uint256[50] private __gap;
}
