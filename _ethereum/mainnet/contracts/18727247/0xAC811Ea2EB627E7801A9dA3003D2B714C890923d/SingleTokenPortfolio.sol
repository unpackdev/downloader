//SPDX-License-Identifier: BSD 3-Clause
pragma solidity 0.8.13;

import "./Registry.sol";
import "./Portfolio.sol";
import "./ISwapWrapper.sol";
import "./Math.sol";
import "./ERC20.sol";
import "./SafeTransferLib.sol";

contract SingleTokenPortfolio is Portfolio {
    using SafeTransferLib for ERC20;
    using Math for uint256;

    /// @notice Percentage error margin for caller's redemption assetOut estimation as WAD (e.g. .01e18 means error tolerance of 1%).
    uint256 public errorMarginPct;

    /// @notice Emitted when caller's redemption assetOut estimation is off by more than errorMarginPct.
    error ErrorMarginExceeded(uint256 expectedAssetsOut, uint256 actualAssetsOut, uint256 margin);

    /// @notice Emitted when errorMarginPct is set.
    event ErrorMarginPctSet(uint256 newErrorMarginPct);

    /**
     * @param _registry Endaoment registry.
     * @param _receiptAsset Underlying ERC20 asset token for portfolio.
     * @param _shareTokenName Name of ERC20 portfolio share token.
     * @param _shareTokenSymbol Symbol of ERC20 portfolio share token.
     * @param _cap Amount of baseToken that this portfolio's asset balance should not exceed.
     * @param _feeTreasury Address of treasury that should receive fees.
     * @param _depositFee Percentage fee as ZOC that should go to treasury on deposit. (100 = 1%).
     * @param _redemptionFee Percentage fee as ZOC that should go to treasury on redemption. (100 = 1%).
     * @param _aumRate Percentage fee per second (as WAD) that should accrue to treasury as AUM fee. (1e16 = 1%).
     * @param _errorMarginPct Tolerable error percentage (as WAD) that caller's redemption asset estimation can be off by.
     */
    constructor(
        Registry _registry,
        address _receiptAsset,
        string memory _shareTokenName,
        string memory _shareTokenSymbol,
        uint256 _cap,
        address _feeTreasury,
        uint256 _depositFee,
        uint256 _redemptionFee,
        uint256 _aumRate,
        uint256 _errorMarginPct
    )
        Portfolio(
            _registry,
            _receiptAsset,
            _shareTokenName,
            _shareTokenSymbol,
            _cap,
            _feeTreasury,
            _depositFee,
            _redemptionFee,
            _aumRate
        )
    {
        if (_errorMarginPct > Math.WAD) revert PercentageOver100();
        errorMarginPct = _errorMarginPct;
        emit ErrorMarginPctSet(_errorMarginPct);
    }

    /**
     * @notice Role authed method to set the tolerance of error for caller's redemption assetOut estimation.
     * @param _pct New percentage error margin as WAD.
     */
    function setErrorMarginPct(uint256 _pct) public requiresAuth {
        if (_pct > Math.WAD) revert PercentageOver100();
        errorMarginPct = _pct;
        emit ErrorMarginPctSet(_pct);
    }

    /**
     * @inheritdoc Portfolio
     */
    function _getAsset(address _receiptAsset) internal pure override returns (address) {
        return _receiptAsset;
    }

    /**
     * @inheritdoc Portfolio
     */
    function _checkCap() internal view override {
        // bypass cap check; we will check it in _deposit
    }

    /**
     * @inheritdoc Portfolio
     * @dev In SingleTokenPortfolio we consider `asset` and `receiptAsset` to be the same. This portfolio merely
     * holds the `asset` in its custody until redemption.
     */
    function convertReceiptAssetsToAssets(uint256 _receiptAssets) public pure override returns (uint256) {
        return _receiptAssets;
    }

    /**
     * @notice Like `convertToAssets`, converts shares to assets, but factors in AUM fee delta as well.
     * Users will need to use this method to calculate their expected assets out for redemption.
     * @param _shares Amount of shares to convert to assets.
     * @param _elapsed Upper bound of time expected to elapse between calculation and inclusion on chain.
     * @dev Rounding down in both of these favors the portfolio, so the user gets slightly less and the portfolio gets slightly more,
     * that way it prevents a situation where the user is owed x but the vault only has x - epsilon, where epsilon is some tiny number
     * due to rounding error.
     * @return Amount of assets that `_shares` is worth after `_elapsed` seconds.
     */
    function convertToAssetsLessFutureFees(uint256 _shares, uint256 _elapsed) external view returns (uint256) {
        uint256 _supply = totalSupply; // Saves an extra SLOAD if totalSupply is non-zero.
        uint256 _totalAssets = totalAssets();
        uint256 _feeAmount = _calculateAumFee(_totalAssets, block.timestamp + _elapsed - timestampAumFeesTaken);
        if (_feeAmount > _totalAssets) return 0;
        return _supply == 0 ? _shares : _shares.mulDivDown(_totalAssets - _feeAmount, _supply);
    }

    /**
     * @notice This method is needed to calculate shares deposit because we already possess the assets that we want to convert.
     * @dev Rounding down favors the portfolio, so the user gets slightly less and the portfolio gets slightly more, that way it prevents
     * a situation where the user is owed x but the vault only has x - epsilon, where epsilon is some tiny number due to rounding error.
     * @return Amount of shares that `_assets` is worth.
     */
    function _convertToSharesLessAssets(uint256 _assets) private view returns (uint256) {
        uint256 _supply = totalSupply; // Saves an extra SLOAD if totalSupply is non-zero.
        return _supply == 0 ? _assets : _assets.mulDivDown(_supply, totalAssets() - _assets);
    }

    /**
     * @inheritdoc Portfolio
     * @dev We convert `baseToken` to `asset` via a swap wrapper.
     * `_data` should be the ABI-encoded `uint minSharesOut`, plus a packed swap wrapper address concatenated with the bytes payload your
     * swap wrapper expects. i.e. `abi.encodePacked(uint _minSharesOut, abi.encodePacked(address swapWrapper), SWAP_WRAPPER_BYTES)`.
     * To determine if this deposit exceeds the cap, we get the asset/baseToken exchange rate and multiply it by `totalAssets`.
     */
    function _deposit(uint256 _amountBaseToken, bytes calldata _data)
        internal
        override
        returns (uint256, uint256, uint256)
    {
        // check swap wrapper
        ISwapWrapper _swapWrapper = ISwapWrapper(address(bytes20(_data[32:32 + 20])));
        if (!registry.isSwapperSupported(_swapWrapper)) revert InvalidSwapper();

        // transfer in baseToken, transfer out fees, and swap to asset
        (uint256 _amountIn, uint256 _amountFee) = _calculateFee(_amountBaseToken, depositFee);
        baseToken.safeTransferFrom(msg.sender, address(this), _amountBaseToken);
        baseToken.safeTransfer(feeTreasury, _amountFee);
        baseToken.safeApprove(address(_swapWrapper), 0);
        baseToken.safeApprove(address(_swapWrapper), _amountIn);
        uint256 _assets = _swapWrapper.swap(address(baseToken), asset, address(this), _amountIn, _data[32 + 20:]);

        // Convert totalAssets to baseToken unit to measure against cap.
        if (totalAssets() * _amountIn / _assets > cap) revert ExceedsCap();

        uint256 _shares = _convertToSharesLessAssets(_assets);
        return (_shares, _assets, _amountFee);
    }

    /**
     * @inheritdoc Portfolio
     * @dev After converting `shares` to `assets`, we convert `assets` to `baseToken` via a swap wrapper.
     *
     * `_data` should consist of:
     * 1.) An encoded uint256 `expectedAssetsOut` that we'll use as your redemption value. It must be within a tolerance of
     *     `errorMarginPct` from the exact asset amount your shares are entitled to. This is necessary because the correct asset value
     *     changes by a small amount every second, due to AUM fees or in some cases rebasing tokens. But to swap the assets back to USDC,
     *     the asset amount must match the amountIn of the swap calldata. Therefore, we introduce this error tolerance. It's recommended
     *     to use `convertToAssetsLessFutureFees` to calculate an `expectedAssetsOut` that accounts for the time elapsed between
     *     calculation and inclusion on chain.
     * 2.) A packed swap wrapper address concatenated with the bytes payload your swap wrapper expects.
     *
     *  _data payload example:
     *  `abi.encodePacked(uint expectedAssetsOut, abi.encodePacked(address swapWrapper), SWAP_WRAPPER_BYTES)`.
     */
    function _redeem(uint256 _amountShares, bytes calldata _data)
        internal
        override
        returns (uint256 assetsOut, uint256 baseTokenOut)
    {
        uint256 _assetsOut = convertToAssets(_amountShares);
        (uint256 _actualAssetsOut, uint256 _baseTokenOut) = _exit(_assetsOut, _data);
        return (_actualAssetsOut, _baseTokenOut);
    }

    /**
     * @inheritdoc Portfolio
     */
    function _exit(uint256 _assetsOut, bytes calldata _data)
        internal
        override
        returns (uint256 actualAssetsOut, uint256 baseTokenOut)
    {
        ISwapWrapper _swapWrapper = ISwapWrapper(address(bytes20(_data[32:32 + 20])));
        if (!registry.isSwapperSupported(_swapWrapper)) revert InvalidSwapper();
        // is specified _expectedAssetsOut within reasonable margin of error?
        uint256 _expectedAssetsOut = abi.decode(_data, (uint256));

        /**
         * Because _assetsOut changes every second due to AUM fees, we need to allow for some error margin.
         * We do this by allowing _expectedAssetsOut to be within a certain percentage of _assetsOut.
         * `errorMarginPct` should be calibrated to allow for, say, 30 minutes of elapsed time between calculation and
         * inclusion on chain. And the user should account for this 30 minutes of elapsed time via `convertToAssetsLessFutureFees`
         * to calculate _expectedAssetsOut.
         * In the case where `asset` is a rebasing token, the `errorMarginPct` should be calibrated with the rebase rate in mind.
         */

        // _margin is the absolute amount that _expectedAssetsOut can be off by
        uint256 _margin = _assetsOut.mulWadDown(errorMarginPct);

        if (
            _expectedAssetsOut > _assetsOut // Make sure user isn't redeeming more than entitled to; also prevent overflow on next line
                || _assetsOut - _expectedAssetsOut > _margin // If off by more than _margin, revert
        ) {
            revert ErrorMarginExceeded(_expectedAssetsOut, _assetsOut, _margin);
        }

        ERC20(asset).safeApprove(address(_swapWrapper), 0);
        ERC20(asset).safeApprove(address(_swapWrapper), _expectedAssetsOut);
        uint256 _baseTokenOut =
            _swapWrapper.swap(asset, address(baseToken), address(this), _expectedAssetsOut, _data[32 + 20:]);
        return (_expectedAssetsOut, _baseTokenOut);
    }
}
