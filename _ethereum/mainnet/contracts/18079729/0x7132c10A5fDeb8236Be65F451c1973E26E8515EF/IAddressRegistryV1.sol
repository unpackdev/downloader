// SPDX-License-Identifier: UNLICENSED
pragma solidity >=0.8.9 <0.9.0;

//-----------------------------------------------------------------------------
/// The Address Registry allows for smart contracts to
/// verify address is not on any sanctions and/or blocked list by the application
/// owners.  For each application there will be a smart contract deployed and
/// can be communicated via this API
///
/// ## Synchronous Flow
/// ```mermaid
/// sequenceDiagram
/// CustomerContract->>IAddressRegistry: check(address)
/// IAddressRegistry->>IAddressRegistry: emit
/// note right of IAddressRegistry: The address was not found in sanctioned list
/// IAddressRegistry-->>CustomerContract: (READY, 1)
/// Oracle Server-)IAddressRegistry: Add Sanctioned Address (address)
/// IAddressRegistry->>IAddressRegistry: Update Map
/// IAddressRegistry->>IAddressRegistry: Emit Sanction Address Added
///
/// CustomerContract->>IAddressRegistry: check(address)
/// IAddressRegistry->>IAddressRegistry: Lookup address in map
/// note right of IAddressRegistry: The address found so it failed the screen
/// IAddressRegistry-->>CustomerContract: (READY, 0)
/// ```
///
/// If the lists become too large over time due many sanction/blocked addresses
/// the contract can switch to an offchain oracle response pattern.  In such a
/// case the following interaction is possible.  This will be a human driven
/// switch however it is important that the Customer Contract accounts for
/// this within their contract it could break their contracts.
///
/// ## Asynchronous Oracle Flow
/// ```mermaid
/// sequenceDiagram
/// CustomerContract->>IAddressRegistry: check(address)
/// IAddressRegistry->>IAddressRegistry: Emit Screening Check Request event
/// note right of IAddressRegistry: Oracle Server will pick up event
/// IAddressRegistry-->>CustomerContract: (PROCESSING, <uint256>ReqID)
/// Oracle Server-)IAddressRegistry: Update (ReqID, true)
/// IAddressRegistry->>IAddressRegistry: Update Map ReqID => True
/// IAddressRegistry->>IAddressRegistry: Emit Screening Check Result
/// note right of CustomerContract: Transaction triggered by waiting for check result
/// CustomerContract->>IAddressRegistry: status(ReqID)
/// IAddressRegistry-->>CustomerContract: (COMPLETE, true)
/// ```
///
/// @title Interface for Address Registry Contract
/// @author Chris Jimison
/// @notice STATUS: WORK IN PROGRESS
/// @dev To invoke any of these methods please use the following pattern:
/// `IAddressRegistryV1(address_register).functionName(arguments);`
interface IAddressRegistryV1 {
    //-------------------------------------------------------------------------
    // Enumerations
    //-------------------------------------------------------------------------

    /// @notice Due to a bug in Solidy/Docgen Enum are NOT getting picked up
    ///         in the generated output.  If you see this message in the
    ///         outputed documentation then please remove this line
    ///
    /// @dev The results enum can be used to identify if a response returned is
    /// ready to be consumed by the caller.  Because it is possible that
    /// maintaining all this data on chain is too expensive, the results enum
    /// can be used as a switch key
    ///
    /// Results Enum usages:
    ///
    /// - `READY` returned when the results can be used synchronously
    /// - `PROCESSING` returned when check requires off chain response
    /// - `COMPLETE` Used for Status checks to verify offchain request has done
    /// - `FAILED` The oracle server failed to process the async request
    /// - `ERROR` Some error happened when processing the request.
    enum ResultsEnum {
        READY,
        PROCESSING,
        COMPLETE,
        FAILED,
        ERROR
    }

    //-------------------------------------------------------------------------
    // Events
    //-------------------------------------------------------------------------

    /// @notice Emitted when a screen check/verify requires and offchain
    /// interaction. The Oracle will listen for these events on registered
    /// smart contracts and will process the request.
    /// - param address 1: The contract/caller requesting the check. Only
    /// registered contracts/address will process the request
    /// - param address 2: The address to do a screen check against
    /// - param uint256: An ID for this request.  When the oracle responses to
    /// this request that ID will be returned to map the response
    event AddressRegistryCheckRequest(address, address, uint256);

    /// @notice Emitted when the Oracle has responded to the `ScreeningCheckRequest`
    /// Other services can listen for this event and when
    /// received they can execute a transaction to use the results.
    /// - param uint256: The Request ID which has been updated.
    /// - param address: The account screened
    /// - param bool: did this account pass the screening check
    /// These results will also be stored on chain and can be accessed via
    /// the `status` function
    event AddressRegistryCheckResult(uint256, address, bool);

    /// @notice Emitted when a new address has been added to the sanctioned
    /// list.  This event can be monitored by external services to update
    /// any caches that might exist off chain.
    /// - param address: that was added to the sanctions list
    event AddressRegistrySanctionSet(address);

    /// @notice Emitted when a new address has been added to the blocked
    /// list.  This event can be monitored by external services to update
    /// any caches that might exist off chain.
    /// - param address: that was added to the blocked list
    event AddressRegistryBlockedSet(address);

    /// @notice Emitted when an existing address has been removed from the
    /// blocked list.  This event can be monitored by external services to
    /// update any caches that might exist off chain.
    /// - param address: that was removed from blocked list
    event AddressRegistryBlockedReleased(address);

    /// @notice The allow list is managed by a Merkle tree and when the
    /// root hash is updated this event will trigger with the new hash.
    /// - param bytes32: of the new hash value
    event AddressRegistryAllowUpdated(bytes32);

    /// @notice A registration of the contract for further updates
    /// from external services.
    /// - param address: the address of the contracts that is being
    /// registered.
    event ContractRegistrationRequested(address);

    //-------------------------------------------------------------------------
    // Interface Functions
    //-------------------------------------------------------------------------

    /// Check if the address is currently blocked.  This call will verify with
    /// the sanctions screening list in addition to "general blocked" list
    /// the developer might be using.
    /// @param account address to screen against
    /// @return Status of the request
    ///         <ul>
    ///             <li>
    ///                 ResultsEnum::READY The value can be used now.  The
    ///                 `uint256` value will be `1` for a passed verify or
    ///                 `0` for a failed verify call
    ///             </li>
    ///             <li>
    ///                 ResultsEnum::PROCESSING The call invoked an oracle
    ///                 request and uint256 is the request ID that the
    ///                 oracle will track and update when the verify has
    ///                 completed off chain
    ///             </li>
    ///         <ul>
    /// @return The results of check.  The context of the value is based on the
    /// `ResultsEnum` returned
    function check(address account) external returns (ResultsEnum, uint256);

    /// Verify allows the developer check if an address is on a
    /// sanctions and/or blocked list AND if the account has permission
    /// to execute the operation based on it's inclusion within an Merkle tree
    ///
    /// The order of operations is:
    /// - Proof is verified that the address has access
    /// - Not on Sanctions List
    /// - Not on blocked list
    /// @param account address to screen against
    /// @param proof from Merkle tree that says this user is valid
    /// @return Status of the request
    ///         <ul>
    ///             <li>
    ///                 ResultsEnum::READY The value can be used now.  The
    ///                 `uint256` value will be `1` for a passed verify or
    ///                 `0` for a failed verify call
    ///             </li>
    ///             <li>
    ///                 ResultsEnum::PROCESSING The call invoked an oracle
    ///                 request and uint256 is the request ID that the
    ///                 oracle will track and update when the verify has
    ///                 completed off chain
    ///             </li>
    ///         <ul>
    /// @return The results of check.  The context of the value is based on the
    /// `ResultsEnum` returned
    function verify(
        address account,
        bytes32[] memory proof
    ) external returns (ResultsEnum, uint256);

    /// Verify allows the developer check if an address is on a
    /// sanctions and/or blocked list AND if the account has permission
    /// to execute the operation based on it's inclusion within an Merkle tree
    ///
    /// The order of operations is:
    /// - Proof is verified that the address has access
    /// - Not on Sanctions List
    /// - Not on blocked list
    ///
    /// @dev this function works the same as `verify` however it will accept a
    /// `calldata` argument for the proof instead of a `memory` proof
    ///
    /// @param account address to screen against
    /// @param proof from Merkle tree that says this user is valid
    /// @return Status of the request
    ///         <ul>
    ///             <li>
    ///                 ResultsEnum::READY The value can be used now.  The
    ///                 `uint256` value will be `1` for a passed verify or
    ///                 `0` for a failed verify call
    ///             </li>
    ///             <li>
    ///                 ResultsEnum::PROCESSING The call invoked an oracle
    ///                 request and uint256 is the request ID that the
    ///                 oracle will track and update when the verify has
    ///                 completed off chain
    ///             </li>
    ///         <ul>
    /// @return The results of check.  The context of the value is based on the
    /// `ResultsEnum` returned
    function verifyCalldata(
        address account,
        bytes32[] calldata proof
    ) external returns (ResultsEnum, uint256);

    /// check if an off chain check has complete and if so what is it's response.
    /// @param reqID returned from the check based call
    /// @return Status of the request
    ///         <ul>
    ///             <li>
    ///                 ResultsEnum::PROCESSING The request is still open and
    ///                 waiting for an orcale response.  The bool response
    ///                 for the tuple will be false
    ///             </li>
    ///             <li>
    ///                 ResultsEnum::COMPLETE The request has been completed.
    ///                 The bool response is what the oracle responded to.
    ///             </li>
    ///             <li>
    ///                 ResultsEnum::ERROR The Oracle server errored out.
    ///                 This case is reserved for things like invalid arguments.
    ///             </li>
    ///             <li>
    ///                 ResultsEnum::FAILED The Oracle server could not process
    ///                 the request.  This case is reserved for things like
    ///                 permissioned problems, etc..
    ///             </li>
    ///         <ul>
    /// @return The results of check.  The context of the value is based on the
    /// `ResultsEnum` returned
    function status(uint256 reqID) external view returns (ResultsEnum, bool);

    /// Function called by contracts to register themselves for updates
    /// from external services.
    function register() external;
}
