// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;
import "./IERC20Upgradeable.sol";

interface ArbitrumEnabledToken {
    /// Should return `0xb1` if token is enabled for arbitrum gateways
    function isArbitrumEnabled() external view returns (uint8);
}

/**
 * @title Minimum expected interface for an L1 custom token
 */
interface IGFlyL1 is ArbitrumEnabledToken, IERC20Upgradeable {
    /**
     * Should make an external call to L2GatewayRouter.setGateway and probably L1CustomGateway.registerTokenToL2
     * @param l2CustomTokenAddress address of the custom token on L2
     * @param maxSubmissionCostForCustomBridge max gas deducted from user's L2 balance to cover submission fee for registerTokenToL2
     * @param maxSubmissionCostForRouter max gas deducted from user's L2 balance to cover submission fee for setGateway
     * @param maxGasForCustomBridge max gas deducted from user's L2 balance to cover L2 execution of registerTokenToL2
     * @param maxGasForRouter max gas deducted from user's L2 balance to cover L2 execution of setGateway
     * @param gasPriceBid gas price for L2 execution
     * @param valueForGateway callvalue sent on call to registerTokenToL2
     * @param valueForRouter callvalue sent on call to setGateway
     * @param creditBackAddress address for crediting back overpayment of maxSubmissionCosts
     */
    function registerTokenOnL2(
        address l2CustomTokenAddress,
        uint256 maxSubmissionCostForCustomBridge,
        uint256 maxSubmissionCostForRouter,
        uint256 maxGasForCustomBridge,
        uint256 maxGasForRouter,
        uint256 gasPriceBid,
        uint256 valueForGateway,
        uint256 valueForRouter,
        address creditBackAddress
    ) external payable;

    /// @dev See {IERC20-transferFrom}
    function transferFrom(
        address sender,
        address recipient,
        uint256 amount
    ) external returns (bool);

    /// @dev See {IERC20-balanceOf}
    function balanceOf(address account) external view returns (uint256);

    /**
    * Should increase token supply by amount, and should only be callable by the L1 gateway.
     * @param account Account to be credited with the tokens in the L2
     * @param amount Token amount
     */
    function bridgeMint(address account, uint256 amount) external;

    /**
     * Should decrease token supply by amount.
     * @param account Account whose tokens will be burned in the L2, to be released on L1
     * @param amount Token amount
     */
    function bridgeBurn(address account, uint256 amount) external;
}