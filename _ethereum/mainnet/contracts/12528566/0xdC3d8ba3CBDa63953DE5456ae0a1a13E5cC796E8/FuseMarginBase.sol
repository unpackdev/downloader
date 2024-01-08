// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.7.6;

import "./IFuseMarginV1.sol";
import "./IFuseMarginController.sol";
import "./IOwnable.sol";
import "./IERC20.sol";

/// @author Ganesh Gautham Elango
/// @title FuseMargin contract base
abstract contract FuseMarginBase is IFuseMarginV1 {
    /// @dev FuseMarginController contract
    IFuseMarginController public immutable override fuseMarginController;

    /// @param _fuseMarginController FuseMarginController address
    constructor(address _fuseMarginController) {
        fuseMarginController = IFuseMarginController(_fuseMarginController);
    }

    /// @dev Transfers token balance
    /// @param token Token address
    /// @param to Transfer to address
    /// @param amount Amount to transfer
    function transferToken(
        address token,
        address to,
        uint256 amount
    ) external {
        require(msg.sender == IOwnable(address(fuseMarginController)).owner(), "FuseMarginV1: Not owner of controller");
        IERC20(token).transfer(to, amount);
    }
}
