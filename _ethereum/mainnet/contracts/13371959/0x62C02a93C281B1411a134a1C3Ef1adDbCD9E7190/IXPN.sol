// SPDX-License-Identifier: Unlicense
pragma solidity 0.8.0;

import "./XPNSettlement.sol";
import "./XPNCore.sol";
import "./AccessControlEnumerable.sol";

interface IXPN is IAccessControlEnumerable {
    function deposit(uint256) external returns (uint256);

    function withdraw(uint256)
        external
        returns (address[] memory, uint256[] memory);

    function submitTrustedTradeOrders(
        bytes[] calldata _trades,
        address[] memory _venues
    ) external returns (bool);

    function submitTrustedPoolOrders(
        bytes[] calldata _orders,
        XPNSettlement.Pool[] calldata _txTypes,
        address[] memory _venues
    ) external returns (bool);

    function submitTradeOrders(
        bytes[] calldata _trades,
        address[] memory _venues
    ) external returns (bool);

    function submitPoolOrders(
        bytes[] calldata _orders,
        XPNSettlement.Pool[] calldata _txTypes,
        address[] memory _venues
    ) external returns (bool);

    function createMigration(XPNCore.State memory) external;

    function signalMigration() external;

    function executeMigration() external;

    function getExponentConfig()
        external
        view
        returns (
            address denomAsset,
            address lptoken,
            address signalPool,
            string memory signalName,
            address admin
        );

    function getEnzymeConfig()
        external
        view
        returns (
            address EZshares,
            address EZcomptroller,
            address EZwhitelistPolicy,
            address EZpolicy,
            address EZtrackedAssetAdapter,
            address EZintegrationManager,
            address EZdeployer
        );
}
