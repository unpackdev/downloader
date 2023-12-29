/**
 * SPDX-License-Identifier: UNLICENSED
 */
pragma solidity >=0.8.0;

import "./IQuote.sol";

/// @title IHashflowFactory
/// @author Victor Ionescu
/**
 * @notice The Factory's main purpose is to create HashflowPool contracts. Every
 * Hashflow trade happens within the context of a HashflowPool.
 *
 * The Factory tracks implementation contracts that every instance of HashflowPool,
 * delegates its function calls to.
 *
 * The Factory is configured with an instance of a HashflowRouter contract, which
 * is passed on to pools.
 */
interface IHashflowFactory is IQuote {
    /// @notice Emitted when the owner updates the authorization status of a pool creator
    /// @param poolCreator The wallet to create pools.
    /// @param authorizationStatus Whether the wallet is now authorized to create pools.
    event UpdatePoolCreatorAuthorization(
        address poolCreator,
        bool authorizationStatus
    );

    /// @notice Emitted when a pool is created.
    /// @param pool The address of the newly created pool.
    /// @param operations The Operations key that manages the pool.
    event CreatePool(address pool, address operations);

    /// @notice Emitted when the implementation of the HashflowPool contract changes.
    /// @param poolImpl The address of the new HashflowPool implementation.
    /// @param prevPoolImpl The address of the old HashflowPool implementation.
    event UpdatePoolImplementation(address poolImpl, address prevPoolImpl);

    /// @notice Initializes the Factory.
    /// @param router The Hashflow Router.
    function initialize(address router) external;

    /// @notice Returns the associated Hashflow Router.
    function router() external view returns (address);

    /// @notice Returns where a Pool Creator is authorized to create pools.
    /// @param poolCreator The address of the Pool Creator.
    /// @return Whether the creator is allowed to create pools.
    function allowedPoolCreators(address poolCreator)
        external
        view
        returns (bool);

    /// @notice Updates the authorization status for a Pool Creator.
    /// @param poolCreator The address of the Pool Creator.
    /// @param status The new authorization status.
    function updatePoolCreatorAuthorization(address poolCreator, bool status)
        external;

    /// @notice Creates a HashflowPool smart contract.
    /// @param name Name of the pool.
    /// @param signer The signer key used to validate signatures.
    /// @dev The msg.sender is the operations key that owns and manages the pool.
    function createPool(string calldata name, address signer) external;

    /**
     * @notice Updates the implementation contract that is used to create pools.
     * The update only reflects on pools that are created after this update occurs.
     * The existing pool contracts are not upgradeable.
     */
    /// @param poolImpl The address of the new implementation contract.
    function updatePoolImpl(address poolImpl) external;
}
