// @unsupported: ovm
// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity 0.7.6;
pragma abicoder v2;

import "./IERC20.sol";
import "./iOVM_L1StandardBridge.sol";

import "./L1_NovaExecutionManager.sol";

contract FuseStrategy {
    L1_NovaExecutionManager constant executionManager = L1_NovaExecutionManager(0xb5b64C2216a134F3731D66acAce03C7E221AFA2d);
    iOVM_L1StandardBridge constant bridge = iOVM_L1StandardBridge(0x99C9fc46f92E8a1c0deC1b1747d010903E884bE1);

    function registerSelf() external {
        // It's okay that people can call this multiple times, all calls after the first will revert.
        executionManager.registerSelfAsStrategy(L1_NovaExecutionManager.StrategyRiskLevel.UNSAFE);
    }

    function depositIntoFuseAndSendToL2(
        CERC20 cToken,
        uint256 underlyingAmount,
        address l2Token,
        address l2Recipient
    ) external {
        // Transfer underlying from relayer.
        address underlying = cToken.underlying();
        executionManager.transferFromRelayer(underlying, underlyingAmount);

        // Approve to and mint cToken.
        IERC20(underlying).approve(address(cToken), underlyingAmount);
        require(cToken.mint(underlyingAmount) == 0, "MINT_FAILED");

        // Get our balance of the cToken.
        uint256 cTokenAmount = cToken.balanceOf(address(this));

        // Approve and send the cToken to L2.
        cToken.approve(address(bridge), cTokenAmount);
        bridge.depositERC20To(address(cToken), l2Token, l2Recipient, cTokenAmount, 1500000, new bytes(0));
    }
}

interface CERC20 {
    function balanceOf(address owner) external view returns (uint256);

    function approve(address spender, uint256 amount) external returns (bool);

    function mint(uint256 mintAmount) external returns (uint256);

    function underlying() external view returns (address);
}
