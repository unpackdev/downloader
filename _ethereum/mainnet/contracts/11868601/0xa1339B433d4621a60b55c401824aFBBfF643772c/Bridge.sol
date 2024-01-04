// SPDX-License-Identifier: Apache 2.0
pragma solidity ^0.7.0;
pragma experimental ABIEncoderV2;


import "./DistributedOwnable.sol";
import "./IBridge.sol";
import "./Nonce.sol";
import "./RedButton.sol";

import "./SafeMath.sol";
import "./Initializable.sol";


/**
    @title Basic smart contract for implementing Bridge logic.
    @dev Uses DistributedOwnable contract for storing list of relays.
**/
contract Bridge is Initializable, DistributedOwnable, RedButton, Nonce, IBridge {
    using SafeMath for uint;

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
        Handy wrapper around ownership functionality + Bridge specific names.
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

        for (uint i=0; i<signatures.length; i++) {
            address signer = recoverSignature(payload, signatures[i]);

            if (isOwner(signer)) ownersConfirmations++;
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
