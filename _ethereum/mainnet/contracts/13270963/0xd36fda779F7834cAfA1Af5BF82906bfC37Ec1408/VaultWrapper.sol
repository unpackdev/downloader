// SPDX-License-Identifier: Apache-2.0
pragma solidity ^0.8.2;

import "./IBridge.sol";
import "./IVault.sol";
import "./IVaultWrapper.sol";
import "./ChainId.sol";


import "./Initializable.sol";


contract VaultWrapper is ChainId, Initializable, IVaultWrapper {
    address constant ZERO_ADDRESS = 0x0000000000000000000000000000000000000000;
    string constant API_VERSION = "0.1.0";

    address public vault;

    function initialize(
        address _vault
    ) external override initializer {
        vault = _vault;
    }

    function apiVersion()
        external
        override
        pure
    returns (
        string memory api_version
    ) {
        return API_VERSION;
    }

    /**
        @notice
            Most common entry point for Broxus Bridge.this
            Simply transfers tokens to the FreeTON side.
        @param recipient Recipient TON address
        @param amount Amount of tokens to be deposited
    */
    function deposit(
        IVault.TONAddress memory recipient,
        uint256 amount
    ) external {
        IVault.PendingWithdrawalId memory pendingWithdrawalId = IVault.PendingWithdrawalId(ZERO_ADDRESS, 0);

        IVault(vault).deposit(
            msg.sender,
            recipient,
            amount,
            pendingWithdrawalId,
            true
        );
    }

    /**
        @notice
            Special type of deposit, which allows to fill specified
            pending withdrawals. Set of fillings should be created off-chain.
            Usually allows depositor to receive additional reward (bounty) on the FreeTON side.
        @param recipient Recipient TON address
        @param amount Amount of tokens to be deposited, should be gte than sum(fillings)
        @param pendingWithdrawalsIdsToFill List of pending withdrawals ids
    */
    function depositWithFillings(
        IVault.TONAddress calldata recipient,
        uint256 amount,
        IVault.PendingWithdrawalId[] calldata pendingWithdrawalsIdsToFill
    ) external {
        require(
            pendingWithdrawalsIdsToFill.length > 0,
            'Wrapper: no pending withdrawals specified'
        );

        for (uint i = 0; i < pendingWithdrawalsIdsToFill.length; i++) {
            IVault(vault).deposit(
                msg.sender,
                recipient,
                amount,
                pendingWithdrawalsIdsToFill[i],
                true
            );
        }
    }

    function decodeWithdrawEventData(
        bytes memory payload
    ) public pure returns (
        int8 sender_wid,
        uint256 sender_addr,
        uint128 amount,
        uint160 _recipient,
        uint32 chainId
    ) {
        (IBridge.TONEvent memory tonEvent) = abi.decode(payload, (IBridge.TONEvent));

        return abi.decode(
            tonEvent.eventData,
            (int8, uint256, uint128, uint160, uint32)
        );
    }

    /**
        @notice Entry point for withdrawing tokens from the Broxus Bridge.
        Expects payload with withdraw details and list of relay's signatures.
        @param payload Bytes encoded `IBridge.TONEvent` structure
        @param signatures Set of relay's signatures
        @param bounty Pending withdraw bounty, can be set only by withdraw recipient. Ignores otherwise.
    */
    function saveWithdraw(
        bytes calldata payload,
        bytes[] calldata signatures,
        uint256 bounty
    ) external {
        address bridge = IVault(vault).bridge();

        // Check signatures correct
        require(
            IBridge(bridge).verifySignedTonEvent(
                payload,
                signatures
            ) == 0,
            "Vault wrapper: signatures verification failed"
        );

        // Decode TON event
        (IBridge.TONEvent memory tonEvent) = abi.decode(payload, (IBridge.TONEvent));

        // dev: fix stack too deep
        {
            // Check event configuration matches Vault's configuration
            IVault.TONAddress memory configuration = IVault(vault).configuration();

            require(
                tonEvent.configurationWid == configuration.wid &&
                tonEvent.configurationAddress == configuration.addr,
                "Vault wrapper: wrong event configuration"
            );
        }

        // Decode event data
        (
            int8 sender_wid,
            uint256 sender_addr,
            uint128 amount,
            uint160 _recipient,
            uint32 chainId
        ) = decodeWithdrawEventData(payload);

        // Check chain id
        require(chainId == getChainID(), "Vault wrapper: wrong chain id");

        address recipient = address(_recipient);

        IVault(vault).saveWithdraw(
            keccak256(payload),
            recipient,
            amount,
            recipient == msg.sender ? bounty : 0
        );
    }
}
