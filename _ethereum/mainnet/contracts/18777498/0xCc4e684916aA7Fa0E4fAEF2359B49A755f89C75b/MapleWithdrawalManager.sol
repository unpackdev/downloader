// SPDX-License-Identifier: BUSL-1.1
pragma solidity 0.8.7;

import { ERC20Helper }           from "../modules/erc20-helper/src/ERC20Helper.sol";
import { IMapleProxyFactory }    from "../modules/maple-proxy-factory/contracts/interfaces/IMapleProxyFactory.sol";
import "./MapleProxiedInternals.sol";

import "./Interfaces.sol";

import "./IMapleWithdrawalManager.sol";

import "./MapleWithdrawalManagerStorage.sol";

/*

    ███╗   ███╗ █████╗ ██████╗ ██╗     ███████╗
    ████╗ ████║██╔══██╗██╔══██╗██║     ██╔════╝
    ██╔████╔██║███████║██████╔╝██║     █████╗
    ██║╚██╔╝██║██╔══██║██╔═══╝ ██║     ██╔══╝
    ██║ ╚═╝ ██║██║  ██║██║     ███████╗███████╗
    ╚═╝     ╚═╝╚═╝  ╚═╝╚═╝     ╚══════╝╚══════╝


    ██╗    ██╗██╗████████╗██╗  ██╗██████╗ ██████╗  █████╗ ██╗    ██╗ █████╗ ██╗
    ██║    ██║██║╚══██╔══╝██║  ██║██╔══██╗██╔══██╗██╔══██╗██║    ██║██╔══██╗██║
    ██║ █╗ ██║██║   ██║   ███████║██║  ██║██████╔╝███████║██║ █╗ ██║███████║██║
    ██║███╗██║██║   ██║   ██╔══██║██║  ██║██╔══██╗██╔══██║██║███╗██║██╔══██║██║
    ╚███╔███╔╝██║   ██║   ██║  ██║██████╔╝██║  ██║██║  ██║╚███╔███╔╝██║  ██║███████╗
    ╚══╝╚══╝ ╚═╝   ╚═╝   ╚═╝  ╚═╝╚═════╝ ╚═╝  ╚═╝╚═╝  ╚═╝ ╚══╝╚══╝ ╚═╝  ╚═╝╚══════╝


    ███╗   ███╗ █████╗ ███╗   ██╗ █████╗  ██████╗ ███████╗██████╗
    ████╗ ████║██╔══██╗████╗  ██║██╔══██╗██╔════╝ ██╔════╝██╔══██╗
    ██╔████╔██║███████║██╔██╗ ██║███████║██║  ███╗█████╗  ██████╔╝
    ██║╚██╔╝██║██╔══██║██║╚██╗██║██╔══██║██║   ██║██╔══╝  ██╔══██╗
    ██║ ╚═╝ ██║██║  ██║██║ ╚████║██║  ██║╚██████╔╝███████╗██║  ██║
    ╚═╝     ╚═╝╚═╝  ╚═╝╚═╝  ╚═══╝╚═╝  ╚═╝ ╚═════╝ ╚══════╝╚═╝  ╚═╝

    * `cycleDuration` is the time of a full withdrawal cycle.
    *
    * |--------|--------|
    *     C1       C2
    *
    * There is a withdrawal window at the beginning of each withdrawal cycle.
    *
    * |===-----|===-----|
    *  WW1      WW2
    *
    * Once a user locks their shares, they must wait at least one full cycle from the end of the cycle they locked their shares in.
    * Users are only able to withdraw during a withdrawal window, which starts at the beginning of each cycle.
    *
    * |===-.---|===-----|===-----|
    *      ^             ^
    *  shares locked    earliest withdrawal time
    *
    * When the pool delegate changes the configuration, it will take effect only on the start of the third cycle.
    * This way all users that have already locked their shares will not have their withdrawal time affected.
    *
    *     C1       C2       C3             C4
    * |===--.--|===-----|===-----|==========----------|
    *       ^                     ^
    * configuration change     new configuration kicks in
    *
    * Users that request a withdrawal during C1 will withdraw during WW3 using the old configuration.
    * Users that lock their shares during and after C2 will withdraw in windows that use the new configuration.

*/

contract MapleWithdrawalManager is IMapleWithdrawalManager, MapleWithdrawalManagerStorage, MapleProxiedInternals {

    // NOTE: The following functions already check for paused state in the pool, therefore no need to check here.
    // * addShares
    // * removeShares
    // * processExit
    modifier whenProtocolNotPaused() {
        require(!IGlobalsLike(globals()).protocolPaused(), "WM:PROTOCOL_PAUSED");
        _;
    }

    modifier onlyPoolDelegateOrProtocolAdmins {
        address globals_ = globals();

        require(
            msg.sender == IPoolManagerLike(poolManager).poolDelegate() ||
            msg.sender == IGlobalsLike(globals_).governor() ||
            msg.sender == IGlobalsLike(globals_).operationalAdmin(),
            "WM:NOT_PD_OR_GOV_OR_OA"
        );

        _;
    }

    /**************************************************************************************************************************************/
    /*** Proxy Functions                                                                                                                ***/
    /**************************************************************************************************************************************/

    function migrate(address migrator_, bytes calldata arguments_) external override {
        require(msg.sender == _factory(),        "WM:M:NOT_FACTORY");
        require(_migrate(migrator_, arguments_), "WM:M:FAILED");
    }

    function setImplementation(address implementation_) external override {
        require(msg.sender == _factory(), "WM:SI:NOT_FACTORY");
        _setImplementation(implementation_);
    }

    function upgrade(uint256 version_, bytes calldata arguments_) external override {
        address poolDelegate_ = poolDelegate();

        IGlobalsLike mapleGlobals_ = IGlobalsLike(globals());

        require(msg.sender == poolDelegate_ || msg.sender == mapleGlobals_.securityAdmin(), "WM:U:NOT_AUTHORIZED");

        if (msg.sender == poolDelegate_) {
            require(mapleGlobals_.isValidScheduledCall(msg.sender, address(this), "WM:UPGRADE", msg.data), "WM:U:INVALID_SCHED_CALL");

            mapleGlobals_.unscheduleCall(msg.sender, "WM:UPGRADE", msg.data);
        }

        IMapleProxyFactory(_factory()).upgradeInstance(version_, arguments_);
    }

    /**************************************************************************************************************************************/
    /*** Administrative Functions                                                                                                       ***/
    /**************************************************************************************************************************************/

    function setExitConfig(
        uint256 cycleDuration_,
        uint256 windowDuration_
    )
        external override whenProtocolNotPaused onlyPoolDelegateOrProtocolAdmins
    {
        require(windowDuration_ != 0,              "WM:SEC:ZERO_WINDOW");
        require(windowDuration_ <= cycleDuration_, "WM:SEC:WINDOW_OOB");

        // The new config will take effect only after the current cycle and two additional ones elapse.
        // This is done in order to to prevent overlaps between the current and new withdrawal cycles.
        uint256 currentCycleId_   = getCurrentCycleId();
        uint256 initialCycleId_   = currentCycleId_ + 3;
        uint256 initialCycleTime_ = getWindowStart(currentCycleId_);
        uint256 latestConfigId_   = latestConfigId;

        // This isn't the most optimal way to do this, since the internal function `getConfigAt` iterates through configs.
        // But this function should only be called by the pool delegate and not often, and, at most, we need to iterate through 3 cycles.
        for (uint256 i = currentCycleId_; i < initialCycleId_; i++) {
            CycleConfig memory config = getConfigAtId(i);

            initialCycleTime_ += config.cycleDuration;
        }

        // If the new config takes effect on the same cycle as the latest config, overwrite it. Otherwise create a new config.
        if (initialCycleId_ != cycleConfigs[latestConfigId_].initialCycleId) {
            latestConfigId_ = ++latestConfigId;
        }

        cycleConfigs[latestConfigId_] = CycleConfig({
            initialCycleId:   _uint64(initialCycleId_),
            initialCycleTime: _uint64(initialCycleTime_),
            cycleDuration:    _uint64(cycleDuration_),
            windowDuration:   _uint64(windowDuration_)
        });

        emit ConfigurationUpdated({
            configId_:         latestConfigId_,
            initialCycleId_:   _uint64(initialCycleId_),
            initialCycleTime_: _uint64(initialCycleTime_),
            cycleDuration_:    _uint64(cycleDuration_),
            windowDuration_:   _uint64(windowDuration_)
        });
    }

    /**************************************************************************************************************************************/
    /*** Exit Functions                                                                                                                 ***/
    /**************************************************************************************************************************************/

    function addShares(uint256 shares_, address owner_) external override {
        require(msg.sender == poolManager, "WM:AS:NOT_POOL_MANAGER");

        uint256 exitCycleId_  = exitCycleId[owner_];
        uint256 lockedShares_ = lockedShares[owner_];

        require(lockedShares_ == 0 || block.timestamp >= getWindowStart(exitCycleId_), "WM:AS:WITHDRAWAL_PENDING");

        // Remove all existing shares from the current cycle.
        totalCycleShares[exitCycleId_] -= lockedShares_;

        lockedShares_ += shares_;

        require(lockedShares_ != 0, "WM:AS:NO_OP");

        // Move all shares (including any new ones) to the new cycle.
        exitCycleId_ = getCurrentCycleId() + 2;
        totalCycleShares[exitCycleId_] += lockedShares_;

        exitCycleId[owner_]  = exitCycleId_;
        lockedShares[owner_] = lockedShares_;

        require(ERC20Helper.transferFrom(pool, msg.sender, address(this), shares_), "WM:AS:TRANSFER_FROM_FAIL");

        _emitUpdate(owner_, lockedShares_, exitCycleId_);
    }

    function removeShares(uint256 shares_, address owner_) external override returns (uint256 sharesReturned_) {
        require(msg.sender == poolManager, "WM:RS:NOT_POOL_MANAGER");

        uint256 exitCycleId_  = exitCycleId[owner_];
        uint256 lockedShares_ = lockedShares[owner_];

        require(block.timestamp >= getWindowStart(exitCycleId_), "WM:RS:WITHDRAWAL_PENDING");
        require(shares_ != 0 && shares_ <= lockedShares_,        "WM:RS:SHARES_OOB");

        // Remove shares from old the cycle.
        totalCycleShares[exitCycleId_] -= lockedShares_;

        // Calculate remaining shares and new cycle (if applicable).
        lockedShares_ -= shares_;
        exitCycleId_   = lockedShares_ != 0 ? getCurrentCycleId() + 2 : 0;

        // Add shares to new cycle (if applicable).
        if (lockedShares_ != 0) {
            totalCycleShares[exitCycleId_] += lockedShares_;
        }

        // Update the withdrawal request.
        exitCycleId[owner_]  = exitCycleId_;
        lockedShares[owner_] = lockedShares_;

        sharesReturned_ = shares_;

        require(ERC20Helper.transfer(pool, owner_, shares_), "WM:RS:TRANSFER_FAIL");

        _emitUpdate(owner_, lockedShares_, exitCycleId_);
    }

    function processExit(uint256 requestedShares_, address owner_)
        external override returns (uint256 redeemableShares_, uint256 resultingAssets_)
    {
        require(msg.sender == poolManager, "WM:PE:NOT_PM");

        uint256 exitCycleId_  = exitCycleId[owner_];
        uint256 lockedShares_ = lockedShares[owner_];

        require(lockedShares_ != 0, "WM:PE:NO_REQUEST");

        require(requestedShares_ == lockedShares_, "WM:PE:INVALID_SHARES");

        bool partialLiquidity_;

        ( uint256 windowStart_, uint256 windowEnd_ ) = getWindowAtId(exitCycleId_);

        require(block.timestamp >= windowStart_ && block.timestamp <  windowEnd_, "WM:PE:NOT_IN_WINDOW");

        ( redeemableShares_, resultingAssets_, partialLiquidity_ ) = getRedeemableAmounts(lockedShares_, owner_);

        // Transfer redeemable shares to be burned in the pool, re-lock remaining shares.
        require(ERC20Helper.transfer(pool, owner_, redeemableShares_), "WM:PE:TRANSFER_FAIL");

        // Reduce totalCurrentShares by the shares that were used in the old cycle.
        totalCycleShares[exitCycleId_] -= lockedShares_;

        // Reduce the locked shares by the total amount transferred back to the LP.
        lockedShares_ -= redeemableShares_;

        // If there are any remaining shares, move them to the next cycle.
        // In case of partial liquidity move shares only one cycle forward (instead of two).
        if (lockedShares_ != 0) {
            exitCycleId_ = getCurrentCycleId() + (partialLiquidity_ ? 1 : 2);
            totalCycleShares[exitCycleId_] += lockedShares_;
        } else {
            exitCycleId_ = 0;
        }

        // Update the locked shares and cycle for the account, setting to zero if no shares are remaining.
        lockedShares[owner_] = lockedShares_;
        exitCycleId[owner_]  = exitCycleId_;

        _emitProcess(owner_, redeemableShares_, resultingAssets_);
        _emitUpdate(owner_, lockedShares_, exitCycleId_);
    }

    /**************************************************************************************************************************************/
    /*** External View Utility Functions                                                                                                ***/
    /**************************************************************************************************************************************/

    function isInExitWindow(address owner_) external view override returns (bool isInExitWindow_) {
        uint256 exitCycleId_ = exitCycleId[owner_];

        if (exitCycleId_ == 0) return false; // No withdrawal request

        ( uint256 windowStart_, uint256 windowEnd_ ) = getWindowAtId(exitCycleId_);

        isInExitWindow_ = block.timestamp >= windowStart_ && block.timestamp <  windowEnd_;
    }

    function lockedLiquidity() external view override returns (uint256 lockedLiquidity_) {
        uint256 currentCycleId_ = getCurrentCycleId();

        ( uint256 windowStart_, uint256 windowEnd_ ) = getWindowAtId(currentCycleId_);

        if (block.timestamp >= windowStart_ && block.timestamp < windowEnd_) {
            IPoolManagerLike poolManager_ = IPoolManagerLike(poolManager);

            uint256 totalAssetsWithLosses_ = poolManager_.totalAssets() - poolManager_.unrealizedLosses();
            uint256 totalSupply_           = IPoolLike(pool).totalSupply();

            lockedLiquidity_ = totalCycleShares[currentCycleId_] * totalAssetsWithLosses_ / totalSupply_;
        }
    }

    function previewRedeem(address owner_, uint256 shares_)
        external view override returns (uint256 redeemableShares_, uint256 resultingAssets_)
    {
        uint256 lockedShares_ = lockedShares[owner_];

        if (shares_ != lockedShares_ || shares_ == 0) {
            return ( redeemableShares_, resultingAssets_ );
        }

        uint256 exitCycleId_  = exitCycleId[owner_];

        ( uint256 windowStart_, uint256 windowEnd_ ) = getWindowAtId(exitCycleId_);

        if (block.timestamp < windowStart_ || block.timestamp >=  windowEnd_) {
            return ( redeemableShares_, resultingAssets_ );
        }

        ( redeemableShares_, resultingAssets_, ) = getRedeemableAmounts(lockedShares_, owner_);
    }

    /**************************************************************************************************************************************/
    /*** Public View Utility Functions                                                                                                  ***/
    /**************************************************************************************************************************************/

    function getConfigAtId(uint256 cycleId_) public view override returns (CycleConfig memory config_) {
        uint256 configId_ = latestConfigId;

        if (configId_ == 0) return cycleConfigs[configId_];

        while (cycleId_ < cycleConfigs[configId_].initialCycleId) {
            --configId_;
        }

        config_ = cycleConfigs[configId_];
    }

    function getCurrentConfig() public view override returns (CycleConfig memory config_) {
        uint256 configId_ = latestConfigId;

        while (configId_ != 0 && block.timestamp < cycleConfigs[configId_].initialCycleTime) {
            --configId_;
        }

        config_ = cycleConfigs[configId_];
    }

    // NOTE: If the first cycle has not been reached yet it will still be returned as the current one.
    function getCurrentCycleId() public view override returns (uint256 cycleId_) {
        CycleConfig memory config_ = getCurrentConfig();

        cycleId_ = config_.initialCycleId;

        if (block.timestamp > config_.initialCycleTime) {
            cycleId_ += (block.timestamp - config_.initialCycleTime) / config_.cycleDuration;
        }
    }

    function getRedeemableAmounts(uint256 lockedShares_, address owner_)
        public view override returns (uint256 redeemableShares_, uint256 resultingAssets_, bool partialLiquidity_)
    {
        IPoolManagerLike poolManager_ = IPoolManagerLike(poolManager);

        // Calculate how much liquidity is available, and how much is required to allow redemption of shares.
        uint256 availableLiquidity_      = IERC20Like(asset()).balanceOf(pool);
        uint256 totalAssetsWithLosses_   = poolManager_.totalAssets() - poolManager_.unrealizedLosses();
        uint256 totalSupply_             = IPoolLike(pool).totalSupply();
        uint256 totalRequestedLiquidity_ = totalCycleShares[exitCycleId[owner_]] * totalAssetsWithLosses_ / totalSupply_;

        partialLiquidity_ = availableLiquidity_ < totalRequestedLiquidity_;

        // Calculate maximum redeemable shares while maintaining a pro-rata distribution.
        redeemableShares_ =
            partialLiquidity_
                ? lockedShares_ * availableLiquidity_ / totalRequestedLiquidity_
                : lockedShares_;

        resultingAssets_ = redeemableShares_ * totalAssetsWithLosses_ / totalSupply_;
    }

    function getWindowStart(uint256 cycleId_) public view override returns (uint256 windowStart_) {
        CycleConfig memory config_ = getConfigAtId(cycleId_);

        windowStart_ = config_.initialCycleTime + (cycleId_ - config_.initialCycleId) * config_.cycleDuration;
    }

    function getWindowAtId(uint256 cycleId_) public view override returns (uint256 windowStart_, uint256 windowEnd_) {
        CycleConfig memory config_ = getConfigAtId(cycleId_);

        windowStart_ = config_.initialCycleTime + (cycleId_ - config_.initialCycleId) * config_.cycleDuration;
        windowEnd_   = windowStart_ + config_.windowDuration;
    }

    /**************************************************************************************************************************************/
    /*** Address View Functions                                                                                                         ***/
    /**************************************************************************************************************************************/

    function asset() public view override returns (address asset_) {
        asset_ = IPoolLike(pool).asset();
    }

    function factory() external view override returns (address factory_) {
        factory_ = _factory();
    }

    function globals() public view override returns (address globals_) {
        globals_ = IMapleProxyFactory(_factory()).mapleGlobals();
    }

    function governor() public view override returns (address governor_) {
        governor_ = IGlobalsLike(globals()).governor();
    }

    function implementation() external view override returns (address implementation_) {
        implementation_ = _implementation();
    }

    function poolDelegate() public view override returns (address poolDelegate_) {
        poolDelegate_ = IPoolManagerLike(poolManager).poolDelegate();
    }

    function previewWithdraw(address owner_, uint256 assets_)
        external pure override returns (uint256 redeemableAssets_, uint256 resultingShares_)
    {
        owner_; assets_; redeemableAssets_; resultingShares_;  // Silence compiler warnings
        return ( redeemableAssets_, resultingShares_ );  // NOTE: Withdrawal not implemented use redeem instead
    }

    /**************************************************************************************************************************************/
    /*** Helper Functions                                                                                                               ***/
    /**************************************************************************************************************************************/

    function _emitProcess(address account_, uint256 sharesToRedeem_, uint256 assetsToWithdraw_) internal {
        if (sharesToRedeem_ == 0) {
            return;
        }

        emit WithdrawalProcessed(account_, sharesToRedeem_, assetsToWithdraw_);
    }

    function _emitUpdate(address account_, uint256 lockedShares_, uint256 exitCycleId_) internal {
        if (lockedShares_ == 0) {
            emit WithdrawalCancelled(account_);
            return;
        }

        ( uint256 windowStart_, uint256 windowEnd_ ) = getWindowAtId(exitCycleId_);

        emit WithdrawalUpdated(account_, lockedShares_, _uint64(windowStart_), _uint64(windowEnd_));
    }

    function _uint64(uint256 input_) internal pure returns (uint64 output_) {
        require(input_ <= type(uint64).max, "WM:UINT64_CAST_OOB");
        output_ = uint64(input_);
    }

}
