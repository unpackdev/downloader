// SPDX-License-Identifier: MIT
pragma solidity 0.8.6;

import "./ITextResolver.sol";
import "./IERC721.sol";
import "./Strings.sol";
import "./JBOperatable.sol";
import "./IJBProjectHandles.sol";
import "./JBOperations2.sol";

/** 
  @title 
  JBProjectHandles

  @author 
  peri, jango, drgorilla

  @notice 
  Manages reverse records that point from JB project IDs to ENS nodes. If the reverse record of a project ID is pointed to an ENS node with a TXT record matching the ID of that project, then the ENS node will be considered the "handle" for that project.

  @dev
  Adheres to -
  IJBProjectHandles: General interface for the methods in this contract that interact with the blockchain's state according to the protocol's rules.

  @dev
  Inherits from -
  JBOperatable: Several functions in this contract can only be accessed by a project owner, or an address that has been preconfifigured to be an operator of the project.
*/
contract JBProjectHandles is IJBProjectHandles, JBOperatable {
  //*********************************************************************//
  // --------------------------- custom errors ------------------------- //
  //*********************************************************************//
  error EMPTY_NAME_PART();
  error NO_PARTS();

  //*********************************************************************//
  // --------------------- internal stored properties ------------------ //
  //*********************************************************************//

  /** 
    @notice
    Mapping of project ID to an array of strings that make up an ENS name and its subdomains.

    @dev
    ["jbx", "dao", "foo"] represents foo.dao.jbx.eth.

    _projectId The ID of the project to get an ENS name for.
  */
  mapping(uint256 => string[]) internal _ensNamePartsOf;

  //*********************************************************************//
  // --------------- public immutable stored properties ---------------- //
  //*********************************************************************//

  /** 
    @notice
    The key of the ENS text record.
  */
  string public constant override TEXT_KEY = 'juicebox_project_id';

  //*********************************************************************//
  // --------------------- public stored properties -------------------- //
  //*********************************************************************//

  /** 
    @notice
    A contract which mints ERC-721's that represent project ownership and transfers.
  */
  IJBProjects public immutable override projects;

  /** 
    @notice
    The ENS text resolver contract address.
  */
  ITextResolver public immutable override textResolver;

  //*********************************************************************//
  // ------------------------- external views -------------------------- //
  //*********************************************************************//

  /** 
    @notice 
    Returns the handle for a project.

    @dev 
    Requires a TXT record for the `TEXT_KEY` that matches the `_projectId`.

    @param _projectId The ID of the project to get the handle of.

    @return The project's handle.
  */
  function handleOf(uint256 _projectId) external view override returns (string memory) {
    // Get a reference to the project's ENS name parts.
    string[] memory _ensNameParts = _ensNamePartsOf[_projectId];

    // Return empty string if ENS isn't set.
    if (_ensNameParts.length == 0) return '';

    // Find the projectId that the text record of the ENS name is mapped to.
    string memory textRecordProjectId = textResolver.text(_namehash(_ensNameParts), TEXT_KEY);

    // Return empty string if text record from ENS name doesn't match projectId.
    if (keccak256(bytes(textRecordProjectId)) != keccak256(bytes(Strings.toString(_projectId))))
      return '';

    // Format the handle from the name parts.
    return _formatHandle(_ensNameParts);
  }

  /** 
    @notice 
    The parts of the stored ENS name of a project.

    @param _projectId The ID of the project to get the ENS name of.

    @return The parts of the ENS name parts of a project.
  */
  function ensNamePartsOf(uint256 _projectId) external view override returns (string[] memory) {
    return _ensNamePartsOf[_projectId];
  }

  //*********************************************************************//
  // ---------------------------- constructor -------------------------- //
  //*********************************************************************//

  /** 
    @param _projects A contract which mints ERC-721's that represent project ownership and transfers.
    @param _operatorStore A contract storing operator assignments.
    @param _textResolver The ENS text resolver contract address.
  */
  constructor(
    IJBProjects _projects,
    IJBOperatorStore _operatorStore,
    ITextResolver _textResolver
  ) JBOperatable(_operatorStore) {
    projects = _projects;
    textResolver = _textResolver;
  }

  //*********************************************************************//
  // --------------------- external transactions ----------------------- //
  //*********************************************************************//

  /** 
    @notice 
    Associate an ENS name with a project.

    @dev
    ["jbx", "dao", "foo"] represents foo.dao.jbx.eth.

    @dev
    Only a project's owner or a designated operator can set its ENS name parts.

    @param _projectId The ID of the project to set an ENS handle for.
    @param _parts The parts of the ENS domain to use as the project handle, excluding the trailing .eth.
  */
  function setEnsNamePartsFor(uint256 _projectId, string[] memory _parts)
    external
    override
    requirePermission(projects.ownerOf(_projectId), _projectId, JBOperations2.SET_ENS_NAME_FOR)
  {
    // Get a reference to the number of parts are in the ENS name.
    uint256 _partsLength = _parts.length;

    // Make sure there are ens name parts.
    if (_parts.length == 0) revert NO_PARTS();

    // Make sure no provided parts are empty.
    for (uint256 _i = 0; _i < _partsLength; ) {
      if (bytes(_parts[_i]).length == 0) revert EMPTY_NAME_PART();
      unchecked {
        ++_i;
      }
    }

    // Store the parts.
    _ensNamePartsOf[_projectId] = _parts;

    emit SetEnsNameParts(_projectId, _formatHandle(_parts), _parts, msg.sender);
  }

  //*********************************************************************//
  // ------------------------ internal functions ----------------------- //
  //*********************************************************************//

  /** 
    @notice 
    Formats ENS name parts into a handle.

    @param _ensNameParts The ENS name parts to format into a handle.

    @return _handle The formatted ENS handle.
  */
  function _formatHandle(string[] memory _ensNameParts)
    internal
    pure
    returns (string memory _handle)
  {
    // Get a reference to the number of parts are in the ENS name.
    uint256 _partsLength = _ensNameParts.length;

    // Concatenate each name part.
    for (uint256 _i = 1; _i <= _partsLength; ) {
      _handle = string(abi.encodePacked(_handle, _ensNameParts[_partsLength - _i]));

      // Add a dot if this part isn't the last.
      if (_i < _partsLength) _handle = string(abi.encodePacked(_handle, '.'));

      unchecked {
        ++_i;
      }
    }
  }

  /** 
    @notice 
    Returns a namehash for an ENS name.

    @dev 
    See https://eips.ethereum.org/EIPS/eip-137.

    @param _ensNameParts The parts of an ENS name to hash.

    @return namehash The namehash for an ENS name parts.
  */
  function _namehash(string[] memory _ensNameParts) internal pure returns (bytes32 namehash) {
    // Hash the trailing "eth" suffix.
    namehash = keccak256(abi.encodePacked(namehash, keccak256(abi.encodePacked('eth'))));

    // Get a reference to the number of parts are in the ENS name.
    uint256 _nameLength = _ensNameParts.length;

    // Hash each part.
    for (uint256 _i = 0; _i < _nameLength; ) {
      namehash = keccak256(
        abi.encodePacked(namehash, keccak256(abi.encodePacked(_ensNameParts[_i])))
      );
      unchecked {
        ++_i;
      }
    }
  }
}
