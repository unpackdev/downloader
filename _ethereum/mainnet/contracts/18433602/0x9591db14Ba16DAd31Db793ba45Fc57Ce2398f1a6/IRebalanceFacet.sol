// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;

import "./IPermissionsFacet.sol";
import "./IDutchAuctionFacet.sol";
import "./IVaultFacet.sol";

interface IRebalanceFacet {
    function rebalance(address callback, bytes calldata data) external;

    function rebalanceInitialized() external view returns (bool);

    function rebalanceSelectors() external view returns (bytes4[] memory selectors_);
}
