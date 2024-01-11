// SPDX-License-Identifier: AGPL-3.0

pragma solidity 0.6.12;
pragma experimental ABIEncoderV2;

import { BaseStrategyInitializable } from "BaseStrategy.sol";
import "IERC20.sol";
import "SafeMath.sol";
import "SafeERC20.sol";

import "IIdleTokenV4.sol";
import "ITradeFactory.sol";
import "IUniswapRouter.sol";

contract StrategyIdle is BaseStrategyInitializable {
    using SafeERC20 for IERC20;
    using SafeERC20 for IIdleTokenV4;
    using SafeMath for uint256;

    uint256 private constant DEPOSIT_THRESHOLD = 10;

    /// @dev `idleYieldToken` have fixed 18 decimals regardless of the underlying
    uint256 private constant EXP_SCALE = 1e18;

    address private constant WETH = 0xC02aaA39b223FE8D0A0e5C4F27eAD9083C756Cc2;

    address private constant REFERRAL = 0xFb3bD022D5DAcF95eE28a6B07825D4Ff9C5b3814; // Idle finance Treasury League multisig

    address public router;

    address public tradeFactory;

    address public idleYieldToken;

    IERC20[] internal rewardTokens;

    /**
     * @notice
     *  Initializes the Strategy or defer initialization when using a proxy
     * @dev `_initialize` choose to init at deploy or later (proxy)
     *      Set false to prevent initialization
     */
    constructor(
        address _vault,
        IERC20[] memory _rewardTokens,
        address _idleYieldToken,
        address _router,
        address _healthCheck,
        bool _initialize
    ) public BaseStrategyInitializable(_vault) {
        if (_initialize) {
            _init(_rewardTokens, _idleYieldToken, _router, _healthCheck);
        }
    }

    // ************************* Init methods *************************

    /**
     * @notice Initializes the Strategy when using a proxy
     */
    function init(
        address _vault,
        address _onBehalfOf,
        IERC20[] memory _rewardTokens,
        address _idleYieldToken,
        address _router,
        address _healthCheck
    ) external {
        // address _vault, address _strategist, address _rewards ,address _keeper
        super._initialize(_vault, _onBehalfOf, _onBehalfOf, _onBehalfOf);

        _init(_rewardTokens, _idleYieldToken, _router, _healthCheck);
    }

    function _init(
        IERC20[] memory _rewardTokens,
        address _idleYieldToken,
        address _router,
        address _healthCheck
    ) internal {
        require(address(want) == IIdleTokenV4(_idleYieldToken).token(), "strat/want-ne-underlying");

        // can be empaty array
        rewardTokens = _rewardTokens; // set `tradeFactory` address after deployment.
        idleYieldToken = _idleYieldToken;
        router = _router;
        healthCheck = _healthCheck;

        // idleYieldToken is expected to have fixed 18 decimals regardless of the underlying
        // `EXP_SCALE` is fixed
        require(IIdleTokenV4(_idleYieldToken).decimals() == 18, "strat/decimals-18");

        want.safeApprove(_idleYieldToken, type(uint256).max);
    }

    // ************************* Permissioned methods *************************

    /// @notice set reward tokens
    function setRewardTokens(IERC20[] memory _rewardTokens) external onlyVaultManagers {
        bool useTradeFactory = tradeFactory != address(0);

        if (useTradeFactory) {
            _revokeTradeFactory();
        }

        rewardTokens = _rewardTokens; // set new rewardTokens

        if (useTradeFactory) {
            _approveTradeFactory();
        }
    }

    /// @dev this strategy must be granted STRATEGY role if `_newTradeFactory` is non-zero address NOTE: https://github.com/yearn/yswaps/blob/7410951c9514dfa2abdcf82477cb4f92e1da7dd5/solidity/contracts/TradeFactory/TradeFactoryPositionsHandler.sol#L80
    ///      to revoke tradeFactory pass address(0) as the parameter
    function updateTradeFactory(address _newTradeFactory) public onlyGovernance {
        if (tradeFactory != address(0)) {
            _revokeTradeFactory();
        }

        tradeFactory = _newTradeFactory;

        if (_newTradeFactory != address(0)) {
            _approveTradeFactory();
        }
    }

    /// @notice setup tradeFactory
    /// @dev assume tradeFactory is not zero address
    ///      this strategy must be granted STRATEGY role by `tradeFactory`
    function _approveTradeFactory() internal {
        IERC20[] memory _rewardTokens = rewardTokens;
        address _want = address(want);
        ITradeFactory tf = ITradeFactory(tradeFactory);

        uint256 length = _rewardTokens.length;
        IERC20 rewardToken;
        for (uint256 i; i < length; i++) {
            rewardToken = _rewardTokens[i];
            rewardToken.safeApprove(address(tf), type(uint256).max);
            // this strategy must be granted STRATEGY role : https://github.com/yearn/yswaps/blob/7410951c9514dfa2abdcf82477cb4f92e1da7dd5/solidity/contracts/TradeFactory/TradeFactoryPositionsHandler.sol#L80
            tf.enable(address(rewardToken), _want);
        }
    }

    /// @notice remove tradeFactory
    /// @dev assume tradeFactory is not zero address
    function _revokeTradeFactory() internal {
        address _tradeFactory = tradeFactory;
        IERC20[] memory _rewardTokens = rewardTokens;
        uint256 length = _rewardTokens.length;

        for (uint256 i; i < length; i++) {
            _rewardTokens[i].safeApprove(_tradeFactory, 0);
        }
    }

    // ************************* View methods *************************

    /// @notice return staked idleTokens + idleToken balance that this contract holds
    function totalIdleTokens() public view returns (uint256) {
        return _balance(IERC20(idleYieldToken));
    }

    function getRewardTokens() external view returns (IERC20[] memory) {
        return rewardTokens;
    }

    // ************************* Overrode methods *************************
    // ************************* Overrode public View methods *************************

    function name() external view override returns (string memory) {
        return string(abi.encodePacked("StrategyIdleV2 ", IIdleTokenV4(idleYieldToken).name()));
    }

    /**
     * @return totalAssets : the value of all positions in terms of `want`
     */
    function estimatedTotalAssets() public view override returns (uint256 totalAssets) {
        IIdleTokenV4 _idleToken = IIdleTokenV4(idleYieldToken);

        totalAssets = _balance(want);
        uint256 idleTokenBal = totalIdleTokens();

        if (idleTokenBal != 0) {
            uint256 price = _idleToken.tokenPriceWithFee(address(this));
            totalAssets = totalAssets.add(idleTokenBal.mul(price).div(EXP_SCALE));
        }
    }

    function ethToWant(uint256 _amount) public view override returns (uint256) {
        if (_amount == 0) {
            return 0;
        }
        address _wantAddress = address(want);
        if (_wantAddress == WETH) {
            return _amount;
        }
        address[] memory path = _getPath(WETH, _wantAddress);
        uint256[] memory amounts = IUniswapRouter(router).getAmountsOut(_amount, path);
        return amounts[amounts.length - 1];
    }

    // ************************* Overrode Internal View methods *************************

    // Override this to add all tokens/tokenized positions this contract manages
    // on a *persistent* basis (e.g. not just for swapping back to want ephemerally)
    // NOTE: Do *not* include `want`, already included in `sweep` below
    //
    // Example:
    //
    //    function protectedTokens() internal override view returns (address[] memory) {
    //      address[] memory protected = new address[](3);
    //      protected[0] = tokenA;
    //      protected[1] = tokenB;
    //      protected[2] = tokenC;
    //      return protected;
    //    }
    function protectedTokens() internal view override returns (address[] memory) {
        IERC20[] memory _rewardTokens = rewardTokens;
        uint256 length = _rewardTokens.length;
        address[] memory protected = new address[](1 + length);

        for (uint256 i; i < length; i++) {
            protected[i] = address(_rewardTokens[i]);
        }
        protected[length] = idleYieldToken;

        return protected;
    }

    // ************************* Overrode Internal Mutative methods *************************

    /*
     * Perform any strategy unwinding or other calls necessary to capture the "free return"
     * this strategy has generated since the last time it's core position(s) were adjusted.
     * Examples include unwrapping extra rewards. This call is only used during "normal operation"
     * of a Strategy, and should be optimized to minimize losses as much as possible. This method
     * returns any realized profits and/or realized losses incurred, and should return the total
     * amounts of profits/losses/debt payments (in `want` tokens) for the Vault's accounting
     * (e.g. `want.balanceOf(this) >= _debtPayment + _profit - _loss`).
     *
     * NOTE: `_debtPayment` should be less than or equal to `_debtOutstanding`. It is okay for it
     *       to be less than `_debtOutstanding`, as that should only used as a guide for how much
     *       is left to pay back. Payments should be made to minimize loss from slippage, debt,
     *       withdrawal fees, etc.
     */
    function prepareReturn(uint256 _debtOutstanding)
        internal
        override
        returns (
            uint256 _profit,
            uint256 _loss,
            uint256 _debtPayment
        )
    {
        // Get total debt, total assets (want+idle)
        uint256 totalDebt = vault.strategies(address(this)).totalDebt;
        uint256 totalAssets = estimatedTotalAssets();

        _profit = totalAssets > totalDebt ? totalAssets - totalDebt : 0; // no underflow

        // To withdraw = profit from lending + _debtOutstanding
        uint256 toFree = _debtOutstanding.add(_profit);

        uint256 freed;
        // In the case want is not enough, divest from idle
        (freed, _loss) = liquidatePosition(toFree);

        _debtPayment = _debtOutstanding >= freed ? freed : _debtOutstanding; // min

        // net out PnL
        if (_profit > _loss) {
            _profit = _profit - _loss; // no underflow
            _loss = 0;
        } else {
            _loss = _loss - _profit; // no underflow
            _profit = 0;
        }
    }

    /*
     * Perform any adjustments to the core position(s) of this strategy given
     * what change the Vault made in the "investable capital" available to the
     * strategy. Note that all "free capital" in the strategy after the report
     * was made is available for reinvestment. Also note that this number could
     * be 0, and you should handle that scenario accordingly.
     */
    function adjustPosition(uint256 _debtOutstanding) internal override {
        // NOTE: Try to adjust positions so that `_debtOutstanding` can be freed up on *next* harvest (not immediately)

        uint256 wantBal = _balance(want);
        if (wantBal > _debtOutstanding) {
            _invest(wantBal - _debtOutstanding); // no underflow
        }
    }

    /**
     * Liquidate up to `_amountNeeded` of `want` of this strategy's positions,
     * irregardless of slippage. Any excess will be re-invested with `adjustPosition()`.
     * This function should return the amount of `want` tokens made available by the
     * liquidation. If there is a difference between them, `_loss` indicates whether the
     * difference is due to a realized loss, or if there is some other sitution at play
     * (e.g. locked funds) where the amount made available is less than what is needed.
     *
     * NOTE: The invariant `_liquidatedAmount + _loss <= _amountNeeded` should always be maintained
     */
    function liquidatePosition(uint256 _amountNeeded)
        internal
        override
        returns (uint256 _liquidatedAmount, uint256 _loss)
    {
        // TODO: Do stuff here to free up to `_amountNeeded` from all positions back into `want`
        // NOTE: Maintain invariant `want.balanceOf(this) >= _liquidatedAmount`
        // NOTE: Maintain invariant `_liquidatedAmount + _loss <= _amountNeeded`

        uint256 wantBal = _balance(want);

        if (_amountNeeded > wantBal) {
            uint256 toWithdraw = _amountNeeded - wantBal; // no underflow
            uint256 withdrawn = _divest(_wantsInIdleToken(IIdleTokenV4(idleYieldToken), toWithdraw));
            if (withdrawn < toWithdraw) {
                _loss = toWithdraw - withdrawn; // no underflow
            }
        }

        _liquidatedAmount = _amountNeeded.sub(_loss);
    }

    function prepareMigration(address _newStrategy) internal override {
        // TODO: Transfer any non-`want` tokens to the new strategy
        // NOTE: `migrate` will automatically forward all `want` in this strategy to the new one

        IIdleTokenV4 _idleYieldToken = IIdleTokenV4(idleYieldToken);

        uint256 idleTokenBal = _balance(_idleYieldToken);
        if (idleTokenBal != 0) {
            _idleYieldToken.safeTransfer(_newStrategy, idleTokenBal);
        }
    }

    /**
     * Liquidate everything and returns the amount that got freed.
     * This function is used during emergency exit instead of `prepareReturn()` to
     * liquidate all of the Strategy's positions back to the Vault.
     */
    function liquidateAllPositions() internal override returns (uint256 amountFreed) {
        _divest(totalIdleTokens());
        amountFreed = _balance(want);
    }

    // ************************* External Invest/Divest methods *************************

    function invest(uint256 _wantAmount) external onlyVaultManagers {
        _invest(_wantAmount);
    }

    function divest(uint256 _tokensToWithdraw) external onlyVaultManagers {
        _divest(_tokensToWithdraw);
    }

    function claimRewards() external onlyVaultManagers {
        _claimRewards();
    }

    // ************************* Mutative Helper methods *************************

    /// @notice deposit `want` to Idle
    /// @param _wantAmount amount of `want` to deposit
    function _invest(uint256 _wantAmount) internal returns (uint256 tokensMinted) {
        // check threshold
        if (_wantAmount <= DEPOSIT_THRESHOLD) {
            return 0;
        }

        IIdleTokenV4 _idleToken = IIdleTokenV4(idleYieldToken);
        uint256 before = _balance(_idleToken);

        _idleToken.mintIdleToken(_wantAmount, true, REFERRAL);

        tokensMinted = _balance(_idleToken).sub(before);
    }

    /// @notice withdraw `want` to Idle
    /// @param _tokensToWithdraw amount of `idleYieldToken` to withdraw
    function _divest(uint256 _tokensToWithdraw) internal returns (uint256 wantRedeemed) {
        IERC20 _want = want;
        IIdleTokenV4 _idleYieldToken = IIdleTokenV4(idleYieldToken);

        uint256 before = _balance(_want);
        uint256 idleTokenBal = _balance(_idleYieldToken);

        // fix rounding error
        if (_tokensToWithdraw > idleTokenBal) {
            _tokensToWithdraw = idleTokenBal;
        }

        IIdleTokenV4(_idleYieldToken).redeemIdleToken(_tokensToWithdraw);

        wantRedeemed = _balance(_want).sub(before);
    }

    /// @notice claim rewards
    function _claimRewards() internal {
        IIdleTokenV4(idleYieldToken).redeemIdleToken(0);
    }

    // ************************* View Helper methods *************************

    /// @dev convert `wantAmount` denominated in `idleYieldToken`
    function _wantsInIdleToken(IIdleTokenV4 _idleYieldToken, uint256 wantAmount) internal view returns (uint256) {
        if (wantAmount == 0) return 0;
        return wantAmount.mul(EXP_SCALE).div(_idleYieldToken.tokenPriceWithFee(address(this)));
    }

    function _getPath(address assetIn, address assetOut) internal view returns (address[] memory path) {
        if (assetIn == WETH || assetOut == WETH) {
            path = new address[](2);
            path[0] = assetIn;
            path[1] = assetOut;
        } else {
            path = new address[](3);
            path[0] = assetIn;
            path[1] = WETH;
            path[2] = assetOut;
        }
    }

    function _balance(IERC20 token) internal view returns (uint256) {
        return token.balanceOf(address(this));
    }
}
