// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity 0.8.21;

import "./UtilLib.sol";
import "./IPriceFetcher.sol";
import "./Initializable.sol";

interface IETHXStakePoolsManager {
    function getExchangeRate() external view returns (uint256);
    function staderConfig() external view returns (address);
}

interface IStaderConfig {
    function getETHxToken() external view returns (address);
}

/// @title EthXPriceOracle Contract
/// @notice contract that fetches the exchange rate of ETHX/ETH
contract EthXPriceOracle is IPriceFetcher, Initializable {
    address public ethXStakePoolsManagerProxyAddress;

    error InvalidAsset();

    /// @custom:oz-upgrades-unsafe-allow constructor
    constructor() {
        _disableInitializers();
    }

    /// @dev Initializes the contract
    /// @param ethXStakePoolsManagerProxyAddress_ ETHX address
    function initialize(address ethXStakePoolsManagerProxyAddress_) external initializer {
        UtilLib.checkNonZeroAddress(ethXStakePoolsManagerProxyAddress_);
        ethXStakePoolsManagerProxyAddress = ethXStakePoolsManagerProxyAddress_;
    }

    /// @notice Fetches Asset/ETH exchange rate
    /// @param asset the asset for which exchange rate is required
    /// @return assetPrice exchange rate of asset
    function getAssetPrice(address asset) external view returns (uint256) {
        address staderConfigProxyAddress = IETHXStakePoolsManager(ethXStakePoolsManagerProxyAddress).staderConfig();

        if (asset != IStaderConfig(staderConfigProxyAddress).getETHxToken()) {
            revert InvalidAsset();
        }

        return IETHXStakePoolsManager(ethXStakePoolsManagerProxyAddress).getExchangeRate();
    }
}
