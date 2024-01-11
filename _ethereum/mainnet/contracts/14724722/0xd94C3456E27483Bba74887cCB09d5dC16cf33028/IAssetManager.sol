// SPDX-License-Identifier: MIT
pragma solidity 0.8.0;

interface IAssetManager {
    function isAvailableLoanAsset(address _asset) external returns (bool);

    function isAvailableCollateralAsset(address _asset) external returns (bool);

    function isValidAutomaticLoan(address _asset, uint256 _amountIn) external returns (bool);

    function requestETH(address _to, uint256 _amount) external;

    function requestToken(
        address _to,
        address _token,
        uint256 _amount
    ) external;

    function collectInstallment(
        address _currency,
        uint256 _amount,
        uint256 _interest,
        bool _collateral
    ) external payable;
}
