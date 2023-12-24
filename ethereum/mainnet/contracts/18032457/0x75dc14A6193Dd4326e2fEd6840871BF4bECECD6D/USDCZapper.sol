// SPDX-License-Identifier: CC BY-NC-ND 4.0
pragma solidity ^0.8.19;

import "./IZapper.sol";
import "./ICurvePool.sol";
import "./MultiPoolStrategy.sol";
import "./console2.sol";
import "./ReentrancyGuard.sol";
import "./Ownable.sol";
import "./SafeERC20.sol";
import "./IERC20.sol";
import "./EnumerableSet.sol";

contract USDCZapper is ReentrancyGuard, Ownable, IZapper {
    // Library for working with the _supportedAssets AddressSet.
    // Elements are added, removed, and checked for existence in constant time (O(1)).
    using EnumerableSet for EnumerableSet.AddressSet;

    // Struct containing information about a supported asset. In our case we use pools that have an index type of int128
    // pool - The address of the pool where the asset is traded.
    // index - The index of the asset within the pool.
    // isLpToken Indicates whether the asset is an LP token.
    struct AssetInfo {
        address pool;
        int128 index;
        bool isLpToken;
    }

    address public constant UNDERLYING_ASSET = 0xA0b86991c6218b36c1d19D4a2e9Eb0cE3606eB48; // USDC
    address public constant USDT = 0xdAC17F958D2ee523a2206206994597C13D831ec7; // USDT
    address public constant DAI = 0x6B175474E89094C44Da98b954EedeAC495271d0F; // DAI
    address public constant FRAX = 0x853d955aCEf822Db058eb8505911ED77F175b99e; // FRAX

    address public constant CRV = 0x6c3F90f043a72FA612cbac8115EE7e52BDe6E490; // CRV
    address public constant CRVFRAX = 0x3175Df0976dFA876431C2E9eE6Bc45b65d3473CC; // CRVFRAX

    address public constant CURVE_3POOL = 0xbEbc44782C7dB0a1A60Cb6fe97d0b483032FF1C7; // DAI+USDC+USDT
    address public constant CURVE_FRAXUSDC = 0xDcEF968d416a41Cdac0ED8702fAC8128A64241A2; // FRAX+USDC

    uint256 public constant CURVE_3POOL_TOKENS_COUNT = 3;
    uint256 public constant CURVE_FRAXUSDC_TOKENS_COUNT = 2;

    int128 public constant UNDERLYING_ASSET_INDEX = 1; // USDC Index - for both 3Pool and FRAXUSDC
    int128 public constant DAI_INDEX = 0; // DAI Index - for 3Pool
    int128 public constant USDT_INDEX = 2; // USDT Index - for 3Pool
    int128 public constant FRAX_INDEX = 0; // FRAX Index - for FRAXUSDC

    // Collection of unique addresses representing supported assets
    EnumerableSet.AddressSet private _supportedAssets;
    mapping(address => AssetInfo) private _supportedAssetsInfo;

    constructor() {
        // add stablecoins
        _supportedAssets.add(USDT);
        _supportedAssets.add(DAI);
        _supportedAssets.add(FRAX);
        // add lp tokens
        _supportedAssets.add(CRV);
        _supportedAssets.add(CRVFRAX);

        _supportedAssetsInfo[USDT] = AssetInfo({pool: CURVE_3POOL, index: USDT_INDEX, isLpToken: false});
        _supportedAssetsInfo[DAI] = AssetInfo({pool: CURVE_3POOL, index: DAI_INDEX, isLpToken: false});
        _supportedAssetsInfo[FRAX] = AssetInfo({pool: CURVE_FRAXUSDC, index: FRAX_INDEX, isLpToken: false});
        // for lp tokens indexes are set as index for UNDERLYING_TOKEN (usdc), as after removing liquidity we want to get usdc
        _supportedAssetsInfo[CRV] = AssetInfo({pool: CURVE_3POOL, index: UNDERLYING_ASSET_INDEX, isLpToken: true});
        _supportedAssetsInfo[CRVFRAX] =
            AssetInfo({pool: CURVE_FRAXUSDC, index: UNDERLYING_ASSET_INDEX, isLpToken: true});
    }

    /**
     * @inheritdoc IZapper
     */
    function deposit(
        uint256 amount,
        address token,
        uint256 minAmount,
        address receiver,
        address strategyAddress
    )
        external
        override
        nonReentrant
        returns (uint256 shares)
    {
        // check if the reciever is not zero address
        if (receiver == address(0)) revert ZeroAddress();
        // check if the amount is not zero
        if (amount == 0) revert EmptyInput();
        // check if the correct strategy provided and it matches underlying asset
        if (!strategyUsesUnderlyingAsset(strategyAddress)) revert StrategyAssetDoesNotMatchUnderlyingAsset();

        // check if the strategy is not paused
        IMultiPoolStrategy multiPoolStrategy = IMultiPoolStrategy(strategyAddress);
        if (multiPoolStrategy.paused()) revert StrategyPaused();

        // check if the provided token is in the assets array, if false - revert
        if (!_supportedAssets.contains(token)) revert InvalidAsset();

        // find the pool regarding the provided token, if pool not found - revert
        AssetInfo storage assetInfo = _supportedAssetsInfo[token];
        if (assetInfo.pool == address(0)) revert PoolDoesNotExist();

        // transfer tokens to this contract
        SafeERC20.safeTransferFrom(IERC20(token), msg.sender, address(this), amount);
        // approve pool to spend tokens
        SafeERC20.safeIncreaseAllowance(IERC20(token), assetInfo.pool, amount);

        // make swap, approval must be given before calling this function
        // minAmount is checked inside pool so not necessary to check it here
        ICurveBasePool pool = ICurveBasePool(assetInfo.pool);

        // TODO: I'd prefer to use address.call here, as some pool implementations return amount, some not.
        // If call eventually returns some data, we can use it in a upcoming calls, if not we need to call UNDERLYING_ASSET.balanceOf(address(this))
        //
        // balance of underlying asset before deposit
        uint256 balancePre = IERC20(UNDERLYING_ASSET).balanceOf(address(this));

        if (assetInfo.isLpToken) {
            pool.remove_liquidity_one_coin(amount, assetInfo.index, minAmount);
        } else {
            pool.exchange(assetInfo.index, UNDERLYING_ASSET_INDEX, amount, minAmount);
        }

        // actual amount of underlying asset that was deposited
        uint256 underlyingAmount = IERC20(UNDERLYING_ASSET).balanceOf(address(this)) - balancePre;

        // we need to approve the strategy to spend underlying asset
        SafeERC20.safeApprove(IERC20(UNDERLYING_ASSET), strategyAddress, 0);
        SafeERC20.safeApprove(IERC20(UNDERLYING_ASSET), strategyAddress, underlyingAmount);

        // deposit
        shares = multiPoolStrategy.deposit(underlyingAmount, address(this));

        // transfer shares to receiver
        SafeERC20.safeTransfer(IERC20(strategyAddress), receiver, shares);

        return shares;
    }

    /**
     * @inheritdoc IZapper
     */
    function withdraw(
        uint256 amount,
        address withdrawToken,
        uint256 minWithdrawAmount,
        address receiver,
        address strategyAddress
    )
        external
        override
        nonReentrant
        returns (uint256 sharesBurnt)
    {
        // check if the reciever is not zero address
        if (receiver == address(0)) revert ZeroAddress();
        // check if the amount is not zero
        if (amount == 0) revert EmptyInput();
        // check if the correct strategy provided and it matches underlying asset
        if (!strategyUsesUnderlyingAsset(strategyAddress)) revert StrategyAssetDoesNotMatchUnderlyingAsset();

        // check if the strategy is not paused
        IMultiPoolStrategy multiPoolStrategy = IMultiPoolStrategy(strategyAddress);
        if (multiPoolStrategy.paused()) revert StrategyPaused();

        // check if the provided token is in the assets array, if false - revert
        if (!_supportedAssets.contains(withdrawToken)) revert InvalidAsset();

        // find the pool regarding the provided token, if pool not found - revert
        AssetInfo storage assetInfo = _supportedAssetsInfo[withdrawToken];
        if (assetInfo.pool == address(0)) revert PoolDoesNotExist();

        // calculate the amount of underlying asset to withdraw, given the asset the user want to get
        // i.e. Calculate the amount of USDC (underlying asset) to withdraw, given the amount of CRV (withdraw token)
        uint256 underlyingAmountToWithdraw;
        if (assetInfo.isLpToken) {
            underlyingAmountToWithdraw =
                ICurveBasePool(assetInfo.pool).calc_withdraw_one_coin(amount, UNDERLYING_ASSET_INDEX);
        } else {
            underlyingAmountToWithdraw =
                ICurveBasePool(assetInfo.pool).get_dy(assetInfo.index, UNDERLYING_ASSET_INDEX, amount);
        }

        // balance of underlying asset before withdraw
        uint256 underlyingBalancePre = IERC20(UNDERLYING_ASSET).balanceOf(address(this));

        // The last parameter here, minAmount, is set to zero because we enforce it later during the swap
        // in "curvePool.addLiquidity" or "curvePool.exchange" calls
        sharesBurnt = multiPoolStrategy.withdraw(underlyingAmountToWithdraw, address(this), _msgSender(), 0);

        // actual amount of underlying asset after withdraw
        uint256 withdrawnUnderlyingAmount = IERC20(UNDERLYING_ASSET).balanceOf(address(this)) - underlyingBalancePre;

        ICurveBasePool pool = ICurveBasePool(assetInfo.pool);

        SafeERC20.safeApprove(IERC20(UNDERLYING_ASSET), assetInfo.pool, 0);
        SafeERC20.safeApprove(IERC20(UNDERLYING_ASSET), assetInfo.pool, withdrawnUnderlyingAmount);

        // balance of user's token before withdraw
        uint256 balancePre = IERC20(withdrawToken).balanceOf(address(this));

        // get withdraw tokens by given the underlying asset
        //
        // in case if withdraw token is LP Token - then we call "curvePool.addLiquidity",
        // as LP Tokens can be retrivied only by providing liquidity to the pool
        // i.e. (withdrawToken = CRV) -> curvePool.addLiquidity(tokenToAdd: USDC) => return CRV
        //
        // if the withdrawal token is not LP Token - then we call "curvePool.exchange",
        // as we just need to exchange one token for another
        // i.e. (withdrawToken = USDT) -> curvePool.exchange(tokenToProvide: USDC, tokenToGet: USDT) => return USDT
        //
        // inside we create an array with a length equal to the number of tokens in the pool,
        // where the index of each element corresponds to the index of the token in the pool
        // and then set the token amount corresponding to the token index in the pool that we intend
        // to add as liquidity or exchange
        //
        // this place should be optimized
        if (assetInfo.isLpToken) {
            if (assetInfo.pool == CURVE_3POOL) {
                uint256[CURVE_3POOL_TOKENS_COUNT] memory amounts;
                amounts[uint256(int256(assetInfo.index))] = withdrawnUnderlyingAmount;

                pool.add_liquidity(amounts, minWithdrawAmount);
            } else if (assetInfo.pool == CURVE_FRAXUSDC) {
                uint256[CURVE_FRAXUSDC_TOKENS_COUNT] memory amounts;
                amounts[uint256(int256(assetInfo.index))] = withdrawnUnderlyingAmount;

                pool.add_liquidity(amounts, minWithdrawAmount);
            }
        } else {
            pool.exchange(UNDERLYING_ASSET_INDEX, assetInfo.index, withdrawnUnderlyingAmount, minWithdrawAmount);
        }

        // actual amount of tokens user will get after withdraw
        uint256 withdrawAmount = IERC20(withdrawToken).balanceOf(address(this)) - balancePre;

        SafeERC20.safeTransfer(IERC20(withdrawToken), receiver, withdrawAmount);
    }

    /**
     * @inheritdoc IZapper
     */
    function redeem(
        uint256 sharesAmount,
        address redeemToken,
        uint256 minRedeemAmount,
        address receiver,
        address strategyAddress
    )
        external
        override
        returns (uint256 redeemAmount)
    {
        // check if the reciever is not zero address
        if (receiver == address(0)) revert ZeroAddress();
        // check if the amount is not zero
        if (sharesAmount == 0) revert EmptyInput();
        // check if the correct strategy provided and it matches underlying asset
        if (!strategyUsesUnderlyingAsset(strategyAddress)) revert StrategyAssetDoesNotMatchUnderlyingAsset();

        // check if the strategy is not paused
        IMultiPoolStrategy multiPoolStrategy = IMultiPoolStrategy(strategyAddress);
        if (multiPoolStrategy.paused()) revert StrategyPaused();

        // check if the provided token is in the assets array, if false - revert
        if (!_supportedAssets.contains(redeemToken)) revert InvalidAsset();

        // find the pool regarding the provided token, if pool not found - revert
        AssetInfo storage assetInfo = _supportedAssetsInfo[redeemToken];
        if (assetInfo.pool == address(0)) revert PoolDoesNotExist();

        // The last parameter here, minAmount, is set to zero because we enforce it later during the swap
        // in "curvePool.addLiquidity" or "curvePool.exchange" calls
        uint256 underlyingAmount = multiPoolStrategy.redeem(sharesAmount, address(this), _msgSender(), 0);

        ICurveBasePool pool = ICurveBasePool(assetInfo.pool);

        SafeERC20.safeApprove(IERC20(UNDERLYING_ASSET), assetInfo.pool, 0);
        SafeERC20.safeApprove(IERC20(UNDERLYING_ASSET), assetInfo.pool, underlyingAmount);

        // balance of user's token before redeem
        uint256 balancePre = IERC20(redeemToken).balanceOf(address(this));

        // get redeem tokens by given the underlying asset
        //
        // in case if redeem token is LP Token - then we call "curvePool.addLiquidity",
        // as LP Tokens can be retrivied only by providing liquidity to the pool
        // i.e. redeemToken = CRV) -> curvePool.addLiquidity(tokenToAdd: USDC) => return CRV
        //
        // if the redeem token is not LP Token - then we call "curvePool.exchange",
        // as we just need to exchange one token for another
        // i.e. (redeemToken = USDT) -> curvePool.exchange(tokenToProvide: USDC, tokenToGet: USDT) => return USDT
        //
        // inside we create an array with a length equal to the number of tokens in the pool,
        // where the index of each element corresponds to the index of the token in the pool
        // and then set the token amount corresponding to the underlying token index in the pool that we intend
        // to add as liquidity or exchange
        //
        // this place should be optimized
        if (assetInfo.isLpToken) {
            if (assetInfo.pool == CURVE_3POOL) {
                uint256[CURVE_3POOL_TOKENS_COUNT] memory amounts;
                amounts[uint256(int256(UNDERLYING_ASSET_INDEX))] = underlyingAmount;

                pool.add_liquidity(amounts, minRedeemAmount);
            } else if (assetInfo.pool == CURVE_FRAXUSDC) {
                uint256[CURVE_FRAXUSDC_TOKENS_COUNT] memory amounts;
                amounts[uint256(int256(UNDERLYING_ASSET_INDEX))] = underlyingAmount;

                pool.add_liquidity(amounts, minRedeemAmount);
            }
        } else {
            pool.exchange(UNDERLYING_ASSET_INDEX, assetInfo.index, underlyingAmount, minRedeemAmount);
        }

        // actual amount of tokens user will get after redeem
        redeemAmount = IERC20(redeemToken).balanceOf(address(this)) - balancePre;

        SafeERC20.safeTransfer(IERC20(redeemToken), receiver, redeemAmount);
    }

    /**
     * @dev Checks if an asset is supported.
     * @param asset The asset address to check.
     * @return True if the asset is supported, false otherwise.
     */
    function assetIsSupported(address asset) external view returns (bool) {
        return _supportedAssets.contains(asset);
    }

    /**
     * @dev Retrieves information about a supported asset.
     * @param asset The asset address to retrieve information for.
     * @return AssetInfo struct containing the asset's pool, index, and LP token status.
     */
    function getAssetInfo(address asset) external view returns (AssetInfo memory) {
        return _supportedAssetsInfo[asset];
    }

    /**
     * @inheritdoc IZapper
     */
    function strategyUsesUnderlyingAsset(address strategyAddress) public view override returns (bool) {
        IMultiPoolStrategy multipoolStrategy = IMultiPoolStrategy(strategyAddress);
        return multipoolStrategy.asset() == address(UNDERLYING_ASSET);
    }

    /**
     * @dev Adds a new asset to the list of supported assets along with its related info.
     * @param asset The address of the asset to add.
     * @param assetInfo Struct containing pool, index, and LP token status information for the asset.
     */
    function addAsset(address asset, AssetInfo memory assetInfo) public onlyOwner {
        _supportedAssets.add(asset);
        _supportedAssetsInfo[asset] = assetInfo;
    }

    /**
     * @dev Updates information about a supported asset.
     * @param asset The address of the asset to update information for.
     * @param assetInfo New struct containing updated pool, index, and LP token status information for the asset.
     */
    function updateAsset(address asset, AssetInfo memory assetInfo) public onlyOwner {
        if (!_supportedAssets.contains(asset)) revert InvalidAsset();
        _supportedAssetsInfo[asset] = assetInfo;
    }

    /**
     * @dev Removes an asset from the list of supported assets along with its related info.
     * @param asset The address of the asset to remove.
     */
    function removeAsset(address asset) public onlyOwner {
        _supportedAssets.remove(asset);
        delete _supportedAssetsInfo[asset];
    }
}
