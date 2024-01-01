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

// Local imports - Structs
import "./StorageTypes.sol";
import "./EnumTypes.sol";

// ToDo : NatSpec + Comments

/// @notice Library containing raise storage with getters and setters.
library LibRaise {
    // -----------------------------------------------------------------------
    //                              Constants
    // -----------------------------------------------------------------------

    /// @dev Raise storage pointer.
    bytes32 internal constant RAISE_STORAGE_POSITION = keccak256("angelblock.fundraising.storage.raise");
    /// @dev Precision used in price calculation
    uint256 internal constant PRICE_PRECISION = 10 ** 18;

    // -----------------------------------------------------------------------
    //                              Structs
    // -----------------------------------------------------------------------

    /// @dev Raise storage struct.
    /// @param raises Mapping of raise id to particular raise struct
    /// @param raiseDetails Mapping of raise id to vested token information
    /// @param raiseDataCrosschains Mapping of raise id to raise state information
    struct RaiseStorage {
        mapping(string => StorageTypes.Raise) raises;
        mapping(string => StorageTypes.RaiseDetails) raiseDetails;
        mapping(string => StorageTypes.RaiseDataCC) raiseDataCrosschains;
    }

    function raiseStorage() internal pure returns (RaiseStorage storage rs) {
        bytes32 position = RAISE_STORAGE_POSITION;

        assembly {
            rs.slot := position
        }

        return rs;
    }

    function getId(string memory _raiseId) internal view returns (string memory) {
        return raiseStorage().raises[_raiseId].raiseId;
    }

    function getType(string memory _raiseId) internal view returns (EnumTypes.RaiseType) {
        return raiseStorage().raises[_raiseId].raiseType;
    }

    function getOwner(string memory _raiseId) internal view returns (address) {
        return raiseStorage().raises[_raiseId].owner;
    }

    function getTokensPerBaseAsset(string memory _raiseId) internal view returns (uint256) {
        return raiseStorage().raiseDetails[_raiseId].tokensPerBaseAsset;
    }

    function getHardcap(string memory _raiseId) internal view returns (uint256) {
        return raiseStorage().raiseDetails[_raiseId].hardcap;
    }

    function getSoftcap(string memory _raiseId) internal view returns (uint256) {
        return raiseStorage().raiseDetails[_raiseId].softcap;
    }

    function getStart(string memory _raiseId) internal view returns (uint256) {
        return raiseStorage().raiseDetails[_raiseId].start;
    }

    function getEnd(string memory _raiseId) internal view returns (uint256) {
        return raiseStorage().raiseDetails[_raiseId].end;
    }

    function getRaised(string memory _raiseId) internal view returns (uint256) {
        return raiseStorage().raiseDataCrosschains[_raiseId].raised;
    }

    function setRaise(string memory _raiseId, StorageTypes.Raise memory _raise) internal {
        raiseStorage().raises[_raiseId] = _raise;
    }

    function setRaiseDetails(string memory _raiseId, StorageTypes.RaiseDetails memory _raiseDetails) internal {
        raiseStorage().raiseDetails[_raiseId] = _raiseDetails;
    }

    function setRaiseDataCrosschain(string memory _raiseId, StorageTypes.RaiseDataCC memory _raiseDataCC) internal {
        raiseStorage().raiseDataCrosschains[_raiseId] = _raiseDataCC;
    }

    function setEnd(string memory _raiseId, uint256 _end) internal {
        raiseStorage().raiseDetails[_raiseId].end = _end;
    }

    function increaseRaised(string memory _raiseId, uint256 _amount) internal {
        raiseStorage().raiseDataCrosschains[_raiseId].raised += _amount;
    }
}
