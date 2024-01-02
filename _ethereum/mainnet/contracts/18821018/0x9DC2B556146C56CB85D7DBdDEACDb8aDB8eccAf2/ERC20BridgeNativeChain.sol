// SPDX-License-Identifier: AGPL-3.0

pragma solidity 0.8.17;

import "./PolygonERC20BridgeBase.sol";
import "./IERC20.sol";
import "./SafeERC20.sol";

/**
 * ERC20BridgeNativeChain is an example contract to use the message layer of the PolygonZkEVMBridge to bridge custom ERC20
 * This contract will be deployed on the native erc20 network (usually will be mainnet)
 */
contract ERC20BridgeNativeChain is PolygonERC20BridgeBase {
    using SafeERC20 for IERC20;

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
        PolygonERC20BridgeBase(
            _polygonZkEVMBridge,
            _counterpartContract,
            _counterpartNetwork
        )
    {}

    /**
     * @dev Handle the reception of the tokens
     * @param tokenAddress Token address
     * @param amount Token amount
     */
    function _receiveTokens(address tokenAddress, uint256 amount) internal override {
        IERC20 token = IERC20(tokenAddress);

        token.safeTransferFrom(msg.sender, address(this), amount);
    }

    /**
     * @dev Handle the transfer of the tokens
     * @param tokenAddress Token address
     * @param destinationAddress Address destination that will receive the tokens on the other network
     * @param amount Token amount
     */
    function _transferTokens(
        address tokenAddress,
        address destinationAddress,
        uint256 amount
    ) internal override {
        IERC20 token = IERC20(tokenAddress);

        token.safeTransfer(destinationAddress, amount);
    }
}
