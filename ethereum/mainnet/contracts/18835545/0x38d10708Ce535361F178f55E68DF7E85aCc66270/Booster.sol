// SPDX-License-Identifier: GPL-3.0
pragma solidity 0.8.19;

import "./ILiquidityGauge.sol";
import "./ERC20.sol";
import "./SafeTransferLib.sol";

/// @title Booster
/// @notice Contract that'll receive the boost from veSDT Delegators.
/// @author StakeDAO
/// @custom:contact contact@stakedao.org
contract Booster {
    /// @notice Address of the governance.
    address public governance;

    /// @notice Address of the future governance contract.
    address public futureGovernance;

    /// @notice Address of the reward handler receiver.
    address public rewardHandler;

    /// @notice Map addresses allowed to interact with the `execute` function.
    mapping(address => bool) public allowed;

    /// @notice Map addresses of vsdTokens allowed to withdraw.
    mapping(address => bool) public vsdTokens;

    /// @notice Throws if caller is not the governance.
    error GOVERNANCE();

    /// @notice Error emitted when auth failed
    error UNAUTHORIZED();

    /// @notice Error emitted when input address is null
    error ADDRESS_NULL();

    /// @notice Error emitted when trying to allow an EOA.
    error NOT_CONTRACT();

    /// @notice Event emitted when governance is changed.
    /// @param newGovernance Address of the new governance.
    event GovernanceChanged(address indexed newGovernance);

    constructor() {
        governance = msg.sender;
    }

    ////////////////////////////////////////////////////////////////
    /// --- MODIFIERS
    ///////////////////////////////////////////////////////////////

    modifier onlyVsdTokens() {
        if (!vsdTokens[msg.sender]) revert UNAUTHORIZED();
        _;
    }

    modifier onlyGovernance() {
        if (msg.sender != governance) revert GOVERNANCE();
        _;
    }

    modifier onlyGovernanceOrAllowed() {
        if (msg.sender != governance && !allowed[msg.sender]) revert UNAUTHORIZED();
        _;
    }

    /// @notice Withdrawal function for vsdTokens.
    /// @param _asset Address of the asset to withdraw.
    function withdraw(address _asset, uint256 _amount) external onlyVsdTokens {
        SafeTransferLib.safeTransfer(_asset, msg.sender, _amount);
    }

    /// @notice Claim rewards for a gauge and send them to the reward handler.
    /// @param _asset Address of the gauge.
    function claim(address _asset) external {
        if (rewardHandler == address(0)) revert ADDRESS_NULL();

        ILiquidityGauge(_asset).claim_rewards(address(this), rewardHandler);
    }

    /// @notice Claim rewards for many gauges and send them to the reward handler.
    /// @param _assets Array of addresses of the gauges.
    function claimMany(address[] calldata _assets) external {
        if (rewardHandler == address(0)) revert ADDRESS_NULL();

        for (uint256 i = 0; i < _assets.length; i++) {
            ILiquidityGauge(_assets[i]).claim_rewards(address(this), rewardHandler);
        }
    }

    //////////////////////////////////////////////////////
    /// --- GOVERNANCE OR ALLOWED FUNCTIONS
    //////////////////////////////////////////////////////

    /// @notice Set the reward handler.
    /// @param _rewardHandler Address of the reward handler.
    function setRewardHandler(address _rewardHandler) external onlyGovernance {
        rewardHandler = _rewardHandler;
    }

    /// @notice Allow a module to interact with the `execute` function.
    /// @dev excodesize can be bypassed but whitelist should go through governance.
    function addVsdToken(address _vsdToken) external onlyGovernance {
        vsdTokens[_vsdToken] = true;
    }

    /// @notice Remove a module from the allowed list.
    function removeVsdToken(address _vsdToken) external onlyGovernance {
        vsdTokens[_vsdToken] = false;
    }

    /// @notice Allow a module to interact with the `execute` function.
    /// @dev excodesize can be bypassed but whitelist should go through governance.
    function allowAddress(address _address) external onlyGovernance {
        if (_address == address(0)) revert ADDRESS_NULL();

        /// Check if the address is a contract.
        int256 size;
        assembly {
            size := extcodesize(_address)
        }
        if (size == 0) revert NOT_CONTRACT();

        allowed[_address] = true;
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

    /// @notice Execute a function.
    /// @param to Address of the contract to execute.
    /// @param value Value to send to the contract.
    /// @param data Data to send to the contract.
    /// @return success_ Boolean indicating if the execution was successful.
    /// @return result_ Bytes containing the result of the execution.
    function execute(address to, uint256 value, bytes calldata data)
        external
        onlyGovernanceOrAllowed
        returns (bool, bytes memory)
    {
        (bool success, bytes memory result) = to.call{value: value}(data);
        return (success, result);
    }
}
