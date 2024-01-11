// SPDX-License-Identifier: agpl-3.0
pragma solidity 0.8.5;

library LibRoles {
    // ***** SETUP *****

    /// @notice Role responsible for updating the Opium Protocol core contracts' addresses encoded in the RegistryEntities.ProtocolAddressesArgs struct
    /// @dev { See RegistryEntities.sol for a detailed description of the struct }
    bytes32 internal constant PROTOCOL_ADDRESSES_SETTER_ROLE = keccak256("RL1");

    /// @notice Role responsible for updating the RegistryEntities.ProtocolParametersArgs.noDataCancellationPeriod
    /// @dev { See RegistryEntities.sol for a detailed description of the ProtocolParametersArgs parameters }
    bytes32 internal constant NO_DATA_CANCELLATION_PERIOD_SETTER_ROLE = keccak256("RL5");

    /// @notice Role responsible for managing (adding and removing accounts) the whitelist
    bytes32 internal constant WHITELISTER_ROLE = keccak256("RL7");

    /// @notice Role responsible for updating the Registry address itself stored in the Opium Protocol core contracts that consume the Registry
    /// @dev It is the only role whose associated setter does not reside in the Registry itself but in a module inherited by its consumer contracts.
    /// @dev The registry's sole responsibility is to keep track of the accounts that have been assigned to the REGISTRY_MANAGER_ROLE role
    /// @dev { See RegistryManager.sol for further details }
    bytes32 internal constant REGISTRY_MANAGER_ROLE = keccak256("RL10");

    /// @notice Role responsible for updating (applying) new core configuration if it was changed in the registry
    bytes32 internal constant CORE_CONFIGURATION_UPDATER_ROLE = keccak256("RL18");

    // ***** RESERVE *****

    /// @notice Role responsible for updating the reserve recipient's address of the profitable execution of derivatives positions
    bytes32 internal constant EXECUTION_RESERVE_CLAIMER_ADDRESS_SETTER_ROLE = keccak256("RL2");

    /// @notice Role responsible for updating the reserve recipient's address of the redemption of market neutral positions
    bytes32 internal constant REDEMPTION_RESERVE_CLAIMER_ADDRESS_SETTER_ROLE = keccak256("RL3");

    /// @notice Role responsible for updating the fixed part (percentage) of the derivative author fees that goes to the protocol execution reserve
    bytes32 internal constant EXECUTION_RESERVE_PART_SETTER_ROLE = keccak256("RL4");

    /// @notice Role responsible for updating the maximum fee that a derivative author can set as a commission originated from the profitable execution of derivatives positions
    bytes32 internal constant DERIVATIVE_AUTHOR_EXECUTION_FEE_CAP_SETTER_ROLE = keccak256("RL8");

    /// @notice Role responsible for updating the fixed part (percentage) of the initial margin that will be deducted to the reserves during redemption of market neutral positions
    /// @notice Also sets fixed part (percentage) of this redemption reserves that goes to the protocol redemption reserve
    bytes32 internal constant REDEMPTION_RESERVE_PART_SETTER_ROLE = keccak256("RL9");

    // ***** EMERGENCY *****

    /// @notice Role responsible for globally pausing the protocol
    bytes32 internal constant GUARDIAN_ROLE = keccak256("RL6");

    /// @notice Role responsible for pausing Core.create
    bytes32 internal constant PARTIAL_CREATE_PAUSE_ROLE = keccak256("RL11");

    /// @notice Role responsible for pausing Core.mint
    bytes32 internal constant PARTIAL_MINT_PAUSE_ROLE = keccak256("RL12");

    /// @notice Role responsible for pausing Core.redeem
    bytes32 internal constant PARTIAL_REDEEM_PAUSE_ROLE = keccak256("RL13");

    /// @notice Role responsible for pausing Core.execute
    bytes32 internal constant PARTIAL_EXECUTE_PAUSE_ROLE = keccak256("RL14");

    /// @notice Role responsible for pausing Core.cancel
    bytes32 internal constant PARTIAL_CANCEL_PAUSE_ROLE = keccak256("RL15");

    /// @notice Role responsible for pausing Core.claimReserve
    bytes32 internal constant PARTIAL_CLAIM_RESERVE_PAUSE_ROLE = keccak256("RL16");

    /// @notice Role responsible for globally unpausing the protocol
    bytes32 internal constant PROTOCOL_UNPAUSER_ROLE = keccak256("RL17");
}
