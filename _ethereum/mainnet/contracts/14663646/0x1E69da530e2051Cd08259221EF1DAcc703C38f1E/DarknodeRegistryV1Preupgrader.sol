pragma solidity ^0.5.17;
pragma experimental ABIEncoderV2;

import "./Ownable.sol";

import "./DarknodeRegistry.sol";
import "./RenProxyAdmin.sol";
import "./RenToken.sol";
import "./DarknodeRegistryV1ToV2Upgrader.sol";

contract DarknodeRegistryV1ToV2Preupgrader is Ownable {
    DarknodeRegistryLogicV1 public darknodeRegistryProxy;
    DarknodeRegistryV1ToV2Upgrader public upgrader;

    constructor(
        DarknodeRegistryLogicV1 _darknodeRegistryProxy,
        DarknodeRegistryV1ToV2Upgrader _upgrader
    ) public {
        Ownable.initialize(msg.sender);
        darknodeRegistryProxy = _darknodeRegistryProxy;
        upgrader = _upgrader;
    }

    function claimStoreOwnership() public {
        darknodeRegistryProxy.store().claimOwnership();
    }

    function recover(
        address[] calldata _darknodeIDs,
        address _bondRecipient,
        bytes[] calldata _signatures
    ) external onlyOwner {
        forwardDNR();
        RenToken ren = darknodeRegistryProxy.ren();
        DarknodeRegistryStore store = darknodeRegistryProxy.store();
        darknodeRegistryProxy.transferStoreOwnership(
            DarknodeRegistryLogicV1(address(this))
        );
        if (darknodeRegistryProxy.store().owner() != address(this)) {
            claimStoreOwnership();
        }

        (, uint256 currentEpochBlocktime) = darknodeRegistryProxy
            .currentEpoch();
        (, uint256 previousEpochBlocktime) = darknodeRegistryProxy
            .previousEpoch();
        uint256 deregistrationInterval = darknodeRegistryProxy
            .deregistrationInterval();

        uint256 total = 0;

        for (uint8 i = 0; i < _darknodeIDs.length; i++) {
            address _darknodeID = _darknodeIDs[i];

            // Require darknode to be refundable.
            {
                uint256 deregisteredAt = store.darknodeDeregisteredAt(
                    _darknodeID
                );
                bool deregistered = deregisteredAt != 0 &&
                    deregisteredAt <= currentEpochBlocktime;
                bool refundable = deregistered &&
                    store.darknodeDeregisteredAt(_darknodeID) <=
                    (previousEpochBlocktime - deregistrationInterval);

                require(
                    refundable,
                    "DarknodeRegistryV1Preupgrader: must be refundable"
                );
            }

            address darknodeOperator = store.darknodeOperator(_darknodeID);
            require(
                ECDSA.recover(
                    keccak256(
                        abi.encodePacked(
                            "\x19Ethereum Signed Message:\n64",
                            "DarknodeRegistry.recover",
                            _darknodeID,
                            _bondRecipient
                        )
                    ),
                    _signatures[i]
                ) == darknodeOperator,
                "DarknodeRegistryV1Preupgrader: invalid signature"
            );
            // Remember the bond amount
            total += store.darknodeBond(_darknodeID);
            // Erase the darknode from the registry
            store.removeDarknode(_darknodeID);
            // // Refund the operator by transferring REN
        }

        require(
            ren.transfer(_bondRecipient, total),
            "DarknodeRegistryV1Preupgrader: bond transfer failed"
        );

        store.transferOwnership(address(darknodeRegistryProxy));
        darknodeRegistryProxy.claimStoreOwnership();
    }

    function forwardDNR() public onlyOwner {
        // Claim ownership
        if (darknodeRegistryProxy.owner() != address(this)) {
            darknodeRegistryProxy.claimOwnership();
        }
        // Set pending owner to upgrader.
        if (darknodeRegistryProxy.pendingOwner() != address(upgrader)) {
            darknodeRegistryProxy.transferOwnership(address(upgrader));
        }
    }
}
