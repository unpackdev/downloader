// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

import "./ERC2771Context.sol";
import "./LyraForwarderBase.sol";
import "./IL1StandardBridge.sol";
import "./ISocketVault.sol";
import "./IERC3009.sol";

/**
 * @title   LyraForwarder
 * @notice  Use this contract when we want to sponsor gas for users
 * @dev     Someone need to fund this contract with ETH to use Socket Bridge
 * @dev     All functions are public, EOAs can also use this contract to use receiveWithAuthorization to deposit USDC
 */
contract LyraSponsoredForwarder is LyraForwarderBase, ERC2771Context {
    /**
     * @dev GelatoRelay1BalanceERC2771 forwarder (0xd8253782c45a12053594b9deB72d8e8aB2Fca54c) is used for all non-zkSync-EVM
     */
    constructor(
        address _usdcLocal,
        address _socketVault
    )
        payable
        LyraForwarderBase(_usdcLocal, _socketVault)
        ERC2771Context(0xd8253782c45a12053594b9deB72d8e8aB2Fca54c)
    {}

    /**
     * @notice  Deposit user USDC to L2 through Socket fast bridge
     * @dev     Users never have to approve USDC to this contract, we use receiveWithAuthorization to save gas
     *
     * @param isScwWallet   True if user wants to deposit to default LightAccount on L2
     * @param minGasLimit   Minimum gas limit for the L2 execution
     * @param connector     Socket Connector
     * @param authData      Data and signatures for receiveWithAuthorization
     */
    function depositUSDCSocketBridge(bool isScwWallet, uint32 minGasLimit, address connector, ReceiveWithAuthData calldata authData)
        external
    {
        address msgSender = _msgSender();

        IERC3009(usdcLocal).receiveWithAuthorization(
            msgSender,
            address(this),
            authData.value,
            authData.validAfter,
            authData.validBefore,
            authData.nonce,
            authData.v,
            authData.r,
            authData.s
        );

        uint256 feeInWei = ISocketVault(socketVault).getMinFees(connector, minGasLimit);

        ISocketVault(socketVault).depositToAppChain{value: feeInWei}(
            _getL2Receiver(msgSender, isScwWallet), authData.value, minGasLimit, connector
        );
    }

    receive() external payable {}
}
