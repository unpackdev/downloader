// SPDX-License-Identifier: MIT
pragma solidity 0.8.23;

import "./Structs.sol";

/**
 * @title IFxIssuerFactory
 * @author fx(hash)
 * @notice Factory for managing newly deployed FxGenArt721 tokens
 */
interface IFxIssuerFactory {
    /*//////////////////////////////////////////////////////////////////////////
                                  EVENTS
    //////////////////////////////////////////////////////////////////////////*/

    /**
     * @notice Event emitted when the FxGenArt721 implementation contract is updated
     * @param _owner Address of the factory owner
     * @param _implementation Address of the new FxGenArt721 implementation contract
     */
    event ImplementationUpdated(address indexed _owner, address indexed _implementation);

    /**
     * @notice Event emitted when a new generative art project is created
     * @param _projectId ID of the project
     * @param _genArtToken Address of newly deployed FxGenArt721 token contract
     * @param _owner Address of project owner
     */
    event ProjectCreated(uint96 indexed _projectId, address indexed _genArtToken, address indexed _owner);

    /*//////////////////////////////////////////////////////////////////////////
                                  ERRORS
    //////////////////////////////////////////////////////////////////////////*/

    /**
     * @notice Error thrown when owner is zero address
     */
    error InvalidOwner();

    /**
     * @notice Error thrown when primary receiver is zero address
     */
    error InvalidPrimaryReceiver();

    /**
     * @notice Error thrown when caller is not authorized to execute transaction
     */
    error NotAuthorized();

    /*//////////////////////////////////////////////////////////////////////////
                                  FUNCTIONS
    //////////////////////////////////////////////////////////////////////////*/

    /**
     * @notice Creates new generative art project
     * @param _owner Address of project owner
     * @param _initInfo Initialization information
     * @param _projectInfo Project information
     * @param _metadataInfo Metadata information
     * @param _mintInfo Array of authorized minter contracts and their reserves
     * @param _royaltyReceivers Array of addresses receiving royalties
     * @param _allocations Array of allocation amounts for calculating royalty shares
     * @param _basisPoints Total allocation scalar for calculating royalty shares
     * @return genArtToken Address of newly created FxGenArt721 proxy
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
    ) external returns (address);

    /**
     * @notice Creates new generative art project with single parameter
     * @param _creationInfo Bytes-encoded data for project creation
     * @return genArtToken Address of newly created FxGenArt721 proxy
     */
    function createProject(bytes memory _creationInfo) external returns (address);

    /**
     * @notice Creates new generative art project with new mint ticket in single transaction
     * @param _projectCreationInfo Bytes-encoded data for project creation
     * @param _ticketCreationInfo Bytes-encoded data for ticket creation
     * @param _tickeFactory Address of FxTicketFactory contract
     * @return genArtToken Address of newly created FxGenArt721 proxy
     * @return mintTicket Address of newly created FxMintTicket721 proxy
     */
    function createProjectWithTicket(
        bytes calldata _projectCreationInfo,
        bytes calldata _ticketCreationInfo,
        address _tickeFactory
    ) external returns (address, address);

    /**
     * @notice Calculates the CREATE2 address of a new FxGenArt721 proxy
     */
    function getTokenAddress(address _sender) external view returns (address);

    /**
     * @notice Returns address of current FxGenArt721 implementation contract
     */
    function implementation() external view returns (address);

    /**
     * @notice Mapping of deployer address to nonce value for precomputing token address
     */
    function nonces(address _deployer) external view returns (uint256);

    /**
     * @notice Stops new FxGenArt721 tokens from being created
     */
    function pause() external;

    /**
     * @notice Returns counter of latest project ID
     */
    function projectId() external view returns (uint96);

    /**
     * @notice Mapping of project ID to address of FxGenArt721 token contract
     */
    function projects(uint96) external view returns (address);

    /**
     * @notice Returns the address of the FxRoleRegistry contract
     */
    function roleRegistry() external view returns (address);

    /**
     * @notice Sets new FxGenArt721 implementation contract
     * @param _implementation Address of the implementation contract
     */
    function setImplementation(address _implementation) external;

    /**
     * @notice Enables new FxGenArt721 tokens from being created
     */
    function unpause() external;
}
