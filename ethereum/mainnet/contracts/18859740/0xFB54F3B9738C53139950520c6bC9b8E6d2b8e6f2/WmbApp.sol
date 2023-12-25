// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./AccessControl.sol";
import "./Initializable.sol";
import "./IWmbGateway.sol";
import "./IWmbReceiver.sol";

/**
 * @title WmbApp
 * @dev Abstract contract to be inherited by applications to use Wanchain Message Bridge for send and receive messages between different chains.
 * All interfaces with WmbGateway have been encapsulated, so users do not need to have any interaction with the WmbGateway contract.
 */
abstract contract WmbApp is AccessControl, Initializable, IWmbReceiver {
    // The address of the WMB Gateway contract
    address public wmbGateway;

    // A mapping of remote chains and addresses that are trusted to send messages to this contract
    // fromChainId => fromAddress => trusted
    mapping (uint => mapping(address => bool)) public trustedRemotes;

    /**
     * @dev Initializes the contract with the given admin, WMB Gateway address, and block mode flag
     * @param admin Address of the contract admin
     * @param _wmbGateway Address of the WMB Gateway contract
     */
    function initialize(address admin, address _wmbGateway) virtual public initializer {
        // Initialize the AccessControl module with the given admin
        _grantRole(DEFAULT_ADMIN_ROLE, admin);
        wmbGateway = _wmbGateway;
    }

    /**
     * @dev Function to set the trusted remote addresses
     * @param fromChainIds IDs of the chains the messages are from
     * @param froms Addresses of the contracts the messages are from
     * @param trusted Trusted flag
     * @notice This function can only be called by the admin
     */
    function setTrustedRemotes(uint[] calldata fromChainIds, address[] calldata froms, bool[] calldata trusted) external {
        require(hasRole(DEFAULT_ADMIN_ROLE, msg.sender), "WmbApp: must have admin role to set trusted remotes");
        require(fromChainIds.length == froms.length && froms.length == trusted.length, "WmbApp: invalid input");
        for (uint i = 0; i < fromChainIds.length; i++) {
            trustedRemotes[fromChainIds[i]][froms[i]] = trusted[i];
        }
    }

    /**
     * @dev Function to estimate fee in native coin for sending a message to the WMB Gateway
     * @param toChain ID of the chain the message is to
     * @param gasLimit Gas limit for the message
     * @return fee Fee in native coin
     */
    function estimateFee(uint256 toChain, uint256 gasLimit) virtual public view returns (uint256) {
        return IWmbGateway(wmbGateway).estimateFee(toChain, gasLimit);
    }

    /**
     * @dev Function to receive a WMB message from the WMB Gateway
     * @param data Message data
     * @param messageId Message ID
     * @param fromChainId ID of the chain the message is from
     * @param from Address of the contract the message is from
     */
    function wmbReceive(
        bytes calldata data,
        bytes32 messageId,
        uint256 fromChainId,
        address from
    ) virtual external {
        // Only the WMB gateway can call this function
        require(msg.sender == wmbGateway, "WmbApp: Only WMB gateway can call this function");
        require(trustedRemotes[fromChainId][from], "WmbApp: Remote is not trusted");
        _wmbReceive(data, messageId, fromChainId, from);
    }

    /**
     * @dev Function to be implemented by the application to handle received WMB messages
     * @param data Message data
     * @param messageId Message ID
     * @param fromChainId ID of the chain the message is from
     * @param from Address of the contract the message is from
     */
    function _wmbReceive(
        bytes calldata data,
        bytes32 messageId,
        uint256 fromChainId,
        address from
    ) virtual internal;

    /**
     * @dev Function to send a WMB message to the WMB Gateway from this App
     * @param toChainId ID of the chain the message is to
     * @param to Address of the contract the message is to
     * @param data Message data
     * @return messageId Message ID
     */
    function _dispatchMessage(
        uint toChainId,
        address to,
        bytes memory data,
        uint fee
    ) virtual internal returns (bytes32) {
        return IWmbGateway(wmbGateway).dispatchMessage{value: fee}(toChainId, to, data);
    }

    /**
     * @dev Function to send batch WMB messages to the WMB Gateway from this App
     * @param toChainId ID of the chain the message is to
     * @param messages Messages data
     * @return messageId Message ID
     */
    function _dispatchMessageBatch(uint256 toChainId, Message[] memory messages, uint fee) virtual internal returns (bytes32) {
        return IWmbGateway(wmbGateway).dispatchMessageBatch{value: fee}(toChainId, messages);
    }
}
