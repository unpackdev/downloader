// SPDX-License-Identifier: Apache 2.0
pragma solidity ^0.8.0;
pragma experimental ABIEncoderV2;


import "./DistributedOwnable.sol";
import "./IBridge.sol";
import "./Nonce.sol";
import "./RedButton.sol";

import "./Initializable.sol";


/**
    @title Ethereum Bridge contract.
**/
contract Bridge is Initializable, DistributedOwnable, RedButton, Nonce, IBridge {
    BridgeConfiguration bridgeConfiguration;

    /**
        @notice Bridge initializer
        @param owners Initial list of owners addresses
        @param admin Red button caller, probably multisig
        @param _bridgeConfiguration Bridge configuration
    **/
    function initialize(
        address[] memory owners,
        address admin,
        BridgeConfiguration memory _bridgeConfiguration
    ) public initializer {
        for (uint i=0; i < owners.length; i++) {
            grantOwnership(owners[i]);
        }

        _setAdmin(admin);

        bridgeConfiguration = _bridgeConfiguration;
    }

    /*
        Is address relay or not.
        Handy wrapper around ownership functionality.
        @param candidate Address
        @returns Boolean is relay or not
    */
    function isRelay(
        address candidate
    ) override public view returns(bool) {
        return isOwner(candidate);
    }

    /**
     * @notice Count how much signatures are made by owners.
     * @param payload Bytes payload, which was signed
     * @param signatures Bytes array with payload signatures
    */
    function countRelaysSignatures(
        bytes memory payload,
        bytes[] memory signatures
    ) public override view returns(uint) {
        uint ownersConfirmations = 0;

        address[] memory signers = new address[](signatures.length);

        for (uint i=0; i<signatures.length; i++) {
            address signer = recoverSignature(payload, signatures[i]);

            if (isOwner(signer)) {
                // Check this owner is not used before
                for (uint u=0; u<signers.length; u++) {
                    require(signers[u] != signer, "Signer already seen");
                }

                ownersConfirmations++;
                signers[i] = signer;
            }
        }

        return ownersConfirmations;
    }

    /*
        Update Bridge configuration
        @dev Check enough owners signed and apply update
        @param payload Bytes encoded BridgeConfiguration structure
    */
    function updateBridgeConfiguration(
        bytes memory payload,
        bytes[] memory signatures
    ) public {
        require(
            countRelaysSignatures(
                payload,
                signatures
            ) >= bridgeConfiguration.bridgeUpdateRequiredConfirmations,
            'Not enough confirmations'
        );

        (BridgeConfiguration memory _bridgeConfiguration) = abi.decode(payload, (BridgeConfiguration));

        require(nonceNotUsed(_bridgeConfiguration.nonce), 'Nonce already used');

        bridgeConfiguration = _bridgeConfiguration;

        rememberNonce(_bridgeConfiguration.nonce);
    }

    /*
        Update Bridge relay
        @dev Check enough owners signed and apply update
        @param payload Bytes encoded BridgeRelay structure
    */
    function updateBridgeRelay(
        bytes memory payload,
        bytes[] memory signatures
    ) public {
        require(
            countRelaysSignatures(
                payload,
                signatures
            ) >= bridgeConfiguration.bridgeUpdateRequiredConfirmations,
            'Not enough confirmations'
        );

        (BridgeRelay memory bridgeRelay) = abi.decode(payload, (BridgeRelay));

        require(nonceNotUsed(bridgeRelay.nonce), 'Nonce already used');

        if (bridgeRelay.action) {
            grantOwnership(bridgeRelay.account);
        } else {
            removeOwnership(bridgeRelay.account);
        }

        rememberNonce(bridgeRelay.nonce);
    }

    /*
        Get current bridge configuration
        @return Bridge configuration structure
    */
    function getConfiguration() public view override returns (BridgeConfiguration memory) {
        return bridgeConfiguration;
    }
}
