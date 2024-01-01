// SPDX-License-Identifier: MIT
pragma solidity 0.8.21;

/**************************************

    security-contact:
    - security@angelblock.io

    maintainers:
    - marcin@angelblock.io
    - piotr@angelblock.io
    - mikolaj@angelblock.io
    - sebastian@angelblock.io

    contributors:
    - domenico@angelblock.io

**************************************/

// OpenZeppelin
import "./Clones.sol";

// Local imports - Events
import "./EscrowEvents.sol";

// Local imports - Errors
import "./EscrowErrors.sol";

// Local imports - Storages
import "./LibEscrow.sol";

// Local imports - Interfaces
import "./Configurable.sol";

library EscrowService {
    /// @dev Allows to create new Escrow contract.
    /// @dev Events: EscrowCreated(string raiseId, address instance, address source).
    /// @param _raiseId Id of the Raise for which Escrow will be created.
    /// @return escrow_ Newly created Escrow contract address
    function createEscrow(string memory _raiseId) internal returns (address escrow_) {
        // get Escrow source address
        address source_ = LibEscrow.getSource();

        // validate if source is set
        if (source_ == address(0)) {
            revert EscrowErrors.SourceNotSet();
        }

        // create new Escrow - clone
        escrow_ = Clones.clone(source_);

        // configure Escrow
        Configurable(escrow_).configure(abi.encode(address(this)));

        // assing created Escrow address for given raise id
        LibEscrow.setEscrow(_raiseId, escrow_);

        // emit
        emit EscrowEvents.EscrowCreated(_raiseId, escrow_, source_);
    }
}
