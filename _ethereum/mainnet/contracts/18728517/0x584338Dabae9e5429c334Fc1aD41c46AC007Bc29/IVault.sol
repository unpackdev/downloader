// SPDX-License-Identifier: GPL-3.0
pragma solidity 0.8.15;

interface IVault {
    function deposit(uint256 _amount) external;

    function withdraw(uint256 _amount) external view;

    function getTotalDeposits() external view returns (uint256);

    function getPrincipalDeposits() external view returns (uint256);

    function migrate(bytes calldata _data) external;

    function upgradeToAndCall(address _newImplementation, bytes memory _data) external;

    function upgradeTo(address _newImplementation) external;
}
