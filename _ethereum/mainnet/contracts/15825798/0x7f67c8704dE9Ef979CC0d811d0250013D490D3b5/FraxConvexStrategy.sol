// SPDX-License-Identifier: AGPL-3.0

pragma solidity >=0.8.0 <0.9.0;

import "./IERC20.sol";
import "./SafeERC20.sol";
import "./Math.sol";
import "./SafeMath.sol";
import "./StrategyConvexBase.sol";
import "./ICurveFi.sol";
import "./IConvexDeposit.sol";
import "./IConvexRewards.sol";
import "./IOracle.sol";
import "./IBaseFee.sol";
import "./IUniswapV2Router02.sol";
import "./IUniV3.sol";

contract FraxConvexStrategy is StrategyConvexBase {
    using SafeERC20 for IERC20;
    using SafeMath for uint256;

    /* ========== STATE VARIABLES ========== */
    // these will likely change across different wants.

    // Curve stuff
    address public curve; // Curve Pool, this is our pool specific to this vault
    ICurveFi internal constant _ZAP_CONTRACT = ICurveFi(0xA79828DF1850E8a3A3064576f380D90aECDD3359); // this is used for depositing to all 3Crv metapools

    // use Curve to sell our CVX and CRV rewards to WETH
    ICurveFi internal constant _CRV_ETH = ICurveFi(0x8301AE4fc9c624d1D396cbDAa1ed877821D7C511); // use curve's new CRV-ETH crypto pool to sell our CRV
    ICurveFi internal constant _CVX_ETH = ICurveFi(0xB576491F1E6e5E62f1d8F26062Ee822B40B0E0d4); // use curve's new CVX-ETH crypto pool to sell our CVX

    // we use these to deposit to our curve pool
    address public targetStable;
    address internal constant _UNISWAP_V3 = 0xE592427A0AEce92De3Edee1F18E0157C05861564;
    IERC20 internal constant _USDT = IERC20(0xdAC17F958D2ee523a2206206994597C13D831ec7);
    IERC20 internal constant _USDC = IERC20(0xA0b86991c6218b36c1d19D4a2e9Eb0cE3606eB48);
    IERC20 internal constant _DAI = IERC20(0x6B175474E89094C44Da98b954EedeAC495271d0F);
    uint24 public uniStableFee; // this is equal to 0.05%, can change this later if a different path becomes more optimal

    // rewards token info. we can have more than 1 reward token but this is rare, so we don't include this in the template
    IERC20 public rewardsToken;
    bool public hasRewards;
    address[] internal _rewardsPath;

    // check for cloning
    bool internal _isOriginal = true;

    /* ========== CONSTRUCTOR ========== */

    constructor(
        address _vault,
        uint256 _pid,
        address _curvePool,
        string memory _name
    ) StrategyConvexBase(_vault) {
        _initializeStrat(_pid, _curvePool, _name);
    }

    /* ========== CLONING ========== */

    event Cloned(address indexed clone);

    // we use this to clone our original strategy to other vaults
    function cloneConvex3CrvRewards(
        address _vault,
        address _strategist,
        address _rewards,
        address _keeper,
        uint256 _pid,
        address _curvePool,
        string memory _name
    ) external returns (address newStrategy) {
        require(_isOriginal);
        bytes20 addressBytes = bytes20(address(this));
        assembly {
            // EIP-1167 bytecode
            let clone_code := mload(0x40)
            mstore(clone_code, 0x3d602d80600a3d3981f3363d3d373d3d3d363d73000000000000000000000000)
            mstore(add(clone_code, 0x14), addressBytes)
            mstore(add(clone_code, 0x28), 0x5af43d82803e903d91602b57fd5bf30000000000000000000000000000000000)
            newStrategy := create(0, clone_code, 0x37)
        }

        FraxConvexStrategy(newStrategy).initialize(_vault, _strategist, _rewards, _keeper, _pid, _curvePool, _name);

        emit Cloned(newStrategy);
    }

    // this will only be called by the clone function above
    function initialize(
        address _vault,
        address _strategist,
        address _rewards,
        address _keeper,
        uint256 _pid,
        address _curvePool,
        string memory _name
    ) public {
        _initialize(_vault, _strategist, _rewards, _keeper);
        _initializeStrat(_pid, _curvePool, _name);
    }

    // this is called by our original strategy, as well as any clones
    function _initializeStrat(
        uint256 _pid,
        address _curvePool,
        string memory _name
    ) internal {
        // make sure that we haven't initialized this before
        require(address(curve) == address(0));

        // 21 days in seconds, if we hit this then harvestTrigger = True
        maxReportDelay = 21 days;

        // want = Curve LP
        want.approve(address(_DEPOSIT_CONTRACT), type(uint256).max);
        _CONVEX_TOKEN.approve(address(_CVX_ETH), type(uint256).max);
        _CRV.approve(address(_CRV_ETH), type(uint256).max);
        _WETH.approve(_UNISWAP_V3, type(uint256).max);

        // this is the pool specific to this vault, but we only use it as an address
        curve = address(_curvePool);

        // setup our rewards contract
        pid = _pid;
        // this is the pool ID on convex, we use this to determine what the rewardsContract address is
        (address lptoken, , , address _rewardsContract, , ) = IConvexDeposit(_DEPOSIT_CONTRACT).poolInfo(_pid);

        // set up our rewardsContract
        rewardsContract = IConvexRewards(_rewardsContract);

        // check that our LP token based on our pid matches our want
        require(address(lptoken) == address(want), "Wrong PID number");

        // set our strategy's name
        _stratName = _name;

        // these are our approvals and path specific to this contract
        _DAI.approve(address(_ZAP_CONTRACT), type(uint256).max);
        _USDT.safeApprove(address(_ZAP_CONTRACT), type(uint256).max);
        // USDT requires safeApprove(), funky token
        _USDC.approve(address(_ZAP_CONTRACT), type(uint256).max);

        // start with usdt
        targetStable = address(_USDT);

        // set our uniswap pool fees
        uniStableFee = 500;
    }

    /* ========== MUTATIVE FUNCTIONS ========== */

    function _prepareReturn(uint256 _debtOutstanding)
        internal
        override
        returns (
            uint256 _profit,
            uint256 _loss,
            uint256 _debtPayment
        )
    {
        // this claims our CRV, CVX, and any extra tokens like SNX or ANKR. no harm leaving this true even if no extra rewards currently.
        rewardsContract.getReward(address(this), true);

        // claim and sell our rewards if we have them
        if (hasRewards) {
            uint256 _rewardsBalance = IERC20(rewardsToken).balanceOf(address(this));
            if (_rewardsBalance > 0) {
                _sellRewards(_rewardsBalance);
            }
        }

        uint256 crvBalance = _CRV.balanceOf(address(this));
        uint256 convexBalance = _CONVEX_TOKEN.balanceOf(address(this));

        // do this even if we have zero balances so we can sell WETH from rewards
        _sellCrvAndCvx(crvBalance, convexBalance);

        // check for balances of tokens to deposit
        uint256 _daiBalance = _DAI.balanceOf(address(this));
        uint256 _usdcBalance = _USDC.balanceOf(address(this));
        uint256 _usdtBalance = _USDT.balanceOf(address(this));

        // deposit our balance to Curve if we have any
        if (_daiBalance > 0 || _usdcBalance > 0 || _usdtBalance > 0) {
            _ZAP_CONTRACT.add_liquidity(curve, [0, _daiBalance, _usdcBalance, _usdtBalance], 0);
        }

        // debtOustanding will only be > 0 in the event of revoking or if we need to rebalance from a withdrawal or lowering the debtRatio
        if (_debtOutstanding > 0) {
            uint256 _stakedBal = stakedBalance();
            if (_stakedBal > 0) {
                rewardsContract.withdrawAndUnwrap(Math.min(_stakedBal, _debtOutstanding), claimRewards);
            }
            uint256 _withdrawnBal = balanceOfWant();
            _debtPayment = Math.min(_debtOutstanding, _withdrawnBal);
        }

        // serious loss should never happen, but if it does (for instance, if Curve is hacked), let's record it accurately
        uint256 assets = estimatedTotalAssets();
        uint256 debt = vault.strategies(address(this)).totalDebt;

        // if assets are greater than debt, things are working great!
        if (assets > debt) {
            _profit = assets.sub(debt);
            uint256 _wantBal = balanceOfWant();
            if (_profit.add(_debtPayment) > _wantBal) {
                // this should only be hit following donations to strategy
                _liquidateAllPositions();
            }
        }
        // if assets are less than debt, we are in trouble
        else {
            _loss = debt.sub(assets);
        }
    }

    // migrate our want token to a new strategy if needed, make sure to check claimRewards first
    // also send over any CRV or CVX that is claimed; for migrations we definitely want to claim
    function _prepareMigration(address _newStrategy) internal override {
        uint256 _stakedBal = stakedBalance();
        if (_stakedBal > 0) {
            rewardsContract.withdrawAndUnwrap(_stakedBal, claimRewards);
        }
        _CRV.safeTransfer(_newStrategy, _CRV.balanceOf(address(this)));
        _CONVEX_TOKEN.safeTransfer(_newStrategy, _CONVEX_TOKEN.balanceOf(address(this)));
    }

    // Sells our CRV and CVX on Curve, then WETH -> stables together on UniV3
    function _sellCrvAndCvx(uint256 _crvAmount, uint256 _convexAmount) internal {
        if (_convexAmount > 1e17) {
            // don't want to swap dust or we might revert
            _CVX_ETH.exchange(1, 0, _convexAmount, 0, false);
        }

        if (_crvAmount > 1e17) {
            // don't want to swap dust or we might revert
            _CRV_ETH.exchange(1, 0, _crvAmount, 0, false);
        }

        uint256 _wethBalance = _WETH.balanceOf(address(this));
        if (_wethBalance > 1e15) {
            // don't want to swap dust or we might revert
            IUniV3(_UNISWAP_V3).exactInput(
                IUniV3.ExactInputParams(
                    abi.encodePacked(address(_WETH), uint24(uniStableFee), address(targetStable)),
                    address(this),
                    block.timestamp,
                    _wethBalance,
                    uint256(1)
                )
            );
        }
    }

    // Sells our harvested reward token into the selected output.
    function _sellRewards(uint256 _amount) internal {
        IUniswapV2Router02(_SUSHI_SWAP).swapExactTokensForTokens(
            _amount,
            uint256(0),
            _rewardsPath,
            address(this),
            block.timestamp
        );
    }

    /// @notice The value in dollars that our claimable rewards are worth (in USDT, 6 decimals).
    function claimableProfitInUsdt() public view returns (uint256) {
        // calculations pulled directly from CVX's contract for minting CVX per CRV claimed
        uint256 totalCliffs = 1_000;
        uint256 maxSupply = 100 * 1_000_000 * 1e18;
        // 100mil
        uint256 reductionPerCliff = 100_000 * 1e18;
        // 100,000
        uint256 supply = _CONVEX_TOKEN.totalSupply();
        uint256 mintableCvx;

        uint256 cliff = supply.div(reductionPerCliff);
        uint256 _claimableBal = claimableBalance();
        //mint if below total cliffs
        if (cliff < totalCliffs) {
            //for reduction% take inverse of current cliff
            uint256 reduction = totalCliffs.sub(cliff);
            //reduce
            mintableCvx = _claimableBal.mul(reduction).div(totalCliffs);

            //supply cap check
            uint256 amtTillMax = maxSupply.sub(supply);
            if (mintableCvx > amtTillMax) {
                mintableCvx = amtTillMax;
            }
        }

        // our chainlink oracle returns prices normalized to 8 decimals, we convert it to 6
        IOracle ethOracle = IOracle(0x5f4eC3Df9cbd43714FE2740f5E3616155c5b8419);
        uint256 ethPrice = ethOracle.latestAnswer().div(1e2);
        // 1e8 div 1e2 = 1e6
        uint256 crvPrice = _CRV_ETH.price_oracle().mul(ethPrice).div(1e18);
        // 1e18 mul 1e6 div 1e18 = 1e6
        uint256 cvxPrice = _CVX_ETH.price_oracle().mul(ethPrice).div(1e18);
        // 1e18 mul 1e6 div 1e18 = 1e6

        uint256 crvValue = crvPrice.mul(_claimableBal).div(1e18);
        // 1e6 mul 1e18 div 1e18 = 1e6
        uint256 cvxValue = cvxPrice.mul(mintableCvx).div(1e18);
        // 1e6 mul 1e18 div 1e18 = 1e6

        // get the value of our rewards token if we have one
        uint256 rewardsValue;
        if (hasRewards) {
            address[] memory usdPath = new address[](3);
            usdPath[0] = address(rewardsToken);
            usdPath[1] = address(_WETH);
            usdPath[2] = address(_USDT);

            uint256 _claimableBonusBal = IConvexRewards(virtualRewardsPool).earned(address(this));
            if (_claimableBonusBal > 0) {
                uint256[] memory rewardSwap = IUniswapV2Router02(_SUSHI_SWAP).getAmountsOut(
                    _claimableBonusBal,
                    usdPath
                );
                rewardsValue = rewardSwap[rewardSwap.length - 1];
            }
        }

        return crvValue.add(cvxValue).add(rewardsValue);
    }

    // convert our keeper's eth cost into want, we don't need this anymore since we don't use baseStrategy harvestTrigger
    function ethToWant(uint256 _ethAmount) public view override returns (uint256) {}

    /* ========== SETTERS ========== */

    // These functions are useful for setting parameters of the strategy that may need to be adjusted.

    /// @notice Set optimal token to sell harvested funds for depositing to Curve.
    function setOptimal(uint256 _optimal) external onlyGovernance {
        if (_optimal == 0) {
            targetStable = address(_DAI);
        } else if (_optimal == 1) {
            targetStable = address(_USDC);
        } else if (_optimal == 2) {
            targetStable = address(_USDT);
        } else {
            revert("incorrect token");
        }
    }

    // Use to add, update or remove rewards
    function updateRewards(bool _hasRewards, uint256 _rewardsIndex) external onlyGovernance {
        if (address(rewardsToken) != address(0) && address(rewardsToken) != address(_CONVEX_TOKEN)) {
            rewardsToken.approve(_SUSHI_SWAP, uint256(0));
        }
        if (_hasRewards == false) {
            hasRewards = false;
            rewardsToken = IERC20(address(0));
            virtualRewardsPool = address(0);
        } else {
            // update with our new token. get this via our virtualRewardsPool
            virtualRewardsPool = rewardsContract.extraRewards(_rewardsIndex);
            address _rewardsToken = IConvexRewards(virtualRewardsPool).rewardToken();
            rewardsToken = IERC20(_rewardsToken);

            // approve, setup our path, and turn on rewards
            rewardsToken.approve(_SUSHI_SWAP, type(uint256).max);
            _rewardsPath = [address(rewardsToken), address(_WETH)];
            hasRewards = true;
        }
    }

    /// @notice Set the fee pool we'd like to swap through on UniV3 (1% = 10_000)
    function setUniFees(uint24 _stableFee) external onlyGovernance {
        uniStableFee = _stableFee;
    }
}
