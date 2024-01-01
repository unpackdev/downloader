// SPDX-License-Identifier: GPL-3.0

pragma solidity ^0.8.19;

/**
 * @title Root-Chain Gauge CCIP Transfer
 * @author DFX Finance
 * @notice Receives total allocated weekly DFX emission mints and sends to L2 gauge via sender contract
 */
import "IERC20.sol";
import "Initializable.sol";
import "ICcipSender.sol";

contract CcipRootGauge is Initializable {
    // The name of the gauge
    string public name;
    // The symbole of the gauge
    string public symbol;
    // The start time (in seconds since Unix epoch) of the current period
    uint256 public startEpochTime;

    // The address of the DFX reward token
    address public immutable DFX;
    // The address of the CCIP Sender
    ICcipSender sender;
    // The address of the rewards distributor on the mainnet (source chain)
    address public distributor;

    // The address with administrative privileges over this contract
    address public admin;

    /// @dev Modifier that checks whether the msg.sender is admin
    modifier onlyAdmin() {
        require(msg.sender == admin, "Not admin");
        _;
    }

    /// @dev Modifier that checks whether the msg.sender is the distributor contract address
    modifier onlyDistributor() {
        require(msg.sender == distributor, "Not distributor");
        _;
    }

    /// @notice Contract constructor
    /// @param _DFX Address of the DFX token
    constructor(address _DFX) initializer {
        require(_DFX != address(0), "Token cannot be zero address");
        DFX = _DFX;
    }

    /// @notice Contract initializer
    /// @param _name Gauge base symbol
    /// @param _symbol Gauge base symbol
    /// @param _distributor Address of the mainnet rewards distributor
    /// @param _sender Address of the CCIP message sender
    /// @param _admin Admin who can kill the gauge
    function initialize(
        string memory _name,
        string memory _symbol,
        address _distributor,
        address _sender,
        address _admin
    ) external initializer {
        name = string(abi.encodePacked("DFX ", _name, " Root Gauge"));
        symbol = string(abi.encodePacked(_symbol, "-gauge"));

        distributor = _distributor;
        sender = ICcipSender(_sender);
        admin = _admin;
    }

    /* Gauge actions */
    /// @notice Send reward tokens to the L2 gauge.
    /// @dev This function approves the router to spend DFX tokens, calculates fees, and triggers a cross-chain token send.
    /// @param _amount Amount of DFX tokens to send as reward.
    /// @return bytes32 ID of the CCIP message that was sent.
    function _notifyReward(uint256 _amount) internal returns (bytes32) {
        startEpochTime = block.timestamp;

        // Max approve spending of rewards tokens by sender
        if (IERC20(DFX).allowance(address(this), address(sender)) < _amount) {
            IERC20(DFX).approve(address(sender), type(uint256).max);
        }

        return sender.relayReward(_amount);
    }

    function notifyReward(uint256 _amount) external onlyDistributor returns (bytes32) {
        bytes32 messageId = _notifyReward(_amount);
        return messageId;
    }

    function notifyReward(address, uint256 _amount) external onlyDistributor returns (bytes32) {
        bytes32 messageId = _notifyReward(_amount);
        return messageId;
    }

    /* Admin */
    /// @notice Set a new admin for the contract.
    /// @dev Only callable by the current admin.
    /// @param _newAdmin Address of the new admin.
    function updateAdmin(address _newAdmin) external onlyAdmin {
        admin = _newAdmin;
    }

    /// @notice Set a new reward distributor.
    /// @dev Only callable by the current admin.
    /// @param _newDistributor Reward distributor on source chain.
    function setDistributor(address _newDistributor) external onlyAdmin {
        distributor = _newDistributor;
    }
}
