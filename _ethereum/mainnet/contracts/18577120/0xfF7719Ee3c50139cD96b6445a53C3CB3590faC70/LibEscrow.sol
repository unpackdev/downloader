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

/// @notice Library containing Escrow storage with getters and setters.
library LibEscrow {
    // -----------------------------------------------------------------------
    //                              Constants
    // -----------------------------------------------------------------------

    /// @dev Escrow storage pointer.
    bytes32 internal constant ESCROW_STORAGE_POSITION = keccak256("angelblock.fundraising.escrow");

    // -----------------------------------------------------------------------
    //                              Structs
    // -----------------------------------------------------------------------

    /// @dev Escrow diamond storage.
    /// @param source Address of contract with source implementation for cloning Escrows.
    /// @param escrows Mapping of raise id to cloned Escrow instance address.
    struct EscrowStorage {
        address source;
        mapping(string => address) escrows;
    }

    // -----------------------------------------------------------------------
    //                              Diamond storage
    // -----------------------------------------------------------------------

    /// @dev Function returning escrow storage at storage pointer slot.
    /// @return es EscrowStorage struct instance at storage pointer position
    function escrowStorage() internal pure returns (EscrowStorage storage es) {
        // declare position
        bytes32 position = ESCROW_STORAGE_POSITION;

        // set slot to position
        assembly {
            es.slot := position
        }

        // explicit return
        return es;
    }

    // -----------------------------------------------------------------------
    //                              Getters / setters
    // -----------------------------------------------------------------------

    /// @dev Diamond storage getter: Escrow source address.
    /// @return Escrow source address.
    function getSource() internal view returns (address) {
        return escrowStorage().source;
    }

    /// @dev Diamond storage getter: Escrow address.
    /// @param _raiseId Id of the Raise.
    /// @return Escrow address.
    function getEscrow(string memory _raiseId) internal view returns (address) {
        // get escrow address
        return escrowStorage().escrows[_raiseId];
    }

    /// @dev Diamond storage setter: Escrow source.
    /// @param _source Address of the source
    function setSource(address _source) internal {
        // set source address
        escrowStorage().source = _source;
    }

    /// @dev Diamond storage setter: Escrow address for raise.
    /// @param _raiseId Id of the Raise.
    /// @param _escrow Address of the escrow
    function setEscrow(string memory _raiseId, address _escrow) internal {
        // set Escrow
        escrowStorage().escrows[_raiseId] = _escrow;
    }
}
