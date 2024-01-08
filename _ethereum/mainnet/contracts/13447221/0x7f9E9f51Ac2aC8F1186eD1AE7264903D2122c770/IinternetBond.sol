// SPDX-License-Identifier: GPL-3.0-only
pragma solidity ^0.8.6;

interface IinternetBond {

    function mintBonds(address account, uint256 amount) external;

    function burn(address account, uint256 amount) external;

    function pendingBurn(address account) external view returns (uint256);

    function lockForDelayedBurn(address account, uint256 amount) external;

    function commitDelayedBurn(address account, uint256 amount) external;

    function ratio() external view returns (uint256);
}
