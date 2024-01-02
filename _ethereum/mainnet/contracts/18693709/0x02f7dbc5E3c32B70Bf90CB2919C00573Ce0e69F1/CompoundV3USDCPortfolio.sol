//SPDX-License-Identifier: BSD 3-Clause
pragma solidity 0.8.13;

import "./Registry.sol";
import "./Portfolio.sol";
import "./ICErc20.sol";
import "./Auth.sol";
import "./Math.sol";
import "./ERC20.sol";
import "./SafeTransferLib.sol";

contract CompoundV3USDCPortfolio is Portfolio {
    using SafeTransferLib for ERC20;
    using Math for uint256;

    /// @notice Address of the Compound III (Comet) USDC market/token.
    IComet public immutable cusdc;

    /// @dev Thrown when there's a mismatch between constructor arguments and the underlying asset.
    error AssetMismatch();

    /// @dev Thrown when the `sync` method is called after shutdown.
    error SyncAfterShutdown();

    /**
     * @param _registry Endaoment registry.
     * @param _receiptAsset Receipt token for this portfolio.
     * @param _cap Amount of baseToken that this portfolio's asset balance should not exceed.
     * @param _feeTreasury Address of the treasury that should receive fees.
     * @param _depositFee Percentage fee as ZOC that should go to treasury on deposit. (100 = 1%).
     * @param _redemptionFee Percentage fee as ZOC that should go to treasury on redemption. (100 = 1%).
     * @param _aumRate Percentage fee per second (as WAD) that should accrue to treasury as AUM fee. (1e16 = 1%).
     */
    constructor(
        Registry _registry,
        address _receiptAsset,
        uint256 _cap,
        address _feeTreasury,
        uint256 _depositFee,
        uint256 _redemptionFee,
        uint256 _aumRate
    )
        Portfolio(
            _registry,
            _receiptAsset,
            "Compound III USDC Portfolio Shares",
            "cUSDCv3-PS",
            _cap,
            _feeTreasury,
            _depositFee,
            _redemptionFee,
            _aumRate
        )
    {
        // The `asset` should match the base token, which means we expect it to be USDC.
        if (address(baseToken) != asset) revert AssetMismatch();

        cusdc = IComet(_receiptAsset);

        // Inputs are consistent, so we can approve the pool to spend our USDC.
        ERC20(asset).safeApprove(address(receiptAsset), type(uint256).max);
    }

    /**
     * @inheritdoc Portfolio
     */
    function _getAsset(address _receiptAsset) internal view override returns (address) {
        return IComet(_receiptAsset).baseToken();
    }

    /**
     * @inheritdoc Portfolio
     */
    function convertReceiptAssetsToAssets(uint256 _receiptAssets) public pure override returns (uint256) {
        // in this case, receipt asset and USDC balance are 1:1
        return _receiptAssets;
    }

    /**
     * @inheritdoc Portfolio
     * @dev `_data` should be the ABI-encoded `uint minSharesOut`.
     */
    function _deposit(uint256 _amountBaseToken, bytes calldata /* _data */ )
        internal
        override
        returns (uint256, uint256, uint256)
    {
        (uint256 _amountNet, uint256 _amountFee) = _calculateFee(_amountBaseToken, depositFee);
        uint256 _shares = convertToShares(_amountNet);
        ERC20(asset).safeTransferFrom(msg.sender, address(this), _amountBaseToken);
        ERC20(asset).safeTransfer(feeTreasury, _amountFee);
        cusdc.supply(asset, _amountNet);
        return (_shares, _amountNet, _amountFee);
    }

    /**
     * @inheritdoc Portfolio
     * @dev No calldata is needed for redeem/exit.
     */
    function _redeem(uint256 _amountShares, bytes calldata _data) internal override returns (uint256, uint256) {
        uint256 _assetsOut = convertToAssets(_amountShares);
        (, uint256 _baseTokenOut) = _exit(_assetsOut, _data);
        return (_assetsOut, _baseTokenOut);
    }

    /**
     * @inheritdoc Portfolio
     * @dev No calldata is needed for redeem/exit.
     */
    function _exit(uint256 _amountAssets, bytes calldata /*_data */ ) internal override returns (uint256, uint256) {
        if (_amountAssets == 0) revert RoundsToZero();
        cusdc.withdraw(asset, _amountAssets);
        return (_amountAssets, _amountAssets);
    }

    /**
     * @notice Deposits stray USDC for the benefit of everyone else
     */
    function sync() external requiresAuth {
        if (didShutdown) revert SyncAfterShutdown();
        cusdc.supply(asset, ERC20(asset).balanceOf(address(this)));
    }
}
