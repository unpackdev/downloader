// SPDX-License-Identifier: bsl-1.1

pragma solidity ^0.8.0;

import "./ECDSA.sol";
import "./MultipartyCommons.sol";


abstract contract NonProxiedOwnerMultipartyCommons is MultipartyCommons {
    event MPOwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    OwnerMultisignature internal ownerMultisignature_; // informational field
    address internal mpOwner_;   // described by ownerMultisignature

    constructor(address verifyingContract, uint256 chainId) MultipartyCommons(verifyingContract, chainId) {
        address[] memory newParticipants = new address[](1);
        newParticipants[0] = msg.sender;
        changeOwner_(msg.sender, 1, newParticipants);
    }

    /**
     * @notice Changes multiparty owner data.
     * @param newOwner Address of the new mp owner.
     * @param quorum New quorum value.
     * @param newParticipants List of the new participants' addresses
     * @param salt Salt value
     * @param deadline Unix ts at which the work must be interrupted.
     */
    function changeOwner(address newOwner, uint quorum, address[] calldata newParticipants, uint salt, uint deadline)
        external
        selfCall
        applicable(salt, deadline)
    {
        changeOwner_(newOwner, quorum, newParticipants);
    }

    /**
     * @notice Changes multiparty owner data. Internal
     * @param newOwner Address of the new mp owner.
     * @param quorum New quorum value.
     * @param newParticipants List of the new participants' addresses
     */
    function changeOwner_(address newOwner, uint quorum, address[] memory newParticipants)
        internal
    {
        require(newOwner != address(0), "MP: ZERO_ADDRESS");
        emit MPOwnershipTransferred(mpOwner_, newOwner);
        address[] memory oldParticipants = ownerMultisignature_.participants;
        onNewOwner(newOwner, quorum, newParticipants, oldParticipants);
        ownerMultisignature_.quorum = quorum;
        ownerMultisignature_.participants = newParticipants;
        mpOwner_ = newOwner;
    }

    /**
     * @notice The new mp owner handler. Empty implementation
     * @param newOwner Address of the new mp owner.
     * @param newQuorum New quorum value.
     * @param newParticipants List of the new participants' addresses.
     * @param oldParticipants List of the old participants' addresses.
     */
    function onNewOwner(address newOwner, uint newQuorum, address[] memory newParticipants, address[] memory oldParticipants) virtual internal {}

    // @inheritdoc IMpOwnable
    function ownerMultisignature() public view virtual override returns (OwnerMultisignature memory) {
        return ownerMultisignature_;
    }

    // @inheritdoc IMpOwnable
    function mpOwner() public view virtual override returns (address) {
        return mpOwner_;
    }
}
