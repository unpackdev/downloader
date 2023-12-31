// SPDX-License-Identifier: BUSL-1.1
pragma solidity 0.8.17;

interface IYearnTokenVault {
    function balanceOf(address account) external view returns (uint256);

    function decimals() external view returns (uint256);

    function pricePerShare() external view returns (uint256);

    function token() external view returns (address);

    function totalAssets() external view returns (uint256);

    function deposit(uint256 _amount) external returns (uint256);

    function withdraw(uint256 maxShares, address recipient, uint256 maxLoss) external returns (uint256);
}
