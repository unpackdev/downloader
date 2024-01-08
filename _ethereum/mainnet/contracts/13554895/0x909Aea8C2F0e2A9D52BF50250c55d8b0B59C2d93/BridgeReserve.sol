// SPDX-License-Identifier: MIT

pragma solidity >=0.8.0;

import "./MerkleProof.sol";
import "./IArtBridge.sol";
import "./BridgeContext.sol";

///
///
/// ██████╗ ██████╗ ██╗██████╗  ██████╗ ███████╗
/// ██╔══██╗██╔══██╗██║██╔══██╗██╔════╝ ██╔════╝
/// ██████╔╝██████╔╝██║██║  ██║██║  ███╗█████╗
/// ██╔══██╗██╔══██╗██║██║  ██║██║   ██║██╔══╝
/// ██████╔╝██║  ██║██║██████╔╝╚██████╔╝███████╗
/// ╚═════╝ ╚═╝  ╚═╝╚═╝╚═════╝  ╚═════╝ ╚══════╝
///
/// ██████╗ ███████╗███████╗███████╗██████╗ ██╗   ██╗███████╗
/// ██╔══██╗██╔════╝██╔════╝██╔════╝██╔══██╗██║   ██║██╔════╝
/// ██████╔╝█████╗  ███████╗█████╗  ██████╔╝██║   ██║█████╗
/// ██╔══██╗██╔══╝  ╚════██║██╔══╝  ██╔══██╗╚██╗ ██╔╝██╔══╝
/// ██║  ██║███████╗███████║███████╗██║  ██║ ╚████╔╝ ███████╗
/// ╚═╝  ╚═╝╚══════╝╚══════╝╚══════╝╚═╝  ╚═╝  ╚═══╝  ╚══════╝
///
///
/// @title Mint reservation and parameter controller
/// @author artbridge.eth
/// @notice BridgeReserve controls all non financial aspects of a project
contract BridgeReserve is BridgeContext {
  IArtBridge public immutable bridge;

  mapping(uint256 => BridgeBeams.ReserveParameters) public projectToParameters;
  mapping(uint256 => mapping(address => bool)) public projectToMinters;
  mapping(uint256 => mapping(address => uint256))
    public projectToUserReservations;
  mapping(uint256 => uint256) public projectToReservations;

  /// @notice allows operations only on projects before mint starts
  /// @param _id target bridge project id
  modifier onlyReservable(uint256 _id) {
    BridgeBeams.ProjectState memory state = bridge.projectState(_id);
    require(state.initialized, "!initialized");
    require(!state.released, "released");
    _;
  }

  constructor(address _bridge) {
    bridge = IArtBridge(_bridge);
  }

  /// @dev proof is supplied by art bridge api
  /// @dev reserve may be over subscribed, allotted on a first come basis
  /// @param _reserved total number of user allocated tokens
  /// @param _id target bridge project id
  /// @param _amount number of reserved tokens to mint
  /// @param _proof reservation merkle proof
  function reserve(
    uint256 _id,
    uint256 _amount,
    uint256 _reserved,
    bytes32[] calldata _proof
  ) external payable onlyReservable(_id) {
    require(
      _amount * bridge.projectToTokenPrice(_id) == msg.value,
      "invalid payment amount"
    );
    require(
      _amount <= _reserved - projectToUserReservations[_id][msg.sender],
      "invalid reserve amount"
    );
    BridgeBeams.ReserveParameters memory params = projectToParameters[_id];
    require(params.reserveRoot != "", "!reserveRoot");
    require(
      _amount <= params.reservedMints - projectToReservations[_id],
      "invalid reserve amount"
    );
    bytes32 node = keccak256(abi.encodePacked(_id, msg.sender, _reserved));
    require(
      MerkleProof.verify(_proof, params.reserveRoot, node),
      "invalid proof"
    );
    bridge.reserve(_id, _amount, msg.sender);
    projectToUserReservations[_id][msg.sender] += _amount;
    projectToReservations[_id] += _amount;
  }

  /// @dev _reserveRoot is required for reserve but is not required to be set initially
  /// @notice set project reserve and mint parameters
  /// @param _id target bridge project id
  /// @param _maxMintPerInvocation maximum allowed number of mints per transaction
  /// @param _reservedMints maximum allowed number of reservice invocations
  function setParameters(
    uint256 _id,
    uint256 _maxMintPerInvocation,
    uint256 _reservedMints,
    bytes32 _reserveRoot
  ) external onlyReservable(_id) onlyOwner {
    require(_id < bridge.nextProjectId(), "invalid _id");
    (, , , , , , uint256 maxSupply, ) = bridge.projects(_id);
    require(_reservedMints <= maxSupply, "invalid reserve amount");
    require(_maxMintPerInvocation > 0, "require positive mint");
    require(_maxMintPerInvocation <= maxSupply, "invalid mint max");
    BridgeBeams.ReserveParameters memory params = BridgeBeams
      .ReserveParameters({
        maxMintPerInvocation: _maxMintPerInvocation,
        reservedMints: _reservedMints,
        reserveRoot: _reserveRoot
      });
    projectToParameters[_id] = params;
  }

  /// @dev projects may support multiple minters
  /// @notice adds a minter as available to mint a given project
  /// @param _id target bridge project id
  /// @param _minter minter address
  function addMinter(uint256 _id, address _minter) external onlyOwner {
    projectToMinters[_id][_minter] = true;
  }

  /// @notice removes a minter as available to mint a given project
  /// @param _id target bridge project id
  /// @param _minter minter address
  function removeMinter(uint256 _id, address _minter) external onlyOwner {
    projectToMinters[_id][_minter] = false;
  }

  /// @notice updates the project maxMintPerInvocation
  /// @param _id target bridge project id
  /// @param _maxMintPerInvocation maximum number of mints per transaction
  function setmaxMintPerInvocation(uint256 _id, uint256 _maxMintPerInvocation)
    external
    onlyReservable(_id)
    onlyOwner
  {
    (, , , , , , uint256 maxSupply, ) = bridge.projects(_id);
    require(_maxMintPerInvocation <= maxSupply, "invalid mint max");
    require(_maxMintPerInvocation > 0, "require positive mint");
    projectToParameters[_id].maxMintPerInvocation = _maxMintPerInvocation;
  }

  /// @notice updates the project reservedMints
  /// @param _id target bridge project id
  /// @param _reservedMints maximum number of reserved mints per project
  function setReservedMints(uint256 _id, uint256 _reservedMints)
    external
    onlyReservable(_id)
    onlyOwner
  {
    (, , , , , , uint256 maxSupply, ) = bridge.projects(_id);
    require(_reservedMints <= maxSupply, "invalid reserve amount");
    projectToParameters[_id].reservedMints = _reservedMints;
  }

  /// @dev utility function to set or update reserve tree root
  /// @notice updates the project reserveRoot
  /// @param _id target bridge project id
  /// @param _reserveRoot project reservation merkle tree root
  function setReserveRoot(uint256 _id, bytes32 _reserveRoot)
    external
    onlyReservable(_id)
    onlyOwner
  {
    projectToParameters[_id].reserveRoot = _reserveRoot;
  }
}
