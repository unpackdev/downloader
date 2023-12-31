// SPDX-License-Identifier: MIT
pragma solidity 0.8.20;

import "./ISquidDepositService.sol";
import "./ISquidMulticall.sol";
import "./IAxelarGateway.sol";
import "./IERC20.sol";
import "./SafeERC20.sol";
import "./Upgradable.sol";
import "./DepositReceiver.sol";
import "./ReceiverImplementation.sol";

/// @dev This should be owned by the microservice that is paying for gas.
contract SquidDepositService is Upgradable, ISquidDepositService {
    using SafeERC20 for IERC20;

    // This public storage is for ERC20 token intended to be refunded.
    // It triggers the DepositReceiver/ReceiverImplementation to switch into a refund mode.
    // Address is stored and deleted withing the same refund transaction.
    address public refundToken;

    address private constant nativeCoin = 0xEeeeeEeeeEeEeeEeEeEeeEEEeeeeEeeeeeeeEEeE;
    address immutable gateway;
    address public immutable refundIssuer;
    address public immutable receiverImplementation;

    constructor(address _router, address _gateway, address _refundIssuer) {
        if (_gateway == address(0) || _refundIssuer == address(0)) revert ZeroAddressProvided();

        gateway = _gateway;
        refundIssuer = _refundIssuer;
        receiverImplementation = address(new ReceiverImplementation(_router, _gateway));
    }

    function addressForBridgeCallDeposit(
        bytes32 salt,
        string calldata bridgedTokenSymbol,
        string calldata destinationChain,
        string calldata destinationAddress,
        bytes calldata payload,
        address refundRecipient,
        bool enableExpress
    ) external view returns (address) {
        return
            _depositAddress(
                salt,
                abi.encodeWithSelector(
                    ReceiverImplementation.receiveAndBridgeCall.selector,
                    bridgedTokenSymbol,
                    destinationChain,
                    destinationAddress,
                    payload,
                    refundRecipient,
                    enableExpress
                ),
                refundRecipient
            );
    }

    function addressForCallBridgeDeposit(
        bytes32 salt,
        address token,
        ISquidMulticall.Call[] calldata calls,
        string calldata bridgedTokenSymbol,
        string calldata destinationChain,
        string calldata destinationAddress,
        address refundRecipient
    ) external view returns (address) {
        return
            _depositAddress(
                salt,
                abi.encodeWithSelector(
                    ReceiverImplementation.receiveAndCallBridge.selector,
                    token,
                    calls,
                    bridgedTokenSymbol,
                    destinationChain,
                    destinationAddress,
                    refundRecipient
                ),
                refundRecipient
            );
    }

    function addressForCallBridgeCallDeposit(
        bytes32 salt,
        address token,
        ISquidMulticall.Call[] calldata calls,
        string calldata bridgedTokenSymbol,
        string calldata destinationChain,
        string calldata destinationAddress,
        bytes calldata payload,
        address refundRecipient,
        bool enableExpress
    ) external view returns (address) {
        return
            _depositAddress(
                salt,
                abi.encodeWithSelector(
                    ReceiverImplementation.receiveAndCallBridgeCall.selector,
                    token,
                    calls,
                    bridgedTokenSymbol,
                    destinationChain,
                    destinationAddress,
                    payload,
                    refundRecipient,
                    enableExpress
                ),
                refundRecipient
            );
    }

    function addressForFundAndRunMulticallDeposit(
        bytes32 salt,
        address token,
        ISquidMulticall.Call[] memory calls,
        address refundRecipient
    ) external view returns (address) {
        return
            _depositAddress(
                salt,
                abi.encodeWithSelector(
                    ReceiverImplementation.receiveAndFundAndRunMulticall.selector,
                    token,
                    calls,
                    refundRecipient
                ),
                refundRecipient
            );
    }

    function bridgeCallDeposit(
        bytes32 salt,
        string calldata bridgedTokenSymbol,
        string calldata destinationChain,
        string calldata destinationAddress,
        bytes calldata payload,
        address refundRecipient,
        bool enableExpress
    ) external {
        new DepositReceiver{salt: salt}(
            abi.encodeWithSelector(
                ReceiverImplementation.receiveAndBridgeCall.selector,
                bridgedTokenSymbol,
                destinationChain,
                destinationAddress,
                payload,
                refundRecipient,
                enableExpress
            ),
            refundRecipient
        );
    }

    function callBridgeDeposit(
        bytes32 salt,
        address token,
        ISquidMulticall.Call[] calldata calls,
        string calldata bridgedTokenSymbol,
        string calldata destinationChain,
        string calldata destinationAddress,
        address refundRecipient
    ) external {
        new DepositReceiver{salt: salt}(
            abi.encodeWithSelector(
                ReceiverImplementation.receiveAndCallBridge.selector,
                token,
                calls,
                bridgedTokenSymbol,
                destinationChain,
                destinationAddress,
                refundRecipient
            ),
            refundRecipient
        );
    }

    function callBridgeCallDeposit(
        bytes32 salt,
        address token,
        ISquidMulticall.Call[] calldata calls,
        string calldata bridgedTokenSymbol,
        string calldata destinationChain,
        string calldata destinationAddress,
        bytes calldata payload,
        address refundRecipient,
        bool express
    ) external {
        new DepositReceiver{salt: salt}(
            abi.encodeWithSelector(
                ReceiverImplementation.receiveAndCallBridgeCall.selector,
                token,
                calls,
                bridgedTokenSymbol,
                destinationChain,
                destinationAddress,
                payload,
                refundRecipient,
                express
            ),
            refundRecipient
        );
    }

    function fundAndRunMulticallDeposit(
        bytes32 salt,
        address token,
        ISquidMulticall.Call[] memory calls,
        address refundRecipient
    ) external {
        // NOTE: `DepositReceiver` is destroyed in the same runtime context that it is deployed.
        new DepositReceiver{salt: salt}(
            abi.encodeWithSelector(
                ReceiverImplementation.receiveAndFundAndRunMulticall.selector,
                token,
                calls,
                refundRecipient
            ),
            refundRecipient
        );
    }

    /// @dev Refunds ERC20 token from the deposit address if it doesn't match the intended token
    // Only refundRecipient can refund the token that was intended to go cross-chain (if not sent yet)
    function refundBridgeCallDeposit(
        bytes32 salt,
        string calldata bridgedTokenSymbol,
        string calldata destinationChain,
        string calldata destinationAddress,
        bytes calldata payload,
        address refundRecipient,
        bool express,
        address tokenToRefund
    ) external {
        address intendedToken = IAxelarGateway(gateway).tokenAddresses(bridgedTokenSymbol);
        // Allowing only the refundRecipient to refund the intended token
        if (tokenToRefund == intendedToken && msg.sender != refundRecipient) return;

        // Saving to public storage to be accessed by the DepositReceiver
        refundToken = tokenToRefund;

        new DepositReceiver{salt: salt}(
            abi.encodeWithSelector(
                ReceiverImplementation.receiveAndBridgeCall.selector,
                bridgedTokenSymbol,
                destinationChain,
                destinationAddress,
                payload,
                refundRecipient,
                express
            ),
            refundRecipient
        );

        refundToken = address(0);
    }

    function refundCallBridgeDeposit(
        bytes32 salt,
        address token,
        ISquidMulticall.Call[] calldata calls,
        string calldata bridgedTokenSymbol,
        string calldata destinationChain,
        string calldata destinationAddress,
        address refundRecipient,
        address tokenToRefund
    ) external {
        // Allowing only the refundRecipient to refund the intended token
        if (tokenToRefund == token && msg.sender != refundRecipient) return;

        // Saving to public storage to be accessed by the DepositReceiver
        refundToken = tokenToRefund;
        new DepositReceiver{salt: salt}(
            abi.encodeWithSelector(
                ReceiverImplementation.receiveAndCallBridge.selector,
                token,
                calls,
                bridgedTokenSymbol,
                destinationChain,
                destinationAddress,
                refundRecipient
            ),
            refundRecipient
        );

        refundToken = address(0);
    }

    function refundCallBridgeCallDeposit(
        bytes32 salt,
        address token,
        ISquidMulticall.Call[] calldata calls,
        string calldata bridgedTokenSymbol,
        string calldata destinationChain,
        string calldata destinationAddress,
        bytes calldata payload,
        address refundRecipient,
        bool express,
        address tokenToRefund
    ) external {
        // Allowing only the refundRecipient to refund the intended token
        if (tokenToRefund == token && msg.sender != refundRecipient) return;

        // Saving to public storage to be accessed by the DepositReceiver
        refundToken = tokenToRefund;
        new DepositReceiver{salt: salt}(
            abi.encodeWithSelector(
                ReceiverImplementation.receiveAndCallBridgeCall.selector,
                token,
                calls,
                bridgedTokenSymbol,
                destinationChain,
                destinationAddress,
                payload,
                refundRecipient,
                express
            ),
            refundRecipient
        );

        refundToken = address(0);
    }

    function refundFundAndRunMulticallDeposit(
        bytes32 salt,
        address token,
        ISquidMulticall.Call[] memory calls,
        address refundRecipient,
        address tokenToRefund
    ) external {
        // Allowing only the refundRecipient to refund the intended token
        if (tokenToRefund == token && msg.sender != refundRecipient) return;

        // Saving to public storage to be accessed by the DepositReceiver
        refundToken = tokenToRefund;
        new DepositReceiver{salt: salt}(
            abi.encodeWithSelector(
                ReceiverImplementation.receiveAndFundAndRunMulticall.selector,
                token,
                calls,
                refundRecipient
            ),
            refundRecipient
        );

        refundToken = address(0);
    }

    function refundLockedAsset(address receiver, address token, uint256 amount) external {
        if (msg.sender != refundIssuer) revert NotRefundIssuer();
        if (receiver == address(0)) revert ZeroAddressProvided();

        if (token == nativeCoin) {
            (bool sent, ) = receiver.call{value: amount}("");
            if (!sent) revert NativeTransferFailed();
        } else {
            IERC20(token).safeTransfer(receiver, amount);
        }
    }

    function _depositAddress(
        bytes32 salt,
        bytes memory delegateData,
        address refundRecipient
    ) private view returns (address) {
        /* Convert a hash which is bytes32 to an address which is 20-byte long
        according to https://docs.soliditylang.org/en/v0.8.9/control-structures.html?highlight=create2#salted-contract-creations-create2 */
        return
            address(
                uint160(
                    uint256(
                        keccak256(
                            abi.encodePacked(
                                bytes1(0xff),
                                address(this),
                                salt,
                                // Encoding delegateData and refundRecipient as constructor params
                                keccak256(
                                    abi.encodePacked(
                                        type(DepositReceiver).creationCode,
                                        abi.encode(delegateData, refundRecipient)
                                    )
                                )
                            )
                        )
                    )
                )
            );
    }

    function contractId() external pure returns (bytes32) {
        return keccak256("squid-deposit-service");
    }
}
