// SPDX-License-Identifier: UNLICENSED
pragma solidity >=0.8.18;

/**
 * @dev IComet source code https://etherscan.io/address/0xea270ca1b5133e58f935a035f3bc5da53975fa9c#code
 */
interface IComet {
    /* solhint-disable explicit-types */
    event Supply(address indexed from, address indexed dst, uint256 amount);
    event Withdraw(address indexed src, address indexed to, uint amount);

    event SupplyCollateral(address indexed from, address indexed dst, address indexed asset, uint amount);

    event WithdrawCollateral(address indexed src, address indexed to, address indexed asset, uint amount);

    function supply(address asset, uint amount) external;

    function withdraw(address asset, uint amount) external;

    function balanceOf(address account) external view returns (uint256);

    function borrowBalanceOf(address account) external view returns (uint256);

    function collateralBalanceOf(address account, address asset) external view returns (uint128);

    function getPrice(address priceFeed) external view returns (uint256);

    function getAssetInfoByAddress(
        address asset
    )
        external
        view
        returns (
            uint8 offset,
            address assetAddress,
            address priceFeed,
            uint64 scale,
            uint64 borrowCollateralFactor,
            uint64 liquidateCollateralFactor,
            uint64 liquidationFactor,
            uint128 supplyCap
        );

    /* solhint-disable explicit-types */
}
