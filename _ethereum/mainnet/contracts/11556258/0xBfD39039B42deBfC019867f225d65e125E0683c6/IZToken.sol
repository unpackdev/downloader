// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.7.0;

import "./IERC20.sol";

interface IZToken is IERC20 {
    function pause() external;

    function unpause() external;

    function addSuperAdmin(address account) external;

    function renounceSuperAdmin() external;

    function addAdmin(address account) external;

    function removeAdmin(address account) external;

    function renounceAdmin() external;

    function isSuperAdmin(address account) external view returns (bool);

    function isAdmin(address account) external view returns (bool);
}
