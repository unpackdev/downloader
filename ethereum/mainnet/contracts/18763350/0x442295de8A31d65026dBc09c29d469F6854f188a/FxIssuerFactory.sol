// SPDX-License-Identifier: MIT
pragma solidity 0.8.23;

import "./LibClone.sol";
import "./Ownable.sol";
import "./Pausable.sol";

import "./IAccessControl.sol";
import "./IFxGenArt721.sol";
import "./IFxIssuerFactory.sol";
import "./IFxTicketFactory.sol";

/**
 * @title FxIssuerFactory
 * @author fx(hash)
 * @dev See the documentation in {IFxIssuerFactory}
 */
contract FxIssuerFactory is IFxIssuerFactory, Ownable, Pausable {
    /*//////////////////////////////////////////////////////////////////////////
                                    STORAGE
    //////////////////////////////////////////////////////////////////////////*/

    /**
     * @inheritdoc IFxIssuerFactory
     */
    address public immutable roleRegistry;

    /**
     * @inheritdoc IFxIssuerFactory
     */
    address public implementation;

    /**
     * @inheritdoc IFxIssuerFactory
     */
    uint96 public projectId;

    /**
     * @inheritdoc IFxIssuerFactory
     */
    mapping(address => uint256) public nonces;

    /**
     * @inheritdoc IFxIssuerFactory
     */
    mapping(uint96 => address) public projects;

    /*//////////////////////////////////////////////////////////////////////////
                                    CONSTRUCTOR
    //////////////////////////////////////////////////////////////////////////*/

    /**
     * @dev Initializes factory owner, FxRoleRegistry and FxGenArt721 implementation
     */
    constructor(address _admin, address _roleRegistry, address _implementation) {
        _pause();
        roleRegistry = _roleRegistry;
        _initializeOwner(_admin);
        _setImplementation(_implementation);
    }

    /*//////////////////////////////////////////////////////////////////////////
                                EXTERNAL FUNCTIONS
    //////////////////////////////////////////////////////////////////////////*/

    /**
     * @inheritdoc IFxIssuerFactory
     */
    function createProjectWithTicket(
        bytes calldata _projectCreationInfo,
        bytes calldata _ticketCreationInfo,
        address _ticketFactory
    ) external whenNotPaused returns (address genArtToken, address mintTicket) {
        genArtToken = createProject(_projectCreationInfo);
        mintTicket = IFxTicketFactory(_ticketFactory).createTicket(_ticketCreationInfo);
    }

    /**
     * @inheritdoc IFxIssuerFactory
     */
    function unpause() external onlyOwner {
        _unpause();
    }

    /**
     * @inheritdoc IFxIssuerFactory
     */
    function pause() external onlyOwner {
        _pause();
    }

    /**
     * @inheritdoc IFxIssuerFactory
     */
    function setImplementation(address _implementation) external onlyOwner {
        _setImplementation(_implementation);
    }

    /*//////////////////////////////////////////////////////////////////////////
                                PUBLIC FUNCTIONS
    //////////////////////////////////////////////////////////////////////////*/

    /**
     * @inheritdoc IFxIssuerFactory
     */
    function createProject(bytes memory _creationInfo) public returns (address genArt721) {
        (
            address _owner,
            InitInfo memory _initInfo,
            ProjectInfo memory _projectInfo,
            MetadataInfo memory _metadataInfo,
            MintInfo[] memory _mintInfo,
            address[] memory _royaltyReceivers,
            uint32[] memory _allocations,
            uint96 _basisPoints
        ) = abi.decode(
                _creationInfo,
                (address, InitInfo, ProjectInfo, MetadataInfo, MintInfo[], address[], uint32[], uint96)
            );

        genArt721 = createProjectWithParams(
            _owner,
            _initInfo,
            _projectInfo,
            _metadataInfo,
            _mintInfo,
            _royaltyReceivers,
            _allocations,
            _basisPoints
        );
    }

    /**
     * @inheritdoc IFxIssuerFactory
     */
    function createProjectWithParams(
        address _owner,
        InitInfo memory _initInfo,
        ProjectInfo memory _projectInfo,
        MetadataInfo memory _metadataInfo,
        MintInfo[] memory _mintInfo,
        address[] memory _royaltyReceivers,
        uint32[] memory _allocations,
        uint96 _basisPoints
    ) public whenNotPaused returns (address genArtToken) {
        if (_owner == address(0)) revert InvalidOwner();

        bytes32 salt = keccak256(abi.encode(msg.sender, nonces[msg.sender]));
        genArtToken = LibClone.cloneDeterministic(implementation, salt);
        nonces[msg.sender]++;
        projects[++projectId] = genArtToken;

        emit ProjectCreated(projectId, genArtToken, _owner);

        IFxGenArt721(genArtToken).initialize(
            _owner,
            _initInfo,
            _projectInfo,
            _metadataInfo,
            _mintInfo,
            _royaltyReceivers,
            _allocations,
            _basisPoints
        );
    }

    /*//////////////////////////////////////////////////////////////////////////
                                VIEW FUNCTIONS
    //////////////////////////////////////////////////////////////////////////*/

    /**
     * @inheritdoc IFxIssuerFactory
     */
    function getTokenAddress(address _sender) external view returns (address) {
        bytes32 salt = keccak256(abi.encode(_sender, nonces[_sender]));
        return LibClone.predictDeterministicAddress(implementation, salt, address(this));
    }

    /*//////////////////////////////////////////////////////////////////////////
                                INTERNAL FUNCTIONS
    //////////////////////////////////////////////////////////////////////////*/

    /**
     * @dev Sets the FxGenArt721 implementation contract
     */
    function _setImplementation(address _implementation) internal {
        implementation = _implementation;
        emit ImplementationUpdated(msg.sender, _implementation);
    }
}
