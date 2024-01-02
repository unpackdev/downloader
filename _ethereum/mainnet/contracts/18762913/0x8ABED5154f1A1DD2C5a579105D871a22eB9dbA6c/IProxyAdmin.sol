// // SPDX-License-Identifier: MIT
// // OpenZeppelin Contracts (last updated v4.8.3) (proxy/transparent/ProxyAdmin.sol)

// pragma solidity ^0.8.0;

// import "./ITransparentUpgradeableProxy.sol";

// /**
//  * @dev This is an auxiliary contract meant to be assigned as the admin of a {TransparentUpgradeableProxy}. For an
//  * explanation of why you would want to use this see the documentation for {TransparentUpgradeableProxy}.
//  */
// interface IProxyAdmin {
//     /**
//      * @dev Returns the current implementation of `proxy`.
//      *
//      * Requirements:
//      *
//      * - This contract must be the admin of `proxy`.
//      */
//     function getProxyImplementation(ITransparentUpgradeableProxy proxy) external view returns (address);

//     /**
//      * @dev Returns the current admin of `proxy`.
//      *
//      * Requirements:
//      *
//      * - This contract must be the admin of `proxy`.
//      */
//     function getProxyAdmin(ITransparentUpgradeableProxy proxy) external view returns (address);

//     /**
//      * @dev Changes the admin of `proxy` to `newAdmin`.
//      *
//      * Requirements:
//      *
//      * - This contract must be the current admin of `proxy`.
//      */
//     function changeProxyAdmin(ITransparentUpgradeableProxy proxy, address newAdmin) external;

//     /**
//      * @dev Upgrades `proxy` to `implementation`. See {TransparentUpgradeableProxy-upgradeTo}.
//      *
//      * Requirements:
//      *
//      * - This contract must be the admin of `proxy`.
//      */
//     function upgrade(ITransparentUpgradeableProxy proxy, address implementation) external;

//     /**
//      * @dev Upgrades `proxy` to `implementation` and calls a function on the new implementation. See
//      * {TransparentUpgradeableProxy-upgradeToAndCall}.
//      *
//      * Requirements:
//      *
//      * - This contract must be the admin of `proxy`.
//      */
//     function upgradeAndCall(
//         ITransparentUpgradeableProxy proxy,
//         address implementation,
//         bytes memory data
//     ) external payable;
// }
