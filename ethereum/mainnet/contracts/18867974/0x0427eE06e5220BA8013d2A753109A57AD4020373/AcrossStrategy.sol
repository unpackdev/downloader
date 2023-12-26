// SPDX-License-Identifier: AGPL-3.0

pragma solidity ^0.8.18;

import "./BaseStrategy.sol";
import "./ERC20.sol";
import "./Math.sol";
import "./SafeERC20.sol";
import "./OracleLibrary.sol";
import "./ISwapRouter.sol";

import "./Utils.sol";
import "./IAcrossHub.sol";
import "./IAcrossStaker.sol";

contract AcrossStrategy is BaseStrategy {
    using SafeERC20 for IERC20;

    address public constant ACROSS_HUB = 0xc186fA914353c44b2E33eBE05f21846F1048bEda;
    address public constant ACROSS_STAKER = 0x9040e41eF5E8b281535a96D9a48aCb8cfaBD9a48;
    address public constant LP_TOKEN = 0x28F77208728B0A45cAb24c4868334581Fe86F95B;
    address public constant WETH = 0xC02aaA39b223FE8D0A0e5C4F27eAD9083C756Cc2;
    address public constant REWARD_TOKEN = 0x44108f0223A3C3028F5Fe7AEC7f9bb2E66beF82F;
    address public constant UNISWAP_V3_ROUTER = 0xE592427A0AEce92De3Edee1F18E0157C05861564;
    address public constant ACX_WETH_UNI_POOL = 0x508acdC358be2ed126B1441F0Cff853dEc49d40F;

    uint32 internal constant TWAP_RANGE_SECS = 1800;
    uint256 public slippage;

    uint256 private WANT_DECIMALS;

    constructor(address _vault) BaseStrategy(_vault) {}

    function initialize(address _vault, address _strategist) external {
        _initialize(_vault, _strategist, _strategist, _strategist);

        want.safeApprove(ACROSS_HUB, type(uint256).max);
        IERC20(LP_TOKEN).safeApprove(ACROSS_STAKER, type(uint256).max);
        IERC20(LP_TOKEN).safeApprove(ACROSS_HUB, type(uint256).max);
        WANT_DECIMALS = ERC20(address(want)).decimals();
        IERC20(REWARD_TOKEN).safeApprove(UNISWAP_V3_ROUTER, type(uint256).max);
        slippage = 9800; // 2%
    }

    function ethToWant(uint256 _amtInWei) public view virtual override returns (uint256){
        return 0;
    }

    function setSlippage(uint256 _slippage) external onlyStrategist {
        require(_slippage < 10_000, "!_slippage");
        slippage = _slippage;
    }

    function name() external pure override returns (string memory) {
        return "AcrossStrategy WETH";
    }

    function balanceOfWant() public view returns (uint256) {
        return want.balanceOf(address(this));
    }

    function balanceOfLPUnstaked() public view returns (uint256) {
        return ERC20(LP_TOKEN).balanceOf(address(this));
    }

    function balanceOfLPStaked() public view returns (uint256) {
        return
            IAcrossStaker(ACROSS_STAKER).getUserStake(LP_TOKEN, address(this)).cumulativeBalance;
    }

    function getRewards() public view virtual returns (uint256) {
        return IAcrossStaker(ACROSS_STAKER).getOutstandingRewards(LP_TOKEN, address(this));
    }

    function LPToWant(uint256 _lpTokens) public view returns (uint256) {
        return _lpTokens * _exchangeRate() / 1e18;
    }

    function wantToLp(uint256 _wantAmount) public view returns(uint256){
       return (_wantAmount * 1e18) / _exchangeRate();
    }

    function _withdrawSome(uint256 _amountNeeded) internal {
        if (_amountNeeded == 0) {
            return;
        }
        
            uint256 lpTokensToWithdraw = Math.min(
                wantToLp(_amountNeeded),
                balanceOfLPStaked()
            );
            _exitPosition(lpTokensToWithdraw);
        
    }

    function estimatedTotalAssets()
        public
        view
        virtual
        override
        returns (uint256 _wants)
    {
        _wants += want.balanceOf(address(this));
        _wants += LPToWant(IAcrossStaker(ACROSS_STAKER).getUserStake(LP_TOKEN, address(this)).cumulativeBalance);
        _wants += AcxToWant(IAcrossStaker(ACROSS_STAKER).getOutstandingRewards(WETH, address(this)));
        _wants += LPToWant(IERC20(LP_TOKEN).balanceOf(address(this)));
        // console.log(want.balanceOf(address(this)));
        // console.log(IAcrossStaker(ACROSS_STAKER).getUserStake(WETH, address(this)).cumulativeBalance);
        // console.log(IAcrossStaker(ACROSS_STAKER).getOutstandingRewards(WETH, address(this)));
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

    function _exchangeRate() internal view returns(uint256){
        IAcrossHub.PooledToken memory pooledToken = IAcrossHub(ACROSS_HUB).pooledTokens(WETH); // Note this is storage so the state can be modified.
        uint256 lpTokenTotalSupply = IERC20(pooledToken.lpToken).totalSupply();
        int256 numerator = int256(pooledToken.liquidReserves) +
            pooledToken.utilizedReserves -
            int256(pooledToken.undistributedLpFees);
        return (uint256(numerator) * 1e18) / lpTokenTotalSupply;
    }

    function adjustPosition(uint256 _debtOutstanding) internal override {
        if (emergencyExit) {
            return;
        }

        uint256 _wantBal = balanceOfWant();
        uint256 _excessWant = 0;
        if (_wantBal > _debtOutstanding) {
            _excessWant = _wantBal - _debtOutstanding;
        }

        if (_excessWant > 0) {
            IAcrossHub(ACROSS_HUB).addLiquidity(WETH, _excessWant);

        }
        if (balanceOfLPUnstaked() > 0) {
            IAcrossStaker(ACROSS_STAKER).stake(LP_TOKEN, IERC20(LP_TOKEN).balanceOf(address(this)));
        }
    }

    function smthToSmth(
        address pool,
        address tokenFrom,
        address tokenTo,
        uint256 amount
    ) internal view returns (uint256) {
        (int24 meanTick, ) = OracleLibrary.consult(pool, TWAP_RANGE_SECS);
        return
            OracleLibrary.getQuoteAtTick(
                meanTick,
                uint128(amount),
                tokenFrom,
                tokenTo
            );
    }

    function AcxToWant(
        uint256 amountIn
    ) internal view returns (uint256 amountOut) {
        if (amountIn == 0) {
            return 0;
        }
        amountOut = smthToSmth(
            ACX_WETH_UNI_POOL,
            REWARD_TOKEN,
            WETH,
            amountIn
        );
    }

    function claimAndSell() external onlyStrategist{
        IAcrossStaker(ACROSS_STAKER).withdrawReward(LP_TOKEN);
        ISwapRouter.ExactInputSingleParams memory params;
        params.tokenIn = REWARD_TOKEN;
        params.tokenOut = WETH;
        params.fee = 10000;
        params.recipient = address(this);
        params.deadline = block.timestamp;
        params.amountIn = IERC20(REWARD_TOKEN).balanceOf(address(this));
        params.amountOutMinimum = AcxToWant(IERC20(REWARD_TOKEN).balanceOf(address(this))) * slippage / 10000;
        params.sqrtPriceLimitX96 = 0;
        ISwapRouter(UNISWAP_V3_ROUTER).exactInputSingle(params);
    }

    function _exitPosition(uint256 _stakedLpTokens) internal {
        IAcrossStaker(ACROSS_STAKER).unstake(
            LP_TOKEN,
            _stakedLpTokens
        );

        uint256 lpTokens = ERC20(LP_TOKEN).balanceOf(address(this));
        // uint256 withdrawAmount = IAcrossHub(ACROSS_HUB).exchangeRateCurrent(WETH) * balanceOfLPUnstaked() / 1e18;

        IAcrossHub(ACROSS_HUB).removeLiquidity(WETH, _stakedLpTokens, false);
        
    }

    function liquidateAllPositions() internal override returns (uint256) {
        _exitPosition(balanceOfLPStaked());
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
        IAcrossStaker(ACROSS_STAKER).unstake(
            LP_TOKEN,
            balanceOfLPStaked()
        );
        IERC20(LP_TOKEN).safeTransfer(
            _newStrategy,
            IERC20(LP_TOKEN).balanceOf(address(this))
        );
    }

    function protectedTokens()
        internal
        pure
        override
        returns (address[] memory)
    {
        address[] memory protected = new address[](3);
        protected[0] = LP_TOKEN;
        protected[1] = WETH;
        return protected;
    }

    receive() external payable {}
}
