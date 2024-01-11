// SPDX-License-Identifier: MIT

/// @title JBProjectHandles
/// @author peri
/// @notice Manages reverse records that point from JB project IDs to ENS nodes. If the reverse record of a project ID is pointed to an ENS node with a TXT record matching the ID of that project, then the ENS node will be considered the "handle" for that project.

pragma solidity 0.8.14;

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

    /// Point from project ID to ENS name
    mapping(uint256 => string) ensNames;

    /* -------------------------------------------------------------------------- */
    /* --------------------------- EXTERNAL FUNCTIONS --------------------------- */
    /* -------------------------------------------------------------------------- */

    /// @notice Set reverse record for Juicebox project
    /// @dev Requires sender to own Juicebox project
    /// @param projectId id of Juicebox project
    /// @param ensName ENS name to use as project handle
    function setEnsNameFor(uint256 projectId, string calldata ensName)
        external
        onlyProjectOwner(projectId)
    {
        ensNames[projectId] = ensName;

        emit SetEnsName(projectId, ensName);
    }

    /// @notice Returns ensName of Juicebox project
    /// @param projectId id of Juicebox project
    function ensNameOf(uint256 projectId)
        public
        view
        returns (string memory ensName)
    {
        ensName = ensNames[projectId];
    }

    /// @notice Returns ensName for Juicebox project
    /// @dev Requires ensName to have TXT record matching projectId
    /// @param projectId id of Juicebox project
    /// @return ensName for projectIf
    function handleOf(uint256 projectId) public view returns (string memory) {
        string memory ensName = ensNameOf(projectId);

        require(bytes(ensName).length > 0, "No ensName for project");

        string memory reverseId = ITextResolver(ensTextResolver).text(
            namehash(ensName),
            KEY
        );

        require(stringToUint(reverseId) == projectId, "Invalid TXT record");

        return ensName;
    }

    /* -------------------------------------------------------------------------- */
    /* --------------------------- INTERNAL FUNCTIONS --------------------------- */
    /* -------------------------------------------------------------------------- */

    /// @notice Converts string to uint256
    /// @param numstring number string to be converted
    /// @return result uint conversion from string
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

    /// @notice Returns namehash for ENS name
    /// @dev https://eips.ethereum.org/EIPS/eip-137
    /// @param ensName ENS name to hash
    /// @return _namehash namehash for ensName
    function namehash(string memory ensName)
        internal
        pure
        returns (bytes32 _namehash)
    {
        _namehash = 0x0000000000000000000000000000000000000000000000000000000000000000;
        _namehash = keccak256(
            abi.encodePacked(_namehash, keccak256(abi.encodePacked("eth")))
        );
        _namehash = keccak256(
            abi.encodePacked(_namehash, keccak256(abi.encodePacked(ensName)))
        );
    }
}
  