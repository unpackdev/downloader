// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.7.6;

import "./IERC20.sol";

/**
 * Minimal xAsset interface
 * Only mintWithToken and burn functions
 */
interface IxAsset is IERC20 {
    /*
     * @dev Mint xAsset using Asset
     * @notice Must run ERC20 approval first
     * @param amount: Asset amount to contribute
     */
    function mintWithToken(uint256 amount) external;

    /*
     * @dev Burn xAsset tokens
     * @notice Will fail if redemption value exceeds available liquidity
     * @param amount: xAsset amount to redeem
     * @param redeemForEth: if true, redeem xAsset for ETH
     * @param minRate: Kyber.getExpectedRate xAsset=>ETH if redeemForEth true (no-op if false)
     */
    function burn(uint256 amount, bool redeemForEth, uint256 minRate) external;
}
