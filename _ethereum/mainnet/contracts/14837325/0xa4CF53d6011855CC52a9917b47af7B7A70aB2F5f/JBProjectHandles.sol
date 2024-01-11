// SPDX-License-Identifier: MIT

/// @title JBProjectHandles
/// @author peri
/// @notice Manages reverse records that point from JB project IDs to ENS nodes. If the reverse record of a project ID is pointed to an ENS node with a TXT record matching the ID of that project, then the ENS node will be considered the "handle" for that project.

pragma solidity ^0.8.0;

import "./IERC721.sol";
import "./IJBProjectHandles.sol";
import "./ITextResolver.sol";

contract JBProjectHandles is IJBProjectHandles {
    /* -------------------------------------------------------------------------- */
    /* ------------------------------- MODIFIERS -------------------------------- */
    /* -------------------------------------------------------------------------- */

    /// @notice Require that caller owns this Juicebox project
    /// @param projectId id of Juicebox project
    modifier onlyProjectOwner(uint256 projectId) {
        require(
            msg.sender == IERC721(jbProjects).ownerOf(projectId),
            "Not Juicebox project owner"
        );
        _;
    }

    /* -------------------------------------------------------------------------- */
    /* ------------------------------ CONSTRUCTOR ------------------------------- */
    /* -------------------------------------------------------------------------- */

    constructor(address _jbProjects, address _ensTextResolver) {
        jbProjects = _jbProjects;
        ensTextResolver = _ensTextResolver;
    }

    /* -------------------------------------------------------------------------- */
    /* ------------------------------- VARIABLES -------------------------------- */
    /* -------------------------------------------------------------------------- */

    string public constant KEY = "juicebox";

    /// JB Projects contract address
    address public immutable jbProjects;

    /// ENS text resolver contract address
    address public immutable ensTextResolver;

    /// Point from project ID to ENS node
    mapping(uint256 => bytes32) reverseRecords;

    /* -------------------------------------------------------------------------- */
    /* --------------------------- EXTERNAL FUNCTIONS --------------------------- */
    /* -------------------------------------------------------------------------- */

    /// @notice Set reverse record for Juicebox project
    /// @dev Requires sender to own Juicebox project
    /// @param projectId id of Juicebox project
    /// @param record new reverse record for Juicebox project
    function setReverseRecord(uint256 projectId, bytes32 record)
        external
        onlyProjectOwner(projectId)
    {
        reverseRecords[projectId] = record;

        emit SetReverseRecord(projectId, record);
    }

    /// @notice Returns reverse record of Juicebox project
    /// @param projectId id of Juicebox project
    function reverseRecordOf(uint256 projectId)
        public
        view
        returns (bytes32 reverseRecord)
    {
        reverseRecord = reverseRecords[projectId];
    }

    /// @notice Returns handle for Juicebox project
    /// @dev Requires ENS TXT record to match projectId
    /// @param projectId id of Juicebox project
    function handleOf(uint256 projectId) public view returns (bytes32) {
        bytes32 reverseRecord = reverseRecordOf(projectId);

        require(reverseRecord != bytes32(0), "No reverse record");

        string memory id = ITextResolver(ensTextResolver).text(
            reverseRecord,
            KEY
        );

        require(stringToUint(id) == projectId, "Invalid TXT record");

        return reverseRecord;
    }

    /* -------------------------------------------------------------------------- */
    /* --------------------------- INTERNAL FUNCTIONS --------------------------- */
    /* -------------------------------------------------------------------------- */

    /// @notice Converts string to uint256
    /// @param numstring number string to be converted
    function stringToUint(string memory numstring)
        internal
        pure
        returns (uint256 result)
    {
        result = 0;
        bytes memory stringBytes = bytes(numstring);
        for (uint256 i = 0; i < stringBytes.length; i++) {
            uint256 exp = stringBytes.length - i;
            bytes1 ival = stringBytes[i];
            uint8 uval = uint8(ival);
            uint256 jval = uval - uint256(0x30);

            result += (uint256(jval) * (10**(exp - 1)));
        }
    }
}
