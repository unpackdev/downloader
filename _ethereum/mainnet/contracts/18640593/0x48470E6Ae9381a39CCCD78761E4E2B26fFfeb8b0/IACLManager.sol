// SPDX-License-Identifier: MIT

pragma solidity 0.8.17;

import "./AccessControl.sol";

interface IACLManager {
    function setRoleAdmin(bytes32 role, bytes32 adminRole) external;

    function addCegaAdmin(address admin) external;

    function removeCegaAdmin(address admin) external;

    function addTraderAdmin(address admin) external;

    function removeTraderAdmin(address admin) external;

    function addOperatorAdmin(address admin) external;

    function removeOperatorAdmin(address admin) external;

    function addServiceAdmin(address admin) external;

    function removeServiceAdmin(address admin) external;

    function isCegaAdmin(address admin) external view returns (bool);

    function isTraderAdmin(address admin) external view returns (bool);

    function isOperatorAdmin(address admin) external view returns (bool);

    function isServiceAdmin(address admin) external view returns (bool);
}
