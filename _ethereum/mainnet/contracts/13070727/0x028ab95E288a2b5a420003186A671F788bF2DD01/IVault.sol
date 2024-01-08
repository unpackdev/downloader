// SPDX-License-Identifier: No License

pragma solidity ^0.8.0;

interface IVault {
    function getTotalDebt(address _asset, address _user) external view returns (uint256 _totalDebt);
    function collaterals(address _asset, address _user) external view returns (uint256 _totalCollateral);
}
