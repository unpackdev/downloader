// SPDX-License-Identifier: MIT
pragma solidity 0.8.20;

import "./IDiamondCut.sol";

/// @notice Contains internal methods for upgrade functionality
library LibGovernance {
    function _calculateUpgradeId(IDiamondCut.FacetCut[] memory _diamondCut, address _init, bytes memory _calldata) internal pure returns (bytes32) {
        return keccak256(abi.encode(_diamondCut, _init, _calldata));
    }
}
