/**
 *Submitted for verification at Etherscan.io on 2021-05-30
*/

// SPDX-License-Identifier: AGPL-3.0

pragma solidity ^0.8.2;
pragma experimental ABIEncoderV2;


import "./IBooster.sol";
import "./ICurveFi.sol";
import "./IERC20.sol";
import "./IERC20Metadata.sol";
import "./IRewards.sol";
import "./IUni.sol";
import "./Address.sol";
import "./Math.sol";
import "./SafeERC20.sol";
import "./BaseStrategy.sol";
import "./Initializable.sol";



// Part: ConvexStable

abstract contract ConvexCrvLp is BaseStrategy {
    using SafeERC20 for IERC20;

    address public constant booster = address(0xF403C135812408BFbE8713b5A23a04b3D48AAE31);

    address public constant cvx = address(0x4e3FBD56CD56c3e72c1403e103b45Db9da5B9D2B);
    address public constant crv = address(0xD533a949740bb3306d119CC777fa900bA034cd52);
    address public constant weth = address(0xC02aaA39b223FE8D0A0e5C4F27eAD9083C756Cc2);

    // address public constant quoter = address(0xb27308f9F90D607463bb33eA1BeBb41C27CE5AB6);
    // address public constant uniswapv3 = address(0xE592427A0AEce92De3Edee1F18E0157C05861564);
    address public constant uniswap = address(0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D);
    address public constant sushiswap = address(0xd9e1cE17f2641f24aE83637ab66a2cca9C378B9F);

    bool public isClaimRewards;
    bool public isClaimExtras;
    uint256 public id;
    address public rewardContract;
    address public curve;

    IERC20 public want_wrapped;
    uint public constant MAX_SLIPPAGE_FACTOR = 1000000;
    uint public slippage_factor;

    uint128 public curve_lp_idx;

    address[] public dex;

    function _initialize(
        address _vault
    ) internal virtual;

    function _approveBasic() internal virtual;

    function _approveDex() internal virtual;

    function approveAll() external onlyAuthorized {
        _approveBasic();
        _approveDex();
    }

    function switchDex(uint256 _id, address _dex) external onlyAuthorized {
        dex[_id] = _dex;
        _approveDex();
    }

    function setSlippageFactor(uint256 new_factor) external onlyAuthorized {
        require (slippage_factor < MAX_SLIPPAGE_FACTOR, 'Bad slippage factor');

        slippage_factor = new_factor;
    }

    function setIsClaimRewards(bool _isClaimRewards) external onlyAuthorized {
        isClaimRewards = _isClaimRewards;
    }

    function setIsClaimExtras(bool _isClaimExtras) external onlyAuthorized {
        isClaimExtras = _isClaimExtras;
    }

    function withdrawToConvexDepositTokens() external onlyAuthorized {
        Rewards(rewardContract).withdrawAll(isClaimRewards);
    }

    function withdrawToWrappedTokens() external onlyAuthorized {
        Rewards(rewardContract).withdrawAllAndUnwrap(isClaimRewards);
    }

    function claimWantTokens() external onlyGovernance {
        want.safeTransfer(governance(), balanceOfWant());
    }

    function claimWrappedWantTokens() external onlyGovernance {
        want_wrapped.safeTransfer(governance(), balanceOfWrapped());
    }

    function claimRewardTokens() external onlyGovernance {
        IERC20(crv).safeTransfer(governance(), IERC20(crv).balanceOf(address(this)));
        IERC20(cvx).safeTransfer(governance(), IERC20(cvx).balanceOf(address(this)));
    }

    function name() external view override returns (string memory) {
        return string(abi.encodePacked("Convex", IERC20Metadata(address(want_wrapped)).symbol()));
    }

    function calc_want_from_wrapped(uint256 wrapped_amount) public view returns (uint256 expected_return) {
        if (wrapped_amount > 0) {
            expected_return = ICurveFi(curve).calc_withdraw_one_coin(wrapped_amount, int128(curve_lp_idx));
        }
    }

    function calc_wrapped_from_want(uint256 want_amount) public virtual view returns (uint256);

    function apply_slippage_factor(uint256 amount) public view returns (uint256) {
        return (amount * (slippage_factor + MAX_SLIPPAGE_FACTOR)) / MAX_SLIPPAGE_FACTOR;
    }

    function unwrap(uint256 wrapped_amount) internal virtual returns (uint256 expected_return) {
        if (wrapped_amount > 0) {
            expected_return = calc_want_from_wrapped(wrapped_amount);
            ICurveFi(curve).remove_liquidity_one_coin(wrapped_amount, int128(curve_lp_idx), 0);
        }
    }

    function wrap(uint256 want_amount) internal virtual returns (uint256 expected_return);

    function balanceOfWant() public view returns (uint256) {
        return want.balanceOf(address(this));
    }

    function balanceOfPool() public view returns (uint256) {
        return Rewards(rewardContract).balanceOf(address(this));
    }

    function balanceOfWrapped() public view returns (uint256) {
        return want_wrapped.balanceOf(address(this));
    }

    function estimatedTotalAssets() public view override returns (uint256) {
        uint256 total_wrapped = estimatedTotalWrappedAssets();
        return calc_want_from_wrapped(total_wrapped) + balanceOfWant();
    }

    function estimatedTotalWrappedAssets() public view returns (uint256) {
        return balanceOfWrapped() + balanceOfPool();
    }

    function adjustPosition(uint256 _debtOutstanding) internal override {
        // _debtOutstanding - unwrapped token
        if (emergencyExit) return;
        wrap(balanceOfWant());

        uint256 _wrapped = balanceOfWrapped();
        if (_wrapped > 0) {
            Booster(booster).deposit(id, _wrapped, true);
        }
    }

    // _amount - wrapped token amount
    function _withdrawSome(uint256 _amount) internal returns (uint256) {
        _amount = Math.min(_amount, balanceOfPool());
        uint _before = balanceOfWrapped();
        Rewards(rewardContract).withdrawAndUnwrap(_amount, false);
        return balanceOfWrapped() - _before;
    }

    // _amountNeeded - wrapped token amount must be provided
    // _liquidatedAmount and loss are in wrapped also
    function liquidatePosition(uint256 _amountNeeded)
    internal
    override
    returns (uint256 _liquidatedAmount, uint256 _loss)
    {
        uint256 _balance = balanceOfWrapped();
        if (_balance < _amountNeeded) {
            _liquidatedAmount = _withdrawSome(_amountNeeded - _balance);
            _liquidatedAmount += _balance;
            _loss = _amountNeeded - _liquidatedAmount; // this should be 0. o/w there must be an error
        }
        else {
            _liquidatedAmount = _amountNeeded;
        }
    }

    function prepareMigration(address _newStrategy) internal override {
        Rewards(rewardContract).withdrawAllAndUnwrap(isClaimRewards);
        _migrateRewards(_newStrategy);
        want_wrapped.safeTransfer(_newStrategy, balanceOfWrapped());
    }

    function _migrateRewards(address _newStrategy) internal virtual {
        IERC20(crv).safeTransfer(_newStrategy, IERC20(crv).balanceOf(address(this)));
        IERC20(cvx).safeTransfer(_newStrategy, IERC20(cvx).balanceOf(address(this)));
    }

    function _claimableBasicInETH() internal view returns (uint256) {
        uint256 _crv = Rewards(rewardContract).earned(address(this));

        // calculations pulled directly from CVX's contract for minting CVX per CRV claimed
        uint256 totalCliffs = 1000;
        uint256 maxSupply = 1e8 * 1e18; // 100m
        uint256 reductionPerCliff = 1e5 * 1e18; // 100k
        uint256 supply = IERC20(cvx).totalSupply();
        uint256 _cvx;

        uint256 cliff = supply / reductionPerCliff;
        // mint if below total cliffs
        if (cliff < totalCliffs) {
            // for reduction% take inverse of current cliff
            uint256 reduction = totalCliffs - cliff;
            // reduce
            _cvx = (_crv * reduction) / totalCliffs;

            // supply cap check
            uint256 amtTillMax = maxSupply - supply;
            if (_cvx > amtTillMax) {
                _cvx = amtTillMax;
            }
        }

        uint256 crvValue;
        if (_crv > 0) {
            address[] memory path = new address[](2);
            path[0] = crv;
            path[1] = weth;
            uint256[] memory crvSwap = Uni(dex[0]).getAmountsOut(_crv, path);
            crvValue = crvSwap[1];
        }

        uint256 cvxValue;
        if (_cvx > 0) {
            address[] memory path = new address[](2);
            path[0] = cvx;
            path[1] = weth;
            uint256[] memory cvxSwap = Uni(dex[1]).getAmountsOut(_cvx, path);
            cvxValue = cvxSwap[1];
        }

        return crvValue + cvxValue;
    }

    function _claimableInETH() internal virtual view returns (uint256 _claimable) {
        _claimable = _claimableBasicInETH();
    }

    // NOTE: Can override `tendTrigger` and `harvestTrigger` if necessary
    function harvestTrigger(uint256 callCost) public override view returns (bool) {
        IVault.StrategyParams memory params = vault.strategies(address(this));

        if (params.activation == 0) return false;

        if ((block.timestamp - params.lastReport) < minReportDelay) return false;

        if ((block.timestamp - params.lastReport) >= maxReportDelay) return true;

        uint256 outstanding = vault.debtOutstanding();
        if (outstanding > debtThreshold) return true;

        uint256 total = estimatedTotalAssets();
        if ((total + debtThreshold) < params.totalDebt) return true;

        return ((profitFactor * callCost) < _claimableInETH());
    }

    /**
     * @notice
     *  Harvests the Strategy, recognizing any profits or losses and adjusting
     *  the Strategy's position.
     *
     *  In the rare case the Strategy is in emergency shutdown, this will exit
     *  the Strategy's position.
     *
     *  This may only be called by governance, the strategist, or the keeper.
     * @dev
     *  When `harvest()` is called, the Strategy reports to the Vault (via
     *  `vault.report()`), so in some cases `harvest()` must be called in order
     *  to take in profits, to borrow newly available funds from the Vault, or
     *  otherwise adjust its position. In other cases `harvest()` must be
     *  called to report to the Vault on the Strategy's position, especially if
     *  any losses have occurred.
     */
    function harvest() external override onlyKeepers {
        uint256 profit = 0;
        uint256 loss = 0;
        uint256 debtOutstanding = calc_wrapped_from_want(vault.debtOutstanding());
        uint256 debtPayment = 0;

        if (emergencyExit) {
            // Free up as much capital as possible
            uint256 totalAssets = estimatedTotalWrappedAssets();
            // NOTE: use the larger of total assets or debt outstanding to book losses properly
            (debtPayment, loss) = liquidatePosition(totalAssets > debtOutstanding ? totalAssets : debtOutstanding);
            // NOTE: take up any remainder here as profit
            if (debtPayment > debtOutstanding) {
                profit = debtPayment - debtOutstanding;
                debtPayment = debtOutstanding;
            }
        } else {
            // Free up returns for Vault to pull
            (profit, loss, debtPayment) = prepareReturn(debtOutstanding);
        }

        // we should be able to give profit + debtPayment to vault
        uint256 want_profit = unwrap(profit);
        uint256 want_debtPayment = unwrap(debtPayment);
        uint256 want_loss = calc_want_from_wrapped(loss);

        // Allow Vault to take up to the "harvested" balance of this contract,
        // which is the amount it has earned since the last time it reported to
        // the Vault.
        debtOutstanding = vault.report(want_profit, want_loss, want_debtPayment);

        // Check if free returns are left, and re-invest them
        adjustPosition(debtOutstanding);

        emit Harvested(want_profit, want_loss, want_debtPayment, debtOutstanding);
    }

    /**
     * @notice
     *  Withdraws `_amountNeeded` to `vault`.
     * _amountNeeded provided in unwrapped tokens
     *
     *  This may only be called by the Vault.
     * @param _amountNeeded How much `want` to withdraw.
     * @return _loss Any realized losses
     */
    function withdraw(uint256 _amountNeeded) external override returns (uint256 _loss) {
        require(msg.sender == address(vault), "!vault");
        // Liquidate as much as possible to `want`, up to `_amountNeeded`
        uint _amountNeededWrapped;
        uint _amountNeededFirst = _amountNeeded;

        for (uint i = 0; i < 3; i++) {
            _amountNeeded = apply_slippage_factor(_amountNeeded);
            _amountNeededWrapped = calc_wrapped_from_want(_amountNeeded);
            uint _expectedUnwrapped = calc_want_from_wrapped(_amountNeededWrapped);
            if (_expectedUnwrapped >= _amountNeededFirst) {
                break;
            }
        }

        uint256 amountFreed;
        (amountFreed, _loss) = liquidatePosition(_amountNeededWrapped);
        // Send it directly back (NOTE: Using `msg.sender` saves some gas here)

        amountFreed = unwrap(amountFreed);
        _loss = calc_want_from_wrapped(_loss);

        if (amountFreed > _amountNeededFirst) {
            // excess want token will be used on next harvest
            amountFreed = _amountNeededFirst;
        }

        want.safeTransfer(msg.sender, amountFreed);
        // NOTE: Reinvest anything leftover on next `tend`/`harvest`
    }

    function protectedTokens()
    internal
    view
    override
    returns (address[] memory)
    {
        address[] memory protected = new address[](2);
        protected[0] = crv;
        protected[1] = cvx;
        return protected;
    }

    /**
     * @notice
     *  Removes tokens from this Strategy that are not the type of tokens
     *  managed by this Strategy. This may be used in case of accidentally
     *  sending the wrong kind of token to this Strategy.
     *
     *  Tokens will be sent to `governance()`.
     *
     *  This will fail if an attempt is made to sweep `want`, or any tokens
     *  that are protected by this Strategy.
     *
     *  This may only be called by governance.
     * @dev
     *  Implement `protectedTokens()` to specify any additional tokens that
     *  should be protected from sweeping in addition to `want`.
     * @param _token The token to transfer out of this vault.
     */
    function sweep(address _token) external override onlyGovernance {
        require(_token != address(want), "!want");
        require(_token != address(want_wrapped), "!want wrapped");

        address[] memory _protectedTokens = protectedTokens();
        for (uint256 i; i < _protectedTokens.length; i++) require(_token != _protectedTokens[i], "!protected");

        IERC20(_token).safeTransfer(governance(), IERC20(_token).balanceOf(address(this)));
    }
}
