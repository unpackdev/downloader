// SPDX-License-Identifier: MIT
pragma solidity 0.8.11;

import "./UniverseMarketplaceCore.sol";
import "./UniverseTransferManager.sol";
import "./IRoyaltiesProvider.sol";

contract UniverseMarketplace is UniverseMarketplaceCore, UniverseTransferManager {
    function __UniverseMarketplace_init(
        uint daoFee,
        address daoAddress,
        IRoyaltiesProvider royaltiesProvider,
        uint256 maxBundleSize,
        uint256 maxBatchTransferSize
    ) external initializer {
        __Context_init_unchained();
        __Ownable_init_unchained();
        __TransferExecutor_init_unchained(maxBundleSize, maxBatchTransferSize);
        __UniverseTransferManager_init_unchained(daoFee, daoAddress, royaltiesProvider);
    }
}
