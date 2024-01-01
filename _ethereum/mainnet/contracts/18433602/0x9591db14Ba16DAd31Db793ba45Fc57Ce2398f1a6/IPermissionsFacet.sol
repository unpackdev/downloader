// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;

interface IPermissionsFacet {
    struct Storage {
        bool initialized;
        mapping(address => uint256) userRoles;
        uint256 publicRoles;
        mapping(address => uint256) allowAllSignaturesRoles;
        mapping(address => mapping(bytes4 => uint256)) allowSignatureRoles;
    }

    function initializePermissionsFacet(address admin) external;

    function hasPermission(address user, address contractAddress, bytes4 signature) external view returns (bool);

    function requirePermission(address user, address contractAddress, bytes4 signature) external;

    function grantPublicRole(uint8 role) external;

    function revokePublicRole(uint8 role) external;

    function grantContractRole(address contractAddress, uint8 role) external;

    function revokeContractRole(address contractAddress, uint8 role) external;

    function grantContractSignatureRole(address contractAddress, bytes4 signature, uint8 role) external;

    function revokeContractSignatureRole(address contractAddress, bytes4 signature, uint8 role) external;

    function grantRole(address user, uint8 role) external;

    function revokeRole(address user, uint8 role) external;

    function userRoles(address user) external view returns (uint256);

    function publicRoles() external view returns (uint256);

    function allowAllSignaturesRoles(address contractAddress) external view returns (uint256);

    function allowSignatureRoles(address contractAddress, bytes4 selector) external view returns (uint256);

    function permissionsInitialized() external view returns (bool);

    function permissionsSelectors() external view returns (bytes4[] memory selectors_);
}
