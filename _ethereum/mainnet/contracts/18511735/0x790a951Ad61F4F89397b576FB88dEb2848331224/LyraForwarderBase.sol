// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

import "./IERC20.sol";
import "./ILightAccountFactory.sol";

/**
 * @title  LyraForwarder
 * @notice This contract help onboarding users with only USDC in their wallet to our custom rollup, with help of Gelato Relayer
 * @dev    All functions use _msgSender() to be compatible with ERC2771.
 *         Users never have to approve USDC to this contract, we use receiveWithAuthorization to save gas on USDC
 */
abstract contract LyraForwarderBase {
    // keccak256("ReceiveWithAuthorization(address from,address to,uint256 value,uint256 validAfter,uint256 validBefore,bytes32 nonce)")
    bytes32 public constant RECEIVE_WITH_AUTHORIZATION_TYPEHASH =
        0xd099cc98ef71107a616c4f0f941f04c322d8e254fe26b3c6668db87aae413de8;

    ///@dev L1 USDC address.
    address public immutable usdcLocal;

    ///@dev L2 USDC address.
    address public immutable usdcRemote;

    ///@dev L1StandardBridge address.
    address public immutable standardBridge;

    ///@dev SocketVault address.
    // address public immutable socketVault;

    ///@dev SocketConnector address.
    // address public immutable socketConnector;

    ///@dev Light Account factory address.
    ///     See this script for more info https://github.com/alchemyplatform/light-account/blob/main/script/Deploy_LightAccountFactory.s.sol
    address public constant lightAccountFactory = 0x000000893A26168158fbeaDD9335Be5bC96592E2;

    struct ReceiveWithAuthData {
        uint256 value;
        uint256 validAfter;
        uint256 validBefore;
        bytes32 nonce;
        uint8 v;
        bytes32 r;
        bytes32 s;
    }

    constructor(
        address _usdcLocal,
        address _usdcRemote,
        address _l1standardBridge
        // address _socketVault,
        // address _socketConnector
    ) {
        usdcLocal = _usdcLocal;
        usdcRemote = _usdcRemote;
        standardBridge = _l1standardBridge;
        // socketVault = _socketVault;
        // socketConnector = _socketConnector;

        IERC20(_usdcLocal).approve(_l1standardBridge, type(uint256).max);
        // IERC20(_usdcLocal).approve(_socketVault, type(uint256).max);
    }

    // /**
    //  * @dev Get the recipient address based on isSCW flag
    //  * @param sender The real sender of the transaction
    //  * @param isSCW  True if the sender wants to deposit to smart contract wallet
    //  */
    // function _getL2Receiver(address sender, bool isSCW) internal view returns (address) {
    //     if (isSCW) {
    //         return ILightAccountFactory(lightAccountFactory).getAddress(sender, 0);
    //     } else {
    //         return sender;
    //     }
    // }
}
