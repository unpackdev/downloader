// SPDX-License-Identifier: MIT
pragma solidity 0.8.19;

interface IArbToken {
    /**
     * @notice should increase token supply by amount, and should (probably) only be callable by the L1 bridge.
     */
    function bridgeMint(address account, uint256 amount) external;

    /**
     * @notice should decrease token supply by amount, and should (probably) only be callable by the L1 bridge.
     */
    function bridgeBurn(address account, uint256 amount) external;

    /**
     * @return address of layer 1 token
     */
    function l1Address() external view returns (address);
}

interface ArbitrumEnabledToken {
    /// @notice should return `0xb1` if token is enabled for arbitrum gateways
    function isArbitrumEnabled() external view returns (uint8);
}

/**
 * @title Minimum expected interface for L1 custom token
 */
interface ICustomToken is ArbitrumEnabledToken {
    /**
     * @notice Should make an external call to L1CustomGateway.registerTokenToL2 and L2GatewayRouter.setGateway
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

    function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);

    function balanceOf(address account) external view returns (uint256);
}

interface L1MintableToken is ICustomToken {
    function bridgeMint(address account, uint256 amount) external;
}

interface L1ReverseToken is L1MintableToken {
    function bridgeBurn(address account, uint256 amount) external;
}

/**
 * @title Interface needed to call function registerTokenToL2 of the L1CustomGateway
 */
interface IL1CustomGateway {
    function registerTokenToL2(
        address _l2Address,
        uint256 _maxGas,
        uint256 _gasPriceBid,
        uint256 _maxSubmissionCost,
        address _creditBackAddress
    ) external payable returns (uint256);
}

interface IL1GatewayRouter {
    function setGateway(address _gateway, uint256 _maxGas, uint256 _gasPriceBid, uint256 _maxSubmissionCost, address _creditBackAddress) external payable returns (uint256);
}
