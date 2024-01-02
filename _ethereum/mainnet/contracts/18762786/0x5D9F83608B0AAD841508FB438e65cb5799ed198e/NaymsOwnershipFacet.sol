// SPDX-License-Identifier: MIT
pragma solidity 0.8.20;

import "./LibDiamond.sol";
import "./IERC173.sol";
import "./LibACL.sol";
import "./LibHelpers.sol";
import "./LibAdmin.sol";
import "./LibConstants.sol";
import "./Modifiers.sol";

contract NaymsOwnershipFacet is IERC173, Modifiers {
    function transferOwnership(address _newOwner) external override assertPrivilege(LibAdmin._getSystemId(), LC.GROUP_SYSTEM_ADMINS) {
        bytes32 systemID = LibHelpers._stringToBytes32(LC.SYSTEM_IDENTIFIER);
        bytes32 newAcc1Id = LibHelpers._getIdForAddress(_newOwner);

        require(!LibACL._isInGroup(newAcc1Id, systemID, LibHelpers._stringToBytes32(LC.GROUP_SYSTEM_ADMINS)), "NEW owner MUST NOT be sys admin");
        require(!LibACL._isInGroup(newAcc1Id, systemID, LibHelpers._stringToBytes32(LC.GROUP_SYSTEM_MANAGERS)), "NEW owner MUST NOT be sys manager");

        LibDiamond.setContractOwner(_newOwner);
    }

    function owner() external view override returns (address owner_) {
        owner_ = LibDiamond.contractOwner();
    }
}
