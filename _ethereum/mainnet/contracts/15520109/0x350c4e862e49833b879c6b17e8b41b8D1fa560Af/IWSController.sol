// SPDX-License-Identifier: GPL-3.0-or-later

pragma solidity ^0.6.12;

interface IWSController {
    function getLogicForPair() external view returns(address);
    function getCurrentAdmin() external view returns(address);
    function updatePairLogic(address _logic) external;
    function updateCurrentAdmin(address _newAdmin) external;
    function updateProxyPair(address _proxy) external;
    function setAdminForProxy(address _proxy) external;
}