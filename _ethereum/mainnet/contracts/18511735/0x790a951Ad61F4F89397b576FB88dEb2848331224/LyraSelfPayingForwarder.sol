// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

import "./GelatoRelayContextERC2771.sol";

import "./LyraForwarderBase.sol";

import "./IL1StandardBridge.sol";
import "./ISocketVault.sol";

import "./IERC3009.sol";

/**
 * @title  LyraSelfPayingForwarder
 * @notice Use this contract to allow gasless transactions, but users pay for their own gas with ERC20s
 * @dev    This contract can only be called by GELATO_RELAY_ERC2771 or GELATO_RELAY_CONCURRENT_ERC2771
 */
contract LyraSelfPayingForwarder is LyraForwarderBase, GelatoRelayContextERC2771 {
    constructor(
        address _usdcLocal,
        address _usdcRemote,
        address _bridge
        // address _socketVault,
        // address _socketConnector
    )
        payable
        LyraForwarderBase(_usdcLocal, _usdcRemote, _bridge
        // , _socketVault, 
        // _socketConnector
        )
        GelatoRelayContextERC2771()
    {}

    /**
     * @notice Deposit USDC to L2
     * @dev Users never have to approve USDC to this contract, we use receiveWithAuthorization to save gas
     * @param l2Receiver    Address of the receiver on L2
     * @param minGasLimit   Minimum gas limit for the L2 execution
     */
    function depositUSDCNativeBridge(
        uint256 maxERC20Fee,
        address l2Receiver,
        uint32 minGasLimit,
        ReceiveWithAuthData calldata authData
    ) external onlyGelatoRelayERC2771 {
        // step 1: receive USDC from user to this contract
        IERC3009(usdcLocal).receiveWithAuthorization(
            _getMsgSender(),
            address(this),
            authData.value,
            authData.validAfter,
            authData.validBefore,
            authData.nonce,
            authData.v,
            authData.r,
            authData.s
        );

        _transferRelayFeeCapped(maxERC20Fee);

        uint256 remaining = authData.value - _getFee();

        // step 3: call bridge to L2
        IL1StandardBridge(standardBridge).bridgeERC20To(usdcLocal, usdcRemote, l2Receiver, remaining, minGasLimit, "");
    }

    // /**
    //  * @notice Deposit USDC to L2 through other socket fast bridge. Gas is paid in USDC
    //  */
    // function depositUSDCSocketBridge(
    //     uint256 maxERC20Fee,
    //     address l2Receiver,
    //     uint32 minGasLimit,
    //     ReceiveWithAuthData calldata authData
    // ) external onlyGelatoRelayERC2771 {
    //     // step 1: receive USDC from user to this contract
    //     IERC3009(usdcLocal).receiveWithAuthorization(
    //         _getMsgSender(),
    //         address(this),
    //         authData.value,
    //         authData.validAfter,
    //         authData.validBefore,
    //         authData.nonce,
    //         authData.v,
    //         authData.r,
    //         authData.s
    //     );

    //     _transferRelayFeeCapped(maxERC20Fee);

    //     // pay gelato fee
    //     uint256 remaining = authData.value - _getFee();

    //     // pay socket protocol fee
    //     uint256 socketFee = ISocketVault(socketVault).getMinFees(socketConnector, minGasLimit);

    //     ISocketVault(socketVault).depositToAppChain{value: socketFee}(
    //         l2Receiver, remaining, minGasLimit, socketConnector
    //     );
    // }

    // receive() external payable {}
}
