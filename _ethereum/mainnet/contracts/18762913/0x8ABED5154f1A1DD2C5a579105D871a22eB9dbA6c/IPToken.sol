// SPDX-License-Identifier: MIT

pragma solidity ^0.8.19;

import "./IERC20.sol";

/**
 * @title IPToken
 * @author pNetwork
 *
 * @notice
 */
interface IPToken is IERC20 {
    /*
     * @notice Burn the corresponding `amount` of pToken and release the collateral.
     *
     * @param amount
     */
    function burn(uint256 amount) external;

    /*
     * @notice Take the collateral and mint the corresponding `amount` of pToken to `msg.sender`.
     *
     * @param amount
     */
    function mint(uint256 amount) external;

    /*
     * @notice Burn the corresponding `amount` of pToken through the PNetworkHub to `account` and release the collateral.
     *
     * @param account
     * @param amount
     */
    function protocolBurn(address account, uint256 amount) external;

    /*
     * @notice Mint the corresponding `amount` of pToken through the PNetworkHub to `account`.
     *
     * @param account
     * @param amount
     */
    function protocolMint(address account, uint256 amount) external;

    function underlyingAssetDecimals() external returns (uint256);

    function underlyingAssetName() external returns (string memory);

    function underlyingAssetNetworkId() external returns (bytes4);

    function underlyingAssetSymbol() external returns (string memory);

    function underlyingAssetTokenAddress() external returns (address);

    /*
     * @notice Burn the corresponding `amount` of pToken through the PRouter in behalf of `account` and release the.
     *
     * @param account
     * @param amount
     */
    function userBurn(address account, uint256 amount) external;

    /*
     * @notice Take the collateral and mint the corresponding `amount` of pToken through the PRouter to `account`.
     *
     * @param account
     * @param amount
     */
    function userMint(address account, uint256 amount) external;

    /*
     * @notice Take the collateral, mint and burn the corresponding `amount` of pToken through the PRouter to `account`.
     *
     * @param account
     * @param amount
     */
    function userMintAndBurn(address account, uint256 amount) external;
}
