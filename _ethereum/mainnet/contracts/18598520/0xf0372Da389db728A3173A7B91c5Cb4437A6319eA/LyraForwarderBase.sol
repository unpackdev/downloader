// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

import "./IERC20.sol";
import "./ILightAccountFactory.sol";

/**
 * @title  LyraForwarderBase
 * @notice Shared logic for both self-paying and sponsored forwarder
 */
abstract contract LyraForwarderBase {
    // keccak256("ReceiveWithAuthorization(address from,address to,uint256 value,uint256 validAfter,uint256 validBefore,bytes32 nonce)")
    bytes32 public constant RECEIVE_WITH_AUTHORIZATION_TYPEHASH =
        0xd099cc98ef71107a616c4f0f941f04c322d8e254fe26b3c6668db87aae413de8;

    ///@dev L1 USDC address.
    address public immutable usdcLocal;

    ///@dev SocketVault address.
    address public immutable socketVault;

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
        address _socketVault
    ) {
        usdcLocal = _usdcLocal;
        socketVault = _socketVault;
        
        IERC20(_usdcLocal).approve(_socketVault, type(uint256).max);
    }

    /**
     * @dev Get the recipient address based on isSCW flag
     * @param sender The real sender of the transaction
     * @param isSCW  True if the sender wants to deposit to smart contract wallet
     */
    function _getL2Receiver(address sender, bool isSCW) internal view returns (address) {
        if (isSCW) {
            return ILightAccountFactory(lightAccountFactory).getAddress(sender, 0);
        } else {
            return sender;
        }
    }
}
