// SPDX-License-Identifier: MIT

pragma solidity 0.8.21;

interface IAccessManagerUpgradeable {
    function admin() external view returns (address);

    function changeAdmin(address newAdmin_) external;
}
