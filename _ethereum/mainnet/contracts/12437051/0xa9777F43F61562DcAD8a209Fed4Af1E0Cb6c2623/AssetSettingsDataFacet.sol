// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

// Contracts
import "./RolesMods.sol";
import "./roles.sol";

// Interfaces
import "./ICErc20.sol";

// Libraries
import "./CacheLib.sol";
import "./AssetCTokenLib.sol";
import "./MaxLoanAmountLib.sol";
import "./MaxTVLLib.sol";

// Storage
import "./app.sol";

/**
 * @notice View function to get asset setting values.
 *
 * @author develop@teller.finance
 */
contract AssetSettingsDataFacet {
    function getAssetMaxLoanAmount(address asset)
        external
        view
        returns (uint256)
    {
        return MaxLoanAmountLib.get(asset);
    }

    function getAssetMaxTVL(address asset) external view returns (uint256) {
        return MaxTVLLib.get(asset);
    }

    function getAssetCToken(address asset) external view returns (ICErc20) {
        return AssetCTokenLib.get(asset);
    }
}
