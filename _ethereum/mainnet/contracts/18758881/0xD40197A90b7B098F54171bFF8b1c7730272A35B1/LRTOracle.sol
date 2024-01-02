// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity 0.8.21;

import "./UtilLib.sol";
import "./LRTConstants.sol";
import "./LRTConfigRoleChecker.sol";

import "./IRSETH.sol";
import "./IPriceFetcher.sol";
import "./ILRTOracle.sol";
import "./ILRTDepositPool.sol";
import "./INodeDelegator.sol";

import "./IERC20.sol";
import "./Initializable.sol";

/// @title LRTOracle Contract
/// @notice oracle contract that calculates the exchange rate of assets
contract LRTOracle is ILRTOracle, LRTConfigRoleChecker, Initializable {
    mapping(address asset => address priceOracle) public override assetPriceOracle;
    uint256 public override rsETHPrice;

    /// @custom:oz-upgrades-unsafe-allow constructor
    constructor() {
        _disableInitializers();
    }

    /// @dev Initializes the contract
    /// @param lrtConfigAddr LRT config address
    function initialize(address lrtConfigAddr) external initializer {
        UtilLib.checkNonZeroAddress(lrtConfigAddr);

        lrtConfig = ILRTConfig(lrtConfigAddr);
        emit UpdatedLRTConfig(lrtConfigAddr);
    }

    /*//////////////////////////////////////////////////////////////
                            view functions
    //////////////////////////////////////////////////////////////*/

    /// @notice Provides Asset/ETH exchange rate
    /// @dev reads from priceFetcher interface which may fetch price from any supported oracle
    /// @param asset the asset for which exchange rate is required
    /// @return assetPrice exchange rate of asset
    function getAssetPrice(address asset) public view onlySupportedAsset(asset) returns (uint256) {
        return IPriceFetcher(assetPriceOracle[asset]).getAssetPrice(asset);
    }

    /// @notice updates RSETH/ETH exchange rate
    /// @dev calculates based on stakedAsset value received from eigen layer
    function updateRSETHPrice() external {
        address rsETHTokenAddress = lrtConfig.rsETH();
        uint256 rsEthSupply = IRSETH(rsETHTokenAddress).totalSupply();

        if (rsEthSupply == 0) {
            rsETHPrice = 1 ether;
            return;
        }

        uint256 totalETHInPool;
        address lrtDepositPoolAddr = lrtConfig.getContract(LRTConstants.LRT_DEPOSIT_POOL);

        address[] memory supportedAssets = lrtConfig.getSupportedAssetList();
        uint256 supportedAssetCount = supportedAssets.length;

        for (uint16 asset_idx; asset_idx < supportedAssetCount;) {
            address asset = supportedAssets[asset_idx];
            uint256 assetER = getAssetPrice(asset);

            uint256 totalAssetAmt = ILRTDepositPool(lrtDepositPoolAddr).getTotalAssetDeposits(asset);
            totalETHInPool += totalAssetAmt * assetER;

            unchecked {
                ++asset_idx;
            }
        }

        rsETHPrice = totalETHInPool / rsEthSupply;
    }

    /*//////////////////////////////////////////////////////////////
                            write functions
    //////////////////////////////////////////////////////////////*/

    /// @dev add/update the price oracle of any supported asset
    /// @dev only LRTManager is allowed
    /// @param asset asset address for which oracle price needs to be added/updated
    function updatePriceOracleFor(
        address asset,
        address priceOracle
    )
        external
        onlyLRTManager
        onlySupportedAsset(asset)
    {
        UtilLib.checkNonZeroAddress(priceOracle);
        assetPriceOracle[asset] = priceOracle;
        emit AssetPriceOracleUpdate(asset, priceOracle);
    }
}
