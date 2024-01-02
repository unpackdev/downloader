// SPDX-License-Identifier: GPL-3.0
// Docgen-SOLC: 0.8.15

pragma solidity ^0.8.15;

import "./IERC4626Upgradeable.sol";
import "./SafeERC20Upgradeable.sol";
import "./IVaultRegistry.sol";
import "./ICurveGauge.sol";

/**
 * @title   VaultRouter
 * @author  RedVeil
 * @notice
 *
 */
contract VaultRouter {
    using SafeERC20 for IERC20;

    constructor() {}

    function depositAndStake(
        IERC4626 vault,
        ICurveGauge gauge,
        uint256 assetAmount,
        address receiver
    ) external {
        IERC20 asset = IERC20(vault.asset());
        asset.safeTransferFrom(msg.sender, address(this), assetAmount);
        asset.safeApprove(address(vault), assetAmount);

        uint256 shares = vault.deposit(assetAmount, address(this));

        vault.approve(address(gauge), shares);
        gauge.deposit(shares, receiver);
    }

    function unstakeAndWithdraw(
        IERC4626 vault,
        ICurveGauge gauge,
        uint256 burnAmount,
        address receiver
    ) external {
        IERC20(address(gauge)).safeTransferFrom(msg.sender, address(this), burnAmount);

        gauge.withdraw(burnAmount);

        vault.redeem(burnAmount, receiver, address(this));
    }
}
