// SPDX-License-Identifier: agpl-3.0
pragma solidity 0.8.5;

import "./AccessControlUpgradeable.sol";
import "./LibRoles.sol";
import "./LibCalculator.sol";
import "./IOpiumProxyFactory.sol";
import "./ISyntheticAggregator.sol";
import "./IOracleAggregator.sol";
import "./ITokenSpender.sol";
import "./ICore.sol";

/**
    Error codes:
    - R1 = ERROR_REGISTRY_ONLY_PROTOCOL_ADDRESSES_SETTER_ROLE
    - R2 = ERROR_REGISTRY_ONLY_EXECUTION_RESERVE_CLAIMER_ADDRESS_SETTER_ROLE
    - R3 = ERROR_REGISTRY_ONLY_REDEMPTION_RESERVE_CLAIMER_ADDRESS_SETTER_ROLE
    - R4 = ERROR_REGISTRY_ONLY_EXECUTION_RESERVE_PART_SETTER_ROLE
    - R5 = ERROR_REGISTRY_ONLY_NO_DATA_CANCELLATION_PERIOD_SETTER_ROLE
    - R6 = ERROR_REGISTRY_ONLY_GUARDIAN_ROLE
    - R7 = ERROR_REGISTRY_ONLY_WHITELISTER_ROLE
    - R8 = ERROR_REGISTRY_ONLY_DERIVATIVE_AUTHOR_EXECUTION_FEE_CAP_SETTER_ROLE
    - R9 = ERROR_REGISTRY_ONLY_REDEMPTION_RESERVE_PART_SETTER_ROLE
    - R10 = ERROR_REGISTRY_ALREADY_PAUSED
    - R11 = ERROR_REGISTRY_NOT_PAUSED
    - R12 = ERROR_REGISTRY_NULL_ADDRESS
    - R13 = ERROR_REGISTRY_ONLY_PARTIAL_CREATE_PAUSE_ROLE
    - R14 = ERROR_REGISTRY_ONLY_PARTIAL_MINT_PAUSE_ROLE
    - R15 = ERROR_REGISTRY_ONLY_PARTIAL_REDEEM_PAUSE_ROLE
    - R16 = ERROR_REGISTRY_ONLY_PARTIAL_EXECUTE_PAUSE_ROLE
    - R17 = ERROR_REGISTRY_ONLY_PARTIAL_CANCEL_PAUSE_ROLE
    - R18 = ERROR_REGISTRY_ONLY_PARTIAL_CLAIM_RESERVE_PAUSE_ROLE
    - R19 = ERROR_REGISTRY_ONLY_PROTOCOL_UNPAUSER_ROLE
    - R20 = ERROR_REGISTRY_INVALID_VALUE
 */

contract Registry is AccessControlUpgradeable {
    // Setup
    event LogNoDataCancellationPeriodChanged(address indexed _setter, uint256 indexed _noDataCancellationPeriod);
    event LogWhitelistAccountAdded(address indexed _setter, address indexed _whitelisted);
    event LogWhitelistAccountRemoved(address indexed _setter, address indexed _unlisted);
    // Reserve
    event LogProtocolExecutionReserveClaimerChanged(
        address indexed _setter,
        address indexed _protocolExecutionReserveClaimer
    );
    event LogProtocolRedemptionReserveClaimerChanged(
        address indexed _setter,
        address indexed _protocolRedemptionReserveClaimer
    );
    event LogProtocolExecutionReservePartChanged(address indexed _setter, uint32 indexed _protocolExecutionReservePart);
    event LogDerivativeAuthorExecutionFeeCapChanged(
        address indexed _setter,
        uint32 indexed _derivativeAuthorExecutionFeeCap
    );
    event LogProtocolRedemptionReservePartChanged(
        address indexed _setter,
        uint32 indexed _protocolRedemptionReservePart
    );
    event LogDerivativeAuthorRedemptionReservePartChanged(
        address indexed _setter,
        uint32 indexed _derivativeAuthorRedemptionReservePart
    );
    // Emergency
    // emits the role to signal what type of pause has been committed, if any
    event LogProtocolPausableStateChanged(address indexed _setter, bool indexed _state, bytes32 indexed _role);

    RegistryEntities.ProtocolParametersArgs private protocolParametersArgs;
    RegistryEntities.ProtocolAddressesArgs private protocolAddressesArgs;
    RegistryEntities.ProtocolPausabilityArgs private protocolPausabilityArgs;
    mapping(address => bool) private coreSpenderWhitelist;

    // ***** SETUP *****

    /// @notice it ensures that the calling account has been granted the PROTOCOL_ADDRESSES_SETTER_ROLE
    /// @dev by default, it is granted to the `governor` account
    modifier onlyProtocolAdressesSetter() {
        require(hasRole(LibRoles.PROTOCOL_ADDRESSES_SETTER_ROLE, msg.sender), "R1");
        _;
    }

    /// @notice it ensures that the calling account has been granted the NO_DATA_CANCELLATION_PERIOD_SETTER_ROLE
    /// @dev by default, it is granted to the `governor` account
    modifier onlyNoDataCancellationPeriodSetter() {
        require(hasRole(LibRoles.NO_DATA_CANCELLATION_PERIOD_SETTER_ROLE, msg.sender), "R5");
        _;
    }

    /// @notice it ensures that the calling account has been granted the WHITELISTER_ROLE
    /// @dev by default, it is granted to the `governor` account
    modifier onlyWhitelister() {
        require(hasRole(LibRoles.WHITELISTER_ROLE, msg.sender), "R7");
        _;
    }

    // ***** RESERVE *****

    /// @notice it ensures that the calling account has been granted the EXECUTION_RESERVE_CLAIMER_ADDRESS_SETTER_ROLE
    /// @dev by default, it is granted to the `governor` account
    modifier onlyProtocolExecutionReserveClaimerAddressSetter() {
        require(hasRole(LibRoles.EXECUTION_RESERVE_CLAIMER_ADDRESS_SETTER_ROLE, msg.sender), "R2");
        _;
    }

    /// @notice it ensures that the calling account has been granted the REDEMPTION_RESERVE_CLAIMER_ADDRESS_SETTER_ROLE
    /// @dev by default, it is granted to the `governor` account
    modifier onlyProtocolRedemptionReserveClaimerAddressSetter() {
        require(hasRole(LibRoles.REDEMPTION_RESERVE_CLAIMER_ADDRESS_SETTER_ROLE, msg.sender), "R3");
        _;
    }

    /// @notice it ensures that the calling account has been granted the EXECUTION_RESERVE_PART_SETTER_ROLE
    /// @dev by default, it is granted to the `governor` account
    modifier onlyProtocolExecutionReservePartSetter() {
        require(hasRole(LibRoles.EXECUTION_RESERVE_PART_SETTER_ROLE, msg.sender), "R4");
        _;
    }

    /// @notice it ensures that the calling account has been granted the DERIVATIVE_AUTHOR_EXECUTION_FEE_CAP_SETTER_ROLE
    /// @dev by default, it is granted to the `governor` account
    modifier onlyDerivativeAuthorExecutionFeeCapSetter() {
        require(hasRole(LibRoles.DERIVATIVE_AUTHOR_EXECUTION_FEE_CAP_SETTER_ROLE, msg.sender), "R8");
        _;
    }

    /// @notice it ensures that the calling account has been granted the REDEMPTION_RESERVE_PART_SETTER_ROLE
    /// @dev by default, it is granted to the `governor` account
    modifier onlyProtocolRedemptionReservePartSetter() {
        require(hasRole(LibRoles.REDEMPTION_RESERVE_PART_SETTER_ROLE, msg.sender), "R9");
        _;
    }

    // ***** EMERGENCY *****

    /// @notice it ensures that the calling account has been granted the GUARDIAN_ROLE
    /// @dev by default, it is granted to the `governor` account
    modifier onlyGuardian() {
        require(hasRole(LibRoles.GUARDIAN_ROLE, msg.sender), "R6");
        _;
    }

    /// @notice it ensures that the calling account has been granted the PARTIAL_CREATE_PAUSE_ROLE
    /// @dev by default, it is granted to the `governor` account
    modifier onlyPartialCreatePauseSetter() {
        require(hasRole(LibRoles.PARTIAL_CREATE_PAUSE_ROLE, msg.sender), "R13");
        _;
    }

    /// @notice it ensures that the calling account has been granted the PARTIAL_MINT_PAUSE_ROLE
    /// @dev by default, it is granted to the `governor` account
    modifier onlyPartialMintPauseSetter() {
        require(hasRole(LibRoles.PARTIAL_MINT_PAUSE_ROLE, msg.sender), "R14");
        _;
    }

    /// @notice it ensures that the calling account has been granted the PARTIAL_REDEEM_PAUSE_ROLE
    /// @dev by default, it is granted to the `governor` account
    modifier onlyPartialRedeemPauseSetter() {
        require(hasRole(LibRoles.PARTIAL_REDEEM_PAUSE_ROLE, msg.sender), "R15");
        _;
    }

    /// @notice it ensures that the calling account has been granted the PARTIAL_EXECUTE_PAUSE_ROLE
    /// @dev by default, it is granted to the `governor` account
    modifier onlyPartialExecutePauseSetter() {
        require(hasRole(LibRoles.PARTIAL_EXECUTE_PAUSE_ROLE, msg.sender), "R16");
        _;
    }

    /// @notice it ensures that the calling account has been granted the PARTIAL_CANCEL_PAUSE_ROLE
    /// @dev by default, it is granted to the `governor` account
    modifier onlyPartialCancelPauseSetter() {
        require(hasRole(LibRoles.PARTIAL_CANCEL_PAUSE_ROLE, msg.sender), "R17");
        _;
    }

    /// @notice it ensures that the calling account has been granted the PARTIAL_CLAIM_RESERVE_PAUSE_ROLE
    /// @dev by default, it is granted to the `governor` account
    modifier onlyPartialClaimReservePauseSetter() {
        require(hasRole(LibRoles.PARTIAL_CLAIM_RESERVE_PAUSE_ROLE, msg.sender), "R18");
        _;
    }

    /// @notice it ensures that the calling account has been granted the PROTOCOL_UNPAUSER_ROLE
    /// @dev by default, it is granted to the `governor` account
    modifier onlyProtocolUnpauserSetter() {
        require(hasRole(LibRoles.PROTOCOL_UNPAUSER_ROLE, msg.sender), "R19");
        _;
    }

    // ****************** EXTERNAL FUNCTIONS ******************

    // ***** SETTERS *****

    /// @notice it is called only once upon deployment of the contract. It initializes the DEFAULT_ADMIN_ROLE with the given governor address.
    /// @notice it sets the default ProtocolParametersArgs protocol parameters
    /// @dev internally, it assigns all the setters roles to the DEFAULT_ADMIN_ROLE and it sets the initial protocol parameters
    /// @param _governor address of the governance account which will be assigned all the roles included in the LibRoles library and the OpenZeppelin AccessControl.DEFAULT_ADMIN_ROLE
    function initialize(address _governor) external initializer {
        __AccessControl_init();

        // Setup
        _setupRole(DEFAULT_ADMIN_ROLE, _governor);
        _setupRole(LibRoles.PROTOCOL_ADDRESSES_SETTER_ROLE, _governor);
        _setupRole(LibRoles.NO_DATA_CANCELLATION_PERIOD_SETTER_ROLE, _governor);
        _setupRole(LibRoles.WHITELISTER_ROLE, _governor);
        _setupRole(LibRoles.REGISTRY_MANAGER_ROLE, _governor);
        _setupRole(LibRoles.CORE_CONFIGURATION_UPDATER_ROLE, _governor);

        // Reserve
        _setupRole(LibRoles.EXECUTION_RESERVE_CLAIMER_ADDRESS_SETTER_ROLE, _governor);
        _setupRole(LibRoles.REDEMPTION_RESERVE_CLAIMER_ADDRESS_SETTER_ROLE, _governor);
        _setupRole(LibRoles.EXECUTION_RESERVE_PART_SETTER_ROLE, _governor);
        _setupRole(LibRoles.DERIVATIVE_AUTHOR_EXECUTION_FEE_CAP_SETTER_ROLE, _governor);
        _setupRole(LibRoles.REDEMPTION_RESERVE_PART_SETTER_ROLE, _governor);

        // Emergency
        _setupRole(LibRoles.GUARDIAN_ROLE, _governor);
        _setupRole(LibRoles.PARTIAL_CREATE_PAUSE_ROLE, _governor);
        _setupRole(LibRoles.PARTIAL_MINT_PAUSE_ROLE, _governor);
        _setupRole(LibRoles.PARTIAL_REDEEM_PAUSE_ROLE, _governor);
        _setupRole(LibRoles.PARTIAL_EXECUTE_PAUSE_ROLE, _governor);
        _setupRole(LibRoles.PARTIAL_CANCEL_PAUSE_ROLE, _governor);
        _setupRole(LibRoles.PARTIAL_CLAIM_RESERVE_PAUSE_ROLE, _governor);
        _setupRole(LibRoles.PROTOCOL_UNPAUSER_ROLE, _governor);

        // Default protocol parameters
        protocolParametersArgs.noDataCancellationPeriod = 2 weeks;
        protocolParametersArgs.derivativeAuthorExecutionFeeCap = 1000; // 10%
        protocolParametersArgs.derivativeAuthorRedemptionReservePart = 10; // 0.1%
        protocolParametersArgs.protocolExecutionReservePart = 1000; // 10%
        protocolParametersArgs.protocolRedemptionReservePart = 1000; // 10%
    }

    // ** ROLE-RESTRICTED FUNCTIONS **

    // * Setup *

    /// @notice It allows the PROTOCOL_ADDRESSES_SETTER_ROLE role to set the addresses of Opium Protocol's contracts
    /// @dev It must be called as part of the protocol's deployment setup after the core addresses have been deployed
    /// @dev the contracts' addresses are set using their respective interfaces
    /// @param _opiumProxyFactory address of Opium.OpiumProxyFactory
    /// @param _core address of Opium.Core
    /// @param _oracleAggregator address of Opium.OracleAggregator
    /// @param _syntheticAggregator address of Opium.SyntheticAggregator
    /// @param _tokenSpender address of Opium.TokenSpender
    function setProtocolAddresses(
        address _opiumProxyFactory,
        address _core,
        address _oracleAggregator,
        address _syntheticAggregator,
        address _tokenSpender
    ) external onlyProtocolAdressesSetter {
        require(
            _opiumProxyFactory != address(0) &&
                _core != address(0) &&
                _oracleAggregator != address(0) &&
                _syntheticAggregator != address(0) &&
                _tokenSpender != address(0),
            "R12"
        );
        protocolAddressesArgs.opiumProxyFactory = _opiumProxyFactory;
        protocolAddressesArgs.core = _core;
        protocolAddressesArgs.oracleAggregator = _oracleAggregator;
        protocolAddressesArgs.syntheticAggregator = _syntheticAggregator;
        protocolAddressesArgs.tokenSpender = _tokenSpender;
    }

    /// @notice It allows the NO_DATA_CANCELLATION_PERIOD_SETTER_ROLE role to change the noDataCancellationPeriod (the timeframe after which a derivative can be cancelled if the oracle has not provided any data)
    function setNoDataCancellationPeriod(uint32 _noDataCancellationPeriod) external onlyNoDataCancellationPeriodSetter {
        protocolParametersArgs.noDataCancellationPeriod = _noDataCancellationPeriod;
        emit LogNoDataCancellationPeriodChanged(msg.sender, _noDataCancellationPeriod);
    }

    /// @notice It allows the WHITELISTER_ROLE to add an address to the whitelist
    function addToWhitelist(address _whitelisted) external onlyWhitelister {
        coreSpenderWhitelist[_whitelisted] = true;
        emit LogWhitelistAccountAdded(msg.sender, _whitelisted);
    }

    /// @notice It allows the WHITELISTER_ROLE to remove an address from the whitelist
    function removeFromWhitelist(address _whitelisted) external onlyWhitelister {
        coreSpenderWhitelist[_whitelisted] = false;
        emit LogWhitelistAccountRemoved(msg.sender, _whitelisted);
    }

    // * Reserve *

    /// @notice It allows the EXECUTION_RESERVE_CLAIMER_ADDRESS_SETTER_ROLE role to change the address of the recipient of execution protocol reserves
    /// @dev It must be called as part of the protocol's deployment setup after the core addresses have been deployed
    /// @dev it must be a non-null address
    /// @param _protocolExecutionReserveClaimer address that will replace the current `protocolExecutionReserveClaimer`
    function setProtocolExecutionReserveClaimer(address _protocolExecutionReserveClaimer)
        external
        onlyProtocolExecutionReserveClaimerAddressSetter
    {
        require(_protocolExecutionReserveClaimer != address(0), "R12");
        protocolAddressesArgs.protocolExecutionReserveClaimer = _protocolExecutionReserveClaimer;
        emit LogProtocolExecutionReserveClaimerChanged(msg.sender, _protocolExecutionReserveClaimer);
    }

    /// @notice It allows the REDEMPTION_RESERVE_CLAIMER_ADDRESS_SETTER_ROLE role to change the address of the recipient of redemption protocol reserves
    /// @dev It must be called as part of the protocol's deployment setup after the core addresses have been deployed
    /// @dev it must be a non-null address
    /// @param _protocolRedemptionReserveClaimer address that will replace the current `protocolAddressesArgs.protocolRedemptionReserveClaimer`
    function setProtocolRedemptionReserveClaimer(address _protocolRedemptionReserveClaimer)
        external
        onlyProtocolRedemptionReserveClaimerAddressSetter
    {
        require(_protocolRedemptionReserveClaimer != address(0), "R12");
        protocolAddressesArgs.protocolRedemptionReserveClaimer = _protocolRedemptionReserveClaimer;
        emit LogProtocolRedemptionReserveClaimerChanged(msg.sender, _protocolRedemptionReserveClaimer);
    }

    /// @notice It allows the EXECUTION_RESERVE_PART_SETTER_ROLE role to change part of derivative author reserves originated from derivative executions go to the protocol reserves
    /// @param _protocolExecutionReservePart must be less than 100%
    function setProtocolExecutionReservePart(uint32 _protocolExecutionReservePart)
        external
        onlyProtocolExecutionReservePartSetter
    {
        require(_protocolExecutionReservePart < LibCalculator.PERCENTAGE_BASE, "R20");
        protocolParametersArgs.protocolExecutionReservePart = _protocolExecutionReservePart;
        emit LogProtocolExecutionReservePartChanged(msg.sender, _protocolExecutionReservePart);
    }

    /// @notice It allows the DERIVATIVE_AUTHOR_EXECUTION_FEE_CAP_SETTER_ROLE role to change max fee that derivative author can set
    /// @param _derivativeAuthorExecutionFeeCap must be less than 100%
    function setDerivativeAuthorExecutionFeeCap(uint32 _derivativeAuthorExecutionFeeCap)
        external
        onlyDerivativeAuthorExecutionFeeCapSetter
    {
        require(_derivativeAuthorExecutionFeeCap < LibCalculator.PERCENTAGE_BASE, "R20");
        protocolParametersArgs.derivativeAuthorExecutionFeeCap = _derivativeAuthorExecutionFeeCap;
        emit LogDerivativeAuthorExecutionFeeCapChanged(msg.sender, _derivativeAuthorExecutionFeeCap);
    }

    /// @notice It allows the REDEMPTION_RESERVE_PART_SETTER_ROLE role to change part of derivative author reserves originated from redemption of market neutral positions go to the protocol reserves
    /// @param _protocolRedemptionReservePart must be less than 100%
    function setProtocolRedemptionReservePart(uint32 _protocolRedemptionReservePart)
        external
        onlyProtocolRedemptionReservePartSetter
    {
        require(_protocolRedemptionReservePart < LibCalculator.PERCENTAGE_BASE, "R20");
        protocolParametersArgs.protocolRedemptionReservePart = _protocolRedemptionReservePart;
        emit LogProtocolRedemptionReservePartChanged(msg.sender, _protocolRedemptionReservePart);
    }

    /// @notice It allows the REDEMPTION_RESERVE_PART_SETTER_ROLE role to change the fixed part (percentage) that the derivative author receives for each redemption of market neutral positions
    /// @param _derivativeAuthorRedemptionReservePart must be less than 1%
    function setDerivativeAuthorRedemptionReservePart(uint32 _derivativeAuthorRedemptionReservePart)
        external
        onlyProtocolRedemptionReservePartSetter
    {
        require(_derivativeAuthorRedemptionReservePart <= LibCalculator.MAX_REDEMPTION_PART, "R20");
        protocolParametersArgs.derivativeAuthorRedemptionReservePart = _derivativeAuthorRedemptionReservePart;
        emit LogDerivativeAuthorRedemptionReservePartChanged(msg.sender, _derivativeAuthorRedemptionReservePart);
    }

    // * Emergency *

    /// @notice It allows the GUARDIAN role to pause the entire Opium Protocol
    /// @dev it fails if the entire protocol is already paused
    function pause() external onlyGuardian {
        require(!protocolPausabilityArgs.protocolGlobal, "R10");
        protocolPausabilityArgs.protocolGlobal = true;
        emit LogProtocolPausableStateChanged(msg.sender, true, LibRoles.GUARDIAN_ROLE);
    }

    /// @notice It allows the PARTIAL_CREATE_PAUSE_ROLE role to pause the creation of positions
    /// @dev it fails if the creation of positions is paused
    function pauseProtocolPositionCreation() external onlyPartialCreatePauseSetter {
        require(!protocolPausabilityArgs.protocolPositionCreation, "R10");
        protocolPausabilityArgs.protocolPositionCreation = true;
        emit LogProtocolPausableStateChanged(msg.sender, true, LibRoles.PARTIAL_CREATE_PAUSE_ROLE);
    }

    /// @notice It allows the PARTIAL_MINT_PAUSE_ROLE role to pause the minting of positions
    /// @dev it fails if the minting of positions is paused
    function pauseProtocolPositionMinting() external onlyPartialMintPauseSetter {
        require(!protocolPausabilityArgs.protocolPositionMinting, "R10");
        protocolPausabilityArgs.protocolPositionMinting = true;
        emit LogProtocolPausableStateChanged(msg.sender, true, LibRoles.PARTIAL_MINT_PAUSE_ROLE);
    }

    /// @notice It allows the PARTIAL_REDEEM_PAUSE_ROLE role to pause the redemption of positions
    /// @dev it fails if the redemption of positions is paused
    function pauseProtocolPositionRedemption() external onlyPartialRedeemPauseSetter {
        require(!protocolPausabilityArgs.protocolPositionRedemption, "R10");
        protocolPausabilityArgs.protocolPositionRedemption = true;
        emit LogProtocolPausableStateChanged(msg.sender, true, LibRoles.PARTIAL_REDEEM_PAUSE_ROLE);
    }

    /// @notice It allows the PARTIAL_EXECUTE_PAUSE_ROLE role to pause the execution of positions
    /// @dev it fails if the execution of positions is paused
    function pauseProtocolPositionExecution() external onlyPartialExecutePauseSetter {
        require(!protocolPausabilityArgs.protocolPositionExecution, "R10");
        protocolPausabilityArgs.protocolPositionExecution = true;
        emit LogProtocolPausableStateChanged(msg.sender, true, LibRoles.PARTIAL_EXECUTE_PAUSE_ROLE);
    }

    /// @notice It allows the PARTIAL_CANCEL_PAUSE_ROLE role to pause the cancellation of positions
    /// @dev it fails if the cancellation of positions is paused
    function pauseProtocolPositionCancellation() external onlyPartialCancelPauseSetter {
        require(!protocolPausabilityArgs.protocolPositionCancellation, "R10");
        protocolPausabilityArgs.protocolPositionCancellation = true;
        emit LogProtocolPausableStateChanged(msg.sender, true, LibRoles.PARTIAL_CANCEL_PAUSE_ROLE);
    }

    /// @notice It allows the PARTIAL_CLAIM_RESERVE_PAUSE_ROLE role to pause the reserves claims
    /// @dev it fails if the reserves claims are paused
    function pauseProtocolReserveClaim() external onlyPartialClaimReservePauseSetter {
        require(!protocolPausabilityArgs.protocolReserveClaim, "R10");
        protocolPausabilityArgs.protocolReserveClaim = true;
        emit LogProtocolPausableStateChanged(msg.sender, true, LibRoles.PARTIAL_CLAIM_RESERVE_PAUSE_ROLE);
    }

    /// @notice It allows the PROTOCOL_UNPAUSER_ROLE to unpause the Opium Protocol
    function unpause() external onlyProtocolUnpauserSetter {
        delete protocolPausabilityArgs;
        emit LogProtocolPausableStateChanged(msg.sender, false, LibRoles.PROTOCOL_UNPAUSER_ROLE);
    }

    // ***** GETTERS *****

    ///@return RegistryEntities.getProtocolParameters struct that packs the protocol lifecycle parameters {see RegistryEntities comments}
    function getProtocolParameters() external view returns (RegistryEntities.ProtocolParametersArgs memory) {
        return protocolParametersArgs;
    }

    ///@return RegistryEntities.ProtocolAddressesArgs struct that packs all the interfaces of the Opium Protocol
    function getProtocolAddresses() external view returns (RegistryEntities.ProtocolAddressesArgs memory) {
        return protocolAddressesArgs;
    }

    /// @notice Returns true if msg.sender has been assigned the REGISTRY_MANAGER_ROLE role
    /// @dev it is meant to be consumed by the RegistryManager module
    /// @param _address address to be checked
    function isRegistryManager(address _address) external view returns (bool) {
        return hasRole(LibRoles.REGISTRY_MANAGER_ROLE, _address);
    }

    /// @notice Returns true if msg.sender has been assigned the CORE_CONFIGURATION_UPDATER_ROLE role
    /// @dev it is meant to be consumed by the RegistryManager module
    /// @param _address address to be checked
    function isCoreConfigurationUpdater(address _address) external view returns (bool) {
        return hasRole(LibRoles.CORE_CONFIGURATION_UPDATER_ROLE, _address);
    }

    /// @return `Opium.Core`
    function getCore() external view returns (address) {
        return address(protocolAddressesArgs.core);
    }

    /// @notice It returns whether a given address is allowed to manage Opium.Core ERC20 balances
    function isCoreSpenderWhitelisted(address _address) external view returns (bool) {
        return coreSpenderWhitelist[_address];
    }

    /// @notice It returns true if the protocol is globally paused
    function isProtocolPaused() external view returns (bool) {
        return protocolPausabilityArgs.protocolGlobal;
    }

    /// @notice It returns whether Core.create() is currently paused
    /// @return true if protocol is globally paused or if protocolPositionCreation is paused
    function isProtocolPositionCreationPaused() external view returns (bool) {
        return protocolPausabilityArgs.protocolGlobal || protocolPausabilityArgs.protocolPositionCreation;
    }

    /// @notice It returns whether Core.mint() is currently paused
    /// @return true if protocol is globally paused or if protocolPositionMinting is paused
    function isProtocolPositionMintingPaused() external view returns (bool) {
        return protocolPausabilityArgs.protocolGlobal || protocolPausabilityArgs.protocolPositionMinting;
    }

    /// @notice It returns whether Core.redeem() is currently paused
    /// @return true if protocol is globally paused or if protocolPositionRedemption is paused
    function isProtocolPositionRedemptionPaused() external view returns (bool) {
        return protocolPausabilityArgs.protocolGlobal || protocolPausabilityArgs.protocolPositionRedemption;
    }

    /// @notice It returns whether Core.execute() is currently paused
    /// @return true if protocol is globally paused or if protocolPositionExecution is paused
    function isProtocolPositionExecutionPaused() external view returns (bool) {
        return protocolPausabilityArgs.protocolGlobal || protocolPausabilityArgs.protocolPositionExecution;
    }

    /// @notice It returns whether Core.cancel() is currently paused
    /// @return true if protocol is globally paused or if protocolPositionCancellation is paused
    function isProtocolPositionCancellationPaused() external view returns (bool) {
        return protocolPausabilityArgs.protocolGlobal || protocolPausabilityArgs.protocolPositionCancellation;
    }

    /// @notice It returns whether Core.execute() is currently paused
    /// @return true if protocol is globally paused or if protocolReserveClaim is paused
    function isProtocolReserveClaimPaused() external view returns (bool) {
        return protocolPausabilityArgs.protocolGlobal || protocolPausabilityArgs.protocolReserveClaim;
    }

    // Reserved storage space to allow for layout changes in the future.
    uint256[50] private __gap;
}
