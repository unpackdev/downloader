// SPDX-License-Identifier: GPL-3.0

pragma solidity 0.8.17;

import "./IMintableBurnableERC20.sol";

interface IVaultFactory {
    function collateral() external view returns (IERC20);
    function token() external view returns (IMintableBurnableERC20);
    function feeManager() external view returns (address);

    function createVault(address) external returns (address);
    function getVault(address) external view returns (address);
    function allVaults(uint) external view returns (address);
    function isVault(address) external view returns (bool);
    function isVaultManager(address) external view returns (bool);
    function vaultsLength() external view returns (uint);
}
