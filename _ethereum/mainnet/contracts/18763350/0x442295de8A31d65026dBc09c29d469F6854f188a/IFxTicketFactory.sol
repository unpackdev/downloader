// SPDX-License-Identifier: MIT
pragma solidity 0.8.23;

import "./Structs.sol";

/**
 * @title IFxTicketFactory
 * @author fx(hash)
 * @notice Factory for managing newly deployed FxMintTicket721 tokens
 */
interface IFxTicketFactory {
    /*//////////////////////////////////////////////////////////////////////////
                                  EVENTS
    //////////////////////////////////////////////////////////////////////////*/

    /**
     * @notice Event emitted when the minimum grace period is updated
     * @param _owner Address of the factory owner
     * @param _gracePeriod Time duration of the new grace period
     */
    event GracePeriodUpdated(address indexed _owner, uint48 indexed _gracePeriod);

    /**
     * @notice Event emitted when the FxMintTicket721 implementation contract is updated
     * @param _owner Address of the factory owner
     * @param _implementation Address of the new FxMintTicket721 implementation contract
     */
    event ImplementationUpdated(address indexed _owner, address indexed _implementation);

    /**
     * @notice Event emitted when new FxMintTicket721 is created
     * @param _ticketId ID of the ticket contract
     * @param _mintTicket Address of newly deployed FxMintTicket721 token contract
     * @param _owner Address of ticket owner
     */
    event TicketCreated(uint96 indexed _ticketId, address indexed _mintTicket, address indexed _owner);

    /*//////////////////////////////////////////////////////////////////////////
                                  ERRORS
    //////////////////////////////////////////////////////////////////////////*/

    /**
     * @notice Error thrown when grace period is less than minimum requirement of one day
     */
    error InvalidGracePeriod();

    /**
     * @notice Error thrown when owner is zero address
     */
    error InvalidOwner();

    /**
     * @notice Error thrown when redeemer contract is zero address
     */
    error InvalidRedeemer();

    /**
     * @notice Error thrown when renderer contract is zero address
     */
    error InvalidRenderer();

    /**
     * @notice Error thrown when token contract is zero address
     */
    error InvalidToken();

    /*//////////////////////////////////////////////////////////////////////////
                                  FUNCTIONS
    //////////////////////////////////////////////////////////////////////////*/

    /**
     * @notice Creates new mint ticket
     * @param _owner Address of project owner
     * @param _genArt721 Address of GenArt721 token contract
     * @param _redeemer Address of TicketRedeemer minter contract
     * @param _redeemer Address of renderer contract
     * @param _gracePeriod Duration of time before token enters harberger taxation
     * @param _mintInfo Array of authorized minter contracts and their reserves
     */
    function createTicket(
        address _owner,
        address _genArt721,
        address _redeemer,
        address _renderer,
        uint48 _gracePeriod,
        MintInfo[] memory _mintInfo
    ) external returns (address);

    /**
     * @notice Creates new mint ticket for new generative art project in single transaction
     * @param _creationInfo Bytes-encoded data for ticket creation
     * @return mintTicket Address of newly created FxMintTicket721 proxy
     */
    function createTicket(bytes calldata _creationInfo) external returns (address);

    /**
     * @notice Calculates the CREATE2 address of a new FxMintTicket721 proxy
     */
    function getTicketAddress(address _sender) external view returns (address);

    /**
     * @notice Returns address of current FxMintTicket721 implementation contract
     */
    function implementation() external view returns (address);

    /**
     * @notice Returns the minimum duration of time before a ticket enters harberger taxation
     */
    function minGracePeriod() external view returns (uint48);

    /**
     * @notice Mapping of deployer address to nonce value for precomputing ticket address
     */
    function nonces(address _deployer) external view returns (uint256);

    /**
     * @notice Sets the new minimum grace period
     * @param _gracePeriod Minimum time duration before a ticket enters harberger taxation
     */
    function setMinGracePeriod(uint48 _gracePeriod) external;

    /**
     * @notice Sets new FxMintTicket721 implementation contract
     * @param _implementation Address of the implementation contract
     */
    function setImplementation(address _implementation) external;

    /**
     * @notice Returns counter of latest token ID
     */
    function ticketId() external view returns (uint48);

    /**
     * @notice Mapping of token ID to address of FxMintTicket721 token contract
     */
    function tickets(uint48 _ticketId) external view returns (address);
}
