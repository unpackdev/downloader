// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity 0.8.19;

import "./ILiquidityGauge.sol";
import "./ERC20.sol";
import "./SafeTransferLib.sol";

/// @title RewardHandler
/// @notice Contract receiving rewards from Booster contract and forwarding them to the right contracts.
/// @author StakeDAO
/// @custom:contact contact@stakedao.org
contract RewardHandler {
    /// @notice Address of the governance.
    address public governance;

    /// @notice Address of the future governance contract.
    address public futureGovernance;

    /// @notice Mapping of handlers.
    mapping(address => bool) public canPullTokens;

    /// @notice Throws if caller is not the governance.
    error GOVERNANCE();

    /// @notice Error emitted when auth failed
    error UNAUTHORIZED();

    /// @notice Event emitted when governance is changed.
    /// @param newGovernance Address of the new governance.
    event GovernanceChanged(address indexed newGovernance);

    constructor() {
        governance = msg.sender;
    }

    modifier onlyGovernance() {
        if (msg.sender != governance) revert GOVERNANCE();
        _;
    }

    modifier onlyHandlers() {
        if (!canPullTokens[msg.sender]) revert UNAUTHORIZED();
        _;
    }

    /// @notice Pulls tokens from the contract.
    /// @param _tokens Array of token addresses to pull.
    /// @param _receiver Address of the receiver.
    function pullTokens(address[] memory _tokens, address _receiver) external onlyHandlers {
        for (uint256 i = 0; i < _tokens.length; i++) {
            SafeTransferLib.safeTransfer(_tokens[i], _receiver, ERC20(_tokens[i]).balanceOf(address(this)));
        }
    }

    ////////////////////////////////////////////////////////////////
    /// --- GOVERNANCE
    ///////////////////////////////////////////////////////////////

    /// @notice Add a handler.
    /// @param _handler Address of the handler.
    function addHandler(address _handler) external onlyGovernance {
        canPullTokens[_handler] = true;
    }

    /// @notice Remove a handler.
    /// @param _handler Address of the handler.
    function removeHandler(address _handler) external onlyGovernance {
        canPullTokens[_handler] = false;
    }

    /// @notice Transfer the governance to a new address.
    /// @param _governance Address of the new governance.
    function transferGovernance(address _governance) external onlyGovernance {
        futureGovernance = _governance;
    }

    /// @notice Accept the governance transfer.
    function acceptGovernance() external {
        if (msg.sender != futureGovernance) revert GOVERNANCE();

        governance = msg.sender;

        futureGovernance = address(0);

        emit GovernanceChanged(msg.sender);
    }
}
