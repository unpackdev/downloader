// SPDX-License-Identifier: MIT

pragma solidity ^0.6.0;

import "./SafeERC20.sol";
import "./SafeMathUpgradeable.sol";
import "./PausableUpgradeable.sol";

import "./StratBase.sol";
import "./ICurveStableSwap.sol";
import "./ILPStaking.sol";
import "./ILPToken.sol";
import "./IStargateRouter.sol";

contract StratStargate is StratBase, PausableUpgradeable {
    using SafeERC20 for IERC20;
    using SafeMathUpgradeable for uint256;

    IStargateRouter public stargateRouter;
    ILPStaking public lpStaking;

    uint256 pid;

    IERC20 public stargate;

    IERC20 public underlyingToken;

    struct CurvePoolConfig {
        address pool;
        bool is128;
        int128 i;
        int128 j;
    }
    // curve routes
    CurvePoolConfig[] public stargateToWantRoute;

    bool public harvestOnDeposit;

    uint256 public constant FEE_PRECISION = 1e6;
    uint256 public harvestFeeRate;
    uint256 public withdrawalFeeRate;

    event StargateRouterUpdated(address _stargateRouter);
    event LPStakingUpdated(address _lpStaking);
    event PidUpdated(uint256 _pid);
    event Deposited(uint256 _amount);
    event Withdrawn(uint256 _amount, uint256 _withdrawalFee);
    event Harvested(uint256 _amount, uint256 _harvestFee);
    event HarvestFeeRateUpdated(uint256 _feeRate);
    event WithdrawalFeeRateUpdated(uint256 _feeRate);

    function initialize() public initializer {
        __StratBase_init();

        __Pausable_init_unchained();
    }

    function setParams(
        address _vault,
        address _want,
        address _keeper,
        address _feeRecipient,
        address _stargateRouter,
        address _lpStaking,
        uint256 _pid,
        address[] memory _pools,
        bool[] memory _is128,
        int128[] memory _i,
        int128[] memory _j
    ) external onlyOwner {
        setAddresses(_vault, _want, _keeper, _feeRecipient);

        underlyingToken = IERC20(ILPToken(_want).token());

        stargateRouter = IStargateRouter(_stargateRouter);
        lpStaking = ILPStaking(_lpStaking);

        (address lpToken, , , ) = lpStaking.poolInfo(_pid);
        require(_want == lpToken, "invalid _want or _pid");
        pid = _pid;

        stargate = IERC20(lpStaking.stargate());

        _checkRoute(_pools, _i, _j);
        for (uint256 index; index < _pools.length; index++) {
            stargateToWantRoute.push(
                CurvePoolConfig({
                    pool: _pools[index],
                    is128: _is128[index],
                    i: _i[index],
                    j: _j[index]
                })
            );
        }

        _giveAllowances();

        harvestOnDeposit = true;

        emit StargateRouterUpdated(_stargateRouter);
        emit LPStakingUpdated(_lpStaking);
        emit PidUpdated(_pid);
    }

    function _checkRoute(
        address[] memory _pools,
        int128[] memory _i,
        int128[] memory _j
    ) internal view {
        require(
            _pools.length > 0 &&
                _pools.length == _i.length &&
                _pools.length == _j.length,
            "invalid _pools or _i or _j"
        );
        address token = address(stargate);
        for (uint256 index; index < _pools.length; index++) {
            ICurveStableSwap pool = ICurveStableSwap(_pools[index]);
            require(token == pool.coins(uint256(_i[index])), "invalid route");
            token = pool.coins(uint256(_j[index]));
        }
        require(token == address(underlyingToken), "invalid route");
    }

    function beforeDeposit() external override onlyVault {
        if (!harvestOnDeposit) {
            return;
        }
        harvest();
    }

    function deposit() public override whenNotPaused {
        uint256 wantBal = want.balanceOf(address(this));

        if (wantBal > 0) {
            lpStaking.deposit(pid, wantBal);

            emit Deposited(wantBal);
        }
    }

    function withdraw(uint256 _amount) external override onlyVault {
        uint256 wantBal = want.balanceOf(address(this));

        if (wantBal < _amount) {
            lpStaking.withdraw(pid, _amount.sub(wantBal));
            wantBal = want.balanceOf(address(this));
        }

        if (wantBal > _amount) {
            wantBal = _amount;
        }

        uint256 withdrawalFee = wantBal.mul(withdrawalFeeRate).div(
            FEE_PRECISION
        );
        want.safeTransfer(feeRecipient, withdrawalFee);
        want.safeTransfer(vault, wantBal.sub(withdrawalFee));

        emit Withdrawn(_amount, withdrawalFee);
    }

    // calculate the total underlying 'want' held by the strat.
    function balanceOf() external view override returns (uint256) {
        return balanceOfWant().add(balanceOfPool());
    }

    // it calculates how much 'want' this contract holds.
    function balanceOfWant() public view override returns (uint256) {
        return want.balanceOf(address(this));
    }

    // it calculates how much 'want' the strategy has working in the farm.
    function balanceOfPool() public view override returns (uint256) {
        (uint256 _amount, ) = lpStaking.userInfo(pid, address(this));
        return _amount;
    }

    // compounds earnings
    function harvest() public override whenNotPaused {
        if (balanceOfPool() > 0) {
            // claim stargate
            lpStaking.deposit(pid, 0);

            uint256 stargateBal = stargate.balanceOf(address(this));
            if (stargateBal > 0) {
                // charge fees
                uint256 harvestFee = stargateBal.mul(harvestFeeRate).div(
                    FEE_PRECISION
                );
                stargate.safeTransfer(feeRecipient, harvestFee);

                // swap back to underlying token
                _swapStargateToUnderlying(stargateBal.sub(harvestFee));

                // Adds liquidity and gets more want tokens.
                uint256 underlyingTokenBal = underlyingToken.balanceOf(
                    address(this)
                );
                stargateRouter.addLiquidity(
                    ILPToken(address(want)).poolId(),
                    underlyingTokenBal,
                    address(this)
                );

                // reinvest
                deposit();

                emit Harvested(stargateBal, harvestFee);
            }
        }
    }

    function _swapStargateToUnderlying(uint256 _stargateBal)
        internal
        returns (uint256)
    {
        if (_estimateSwappedUnderlying(_stargateBal) == 0) {
            return 0;
        }
        uint256 amount = _stargateBal;
        for (uint256 index; index < stargateToWantRoute.length; index++) {
            CurvePoolConfig memory config = stargateToWantRoute[index];
            IERC20 coin = IERC20(
                ICurveStableSwap(config.pool).coins(uint256(config.j))
            );
            uint256 coinBalBefore = coin.balanceOf(address(this));
            if (config.is128) {
                ICurveStableSwap128(config.pool).exchange(
                    config.i,
                    config.j,
                    amount,
                    0
                );
            } else {
                ICurveStableSwap256(config.pool).exchange(
                    uint256(config.i),
                    uint256(config.j),
                    amount,
                    0
                );
            }
            uint256 coinBalAfter = coin.balanceOf(address(this));
            amount = coinBalAfter.sub(coinBalBefore);
            if (amount == 0) {
                break;
            }
        }
        return amount;
    }

    function _estimateSwappedUnderlying(uint256 _stargateBal)
        internal
        view
        returns (uint256)
    {
        if (_stargateBal == 0) {
            return 0;
        }
        uint256 amount = _stargateBal;
        for (uint256 index; index < stargateToWantRoute.length; index++) {
            CurvePoolConfig memory config = stargateToWantRoute[index];
            if (config.is128) {
                amount = ICurveStableSwap128(config.pool).get_dy(
                    config.i,
                    config.j,
                    amount
                );
            } else {
                amount = ICurveStableSwap256(config.pool).get_dy(
                    uint256(config.i),
                    uint256(config.j),
                    amount
                );
            }
            if (amount == 0) {
                break;
            }
        }
        return amount;
    }

    // called as part of strat migration. Sends all the available funds back to the vault.
    function retireStrat() external override onlyVault {
        lpStaking.emergencyWithdraw(pid);

        uint256 wantBal = want.balanceOf(address(this));
        want.safeTransfer(vault, wantBal);
    }

    // pauses deposits and withdraws all funds from third party systems.
    function panic() public onlyManager {
        pause();
        lpStaking.emergencyWithdraw(pid);
    }

    function pause() public onlyManager {
        _pause();

        _removeAllowances();
    }

    function unpause() external onlyManager {
        _unpause();

        _giveAllowances();

        deposit();
    }

    function _giveAllowances() internal {
        want.safeApprove(address(lpStaking), uint256(-1));
        for (uint256 index; index < stargateToWantRoute.length; index++) {
            CurvePoolConfig memory config = stargateToWantRoute[index];
            IERC20(ICurveStableSwap(config.pool).coins(uint256(config.i)))
                .safeApprove(address(config.pool), uint256(-1));
        }
        underlyingToken.safeApprove(address(stargateRouter), uint256(-1));
    }

    function _removeAllowances() internal {
        want.safeApprove(address(lpStaking), 0);
        for (uint256 index; index < stargateToWantRoute.length; index++) {
            CurvePoolConfig memory config = stargateToWantRoute[index];
            IERC20(ICurveStableSwap(config.pool).coins(uint256(config.i)))
                .safeApprove(address(config.pool), 0);
        }
        underlyingToken.safeApprove(address(stargateRouter), 0);
    }

    function setHarvestOnDeposit(bool _harvestOnDeposit) external onlyManager {
        harvestOnDeposit = _harvestOnDeposit;
    }

    function setHarvestFeeRate(uint256 _feeRate) external onlyManager {
        require(_feeRate <= FEE_PRECISION, "!cap");

        harvestFeeRate = _feeRate;
        emit HarvestFeeRateUpdated(_feeRate);
    }

    function setWithdrawalFeeRate(uint256 _feeRate) external onlyManager {
        require(_feeRate <= FEE_PRECISION, "!cap");

        withdrawalFeeRate = _feeRate;
        emit WithdrawalFeeRateUpdated(_feeRate);
    }
}
