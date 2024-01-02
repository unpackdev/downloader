// SPDX-License-Identifier: AGPL-3.0

pragma solidity 0.8.17;

import "./PolygonBridgeBase.sol";
import "./Ownable.sol";

/**
 * This contract contains the common logic to interact with the message layer of the bridge
 * to build a custom erc20 bridge. Is needed to deploy 1 contract on each layer that inherits
 * this base.
 */
abstract contract PolygonERC20BridgeBase is PolygonBridgeBase, Ownable {
    mapping(address => address) public associativeBridgeTokens; //// Token this network - token other network;

    //// Event when associative tokens added/changed
    event AssociativeTokens(address indexed currentNetworkTokenAddress, address indexed otherNetworkTokenAddress);

    /**
     * @param _polygonZkEVMBridge Polygon zkevm bridge address
     * @param _counterpartContract Couterpart contract
     * @param _counterpartNetwork Couterpart network
     */
    constructor(
        IPolygonZkEVMBridge _polygonZkEVMBridge,
        address _counterpartContract,
        uint32 _counterpartNetwork
    )
        PolygonBridgeBase(
            _polygonZkEVMBridge,
            _counterpartContract,
            _counterpartNetwork
        )
    {}

    /**
     * @dev Emitted when bridge tokens to the counterpart network
     */
    event BridgeTokens(address destinationAddress, uint256 amount);

    /**
     * @dev Emitted when claim tokens from the counterpart network
     */
    event ClaimTokens(address destinationAddress, uint256 amount);

    /**
     * @dev Handle for the configured associative tokens
     * @param currentNetworkTokenAddress Current network token address
     * @param otherNetworkTokenAddress Other network token address
     */
    function addAssociativeTokens(
        address currentNetworkTokenAddress,
        address otherNetworkTokenAddress
    ) external onlyOwner {
        require(associativeBridgeTokens[currentNetworkTokenAddress] == address(0), 'Token is associative');

        associativeBridgeTokens[currentNetworkTokenAddress] = otherNetworkTokenAddress;

        emit AssociativeTokens(currentNetworkTokenAddress, otherNetworkTokenAddress);
    }

    /**
     * @dev Handle for the change configured associative tokens
     * @param currentNetworkTokenAddress Current network token address
     * @param otherNetworkTokenAddress Other network token address
     */
    function changeAssociativeTokens(
        address currentNetworkTokenAddress,
        address otherNetworkTokenAddress
    ) external onlyOwner {
        require(associativeBridgeTokens[currentNetworkTokenAddress] != address(0), 'Current network token is not find');
        require(
            associativeBridgeTokens[currentNetworkTokenAddress] != otherNetworkTokenAddress,
            'Other network token equal is already set'
        );

        associativeBridgeTokens[currentNetworkTokenAddress] = otherNetworkTokenAddress;

        emit AssociativeTokens(currentNetworkTokenAddress, otherNetworkTokenAddress);
    }

    /**
     * @notice Send a message to the bridge that contains the destination address and the token amount
     * The parent contract should implement the receive token protocol and afterwards call this function
     * @param destinationAddress Address destination that will receive the tokens on the other network
     * @param amount Token amount
     * @param erc20TokenAddress Bridge token address
     * @param forceUpdateGlobalExitRoot Indicates if the global exit root is updated or not
     */
    function bridgeToken(
        address destinationAddress,
        uint256 amount,
        address erc20TokenAddress,
        bool forceUpdateGlobalExitRoot
    ) external {
        require(associativeBridgeTokens[erc20TokenAddress] != address(0), 'Token is not configured');

        _receiveTokens(erc20TokenAddress, amount);

        address _otherNetworkTokenAddress = associativeBridgeTokens[erc20TokenAddress];

        // Encode message data
        bytes memory messageData = abi.encode(destinationAddress, amount, _otherNetworkTokenAddress);

        // Send message data through the bridge
        _bridgeMessage(messageData, forceUpdateGlobalExitRoot);

        emit BridgeTokens(destinationAddress, amount);
    }

    /**
     * @notice Internal function triggered when receive a message
     * @param data message data containing the destination address and the token amount
     */
    function _onMessageReceived(bytes memory data) internal override {
        // Decode message data
        (address destinationAddress, uint256 amount, address otherNetworkTokenAddress) = abi.decode(
            data,
            (address, uint256, address)
        );

        _transferTokens(otherNetworkTokenAddress, destinationAddress, amount);
        emit ClaimTokens(destinationAddress, amount);
    }

    /**
     * @dev Handle the reception of the tokens
     * Must be implemented in parent contracts
     */
    function _receiveTokens(address tokenAddress, uint256 amount) internal virtual;

    /**
     * @dev Handle the transfer of the tokens
     * Must be implemented in parent contracts
     */
    function _transferTokens(
        address tokenAddress,
        address destinationAddress,
        uint256 amount
    ) internal virtual;
}
