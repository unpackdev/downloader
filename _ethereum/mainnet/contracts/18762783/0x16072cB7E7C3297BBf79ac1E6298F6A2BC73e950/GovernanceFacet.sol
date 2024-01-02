// SPDX-License-Identifier: MIT
pragma solidity 0.8.20;

import "./IDiamondCut.sol";
import "./Modifiers.sol";
import "./AppStorage.sol";
import "./LibGovernance.sol";
import "./LibAdmin.sol";
import "./LibConstants.sol";

contract GovernanceFacet is Modifiers {
    event CreateUpgrade(bytes32 id, address indexed who);
    event UpdateUpgradeExpiration(uint256 duration);
    event UpgradeCancelled(bytes32 id, address indexed who);

    /**
     * @notice Check if the diamond has been initialized.
     * @dev This will get the value from AppStorage.diamondInitialized.
     */
    function isDiamondInitialized() external view returns (bool) {
        AppStorage storage s = LibAppStorage.diamondStorage();
        return s.diamondInitialized;
    }

    function calculateUpgradeId(IDiamondCut.FacetCut[] calldata _diamondCut, address _init, bytes calldata _calldata) external pure returns (bytes32) {
        return LibGovernance._calculateUpgradeId(_diamondCut, _init, _calldata);
    }

    function createUpgrade(bytes32 id) external assertPrivilege(LibAdmin._getSystemId(), LC.GROUP_SYSTEM_ADMINS) {
        AppStorage storage s = LibAppStorage.diamondStorage();

        if (s.upgradeScheduled[id] > block.timestamp) {
            revert("Upgrade has already been scheduled");
        }
        // 0 == upgrade is not scheduled / has been cancelled
        // block.timestamp + upgradeExpiration == upgrade is scheduled and expires at this time
        // Set back to 0 when an upgrade is complete
        s.upgradeScheduled[id] = block.timestamp + s.upgradeExpiration;
        emit CreateUpgrade(id, msg.sender);
    }

    function updateUpgradeExpiration(uint256 duration) external assertPrivilege(LibAdmin._getSystemId(), LC.GROUP_SYSTEM_ADMINS) {
        AppStorage storage s = LibAppStorage.diamondStorage();

        require(1 minutes < duration && duration < 1 weeks, "invalid upgrade expiration period");

        s.upgradeExpiration = duration;
        emit UpdateUpgradeExpiration(duration);
    }

    function cancelUpgrade(bytes32 id) external assertPrivilege(LibAdmin._getSystemId(), LC.GROUP_SYSTEM_ADMINS) {
        AppStorage storage s = LibAppStorage.diamondStorage();

        require(s.upgradeScheduled[id] > 0, "invalid upgrade ID");

        s.upgradeScheduled[id] = 0;

        emit UpgradeCancelled(id, msg.sender);
    }

    function getUpgrade(bytes32 id) external view returns (uint256 expiry) {
        AppStorage storage s = LibAppStorage.diamondStorage();
        expiry = s.upgradeScheduled[id];
    }

    function getUpgradeExpiration() external view returns (uint256 upgradeExpiration) {
        AppStorage storage s = LibAppStorage.diamondStorage();
        upgradeExpiration = s.upgradeExpiration;
    }
}
