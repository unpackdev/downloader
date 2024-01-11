// SPDX-License-Identifier: agpl-3.0
pragma solidity 0.8.5;

import "./IERC20Upgradeable.sol";
import "./SafeERC20Upgradeable.sol";
import "./ReentrancyGuardUpgradeable.sol";
import "./RegistryEntities.sol";
import "./RegistryManager.sol";
import "./LibDerivative.sol";
import "./LibPosition.sol";
import "./LibCalculator.sol";
import "./IOpiumProxyFactory.sol";
import "./ISyntheticAggregator.sol";
import "./IOracleAggregator.sol";
import "./ITokenSpender.sol";
import "./IRegistry.sol";
import "./IOpiumPositionToken.sol";
import "./IDerivativeLogic.sol";

/**
    Error codes:
    - C1 = ERROR_CORE_POSITION_ADDRESSES_AND_AMOUNTS_DO_NOT_MATCH
    - C2 = ERROR_CORE_WRONG_HASH
    - C3 = ERROR_CORE_WRONG_POSITION_TYPE
    - C4 = ERROR_CORE_NOT_ENOUGH_POSITIONS
    - C5 = ERROR_CORE_WRONG_MOD
    - C6 = ERROR_CORE_CANT_CANCEL_DUMMY_ORACLE_ID
    - C7 = ERROR_CORE_TICKER_WAS_CANCELLED
    - C8 = ERROR_CORE_SYNTHETIC_VALIDATION_ERROR
    - C9 = ERROR_CORE_INSUFFICIENT_P2P_BALANCE
    - C10 = ERROR_CORE_EXECUTION_BEFORE_MATURITY_NOT_ALLOWED
    - C11 = ERROR_CORE_SYNTHETIC_EXECUTION_WAS_NOT_ALLOWED
    - C12 = ERROR_CORE_NOT_ENOUGH_TOKEN_ALLOWANCE
    - C13 = ERROR_CORE_CANCELLATION_IS_NOT_ALLOWED
    - C14 = ERROR_CORE_NOT_OPIUM_FACTORY_POSITIONS
    - C15 = ERROR_CORE_RESERVE_AMOUNT_GREATER_THAN_BALANCE
    - C16 = ERROR_CORE_NO_DERIVATIVE_CREATION_IN_THE_PAST
    - C17 = ERROR_CORE_PROTOCOL_POSITION_CREATION_PAUSED
    - C18 = ERROR_CORE_PROTOCOL_POSITION_MINT_PAUSED
    - C19 = ERROR_CORE_PROTOCOL_POSITION_REDEMPTION_PAUSED
    - C20 = ERROR_CORE_PROTOCOL_POSITION_EXECUTION_PAUSED
    - C21 = ERROR_CORE_PROTOCOL_POSITION_CANCELLATION_PAUSED
    - C22 = ERROR_CORE_PROTOCOL_RESERVE_CLAIM_PAUSED
    - C23 = ERROR_CORE_MISMATCHING_DERIVATIVES
 */

/// @title Opium.Core contract creates positions, holds and distributes margin at the maturity
contract Core is ReentrancyGuardUpgradeable, RegistryManager {
    using LibDerivative for LibDerivative.Derivative;
    using LibCalculator for uint256;
    using LibPosition for bytes32;
    using SafeERC20Upgradeable for IERC20Upgradeable;

    // Emitted when Core creates a new LONG/SHORT position pair
    event LogCreated(address indexed _buyer, address indexed _seller, bytes32 indexed _derivativeHash, uint256 _amount);
    // Emitted when Core mints an amount of LONG/SHORT positions
    event LogMinted(address indexed _buyer, address indexed _seller, bytes32 indexed _derivativeHash, uint256 _amount);
    // Emitted when Core executes positions
    event LogExecuted(address indexed _positionsOwner, address indexed _positionAddress, uint256 _amount);
    // Emitted when Core cancels ticker for the first time
    event LogDerivativeHashCancelled(address indexed _positionOwner, bytes32 indexed _derivativeHash);
    // Emitted when Core cancels a position of a previously cancelled Derivative.derivativeHash
    event LogCancelled(address indexed _positionOwner, bytes32 indexed _derivativeHash, uint256 _amount);
    // Emitted when Core redeems an amount of market neutral positions
    event LogRedeemed(address indexed _positionOwner, bytes32 indexed _derivativeHash, uint256 _amount);

    RegistryEntities.ProtocolParametersArgs private protocolParametersArgs;
    RegistryEntities.ProtocolAddressesArgs private protocolAddressesArgs;

    // Key-value entity that maps a derivativeHash representing an existing derivative to its available balance (i.e: the amount of collateral that has not been claimed yet)
    mapping(bytes32 => uint256) private p2pVaults;

    // Key-value entity that maps a derivativeHash representing an existing derivative to a boolean representing whether a given derivative has been cancelled
    mapping(bytes32 => bool) private cancelledDerivatives;

    /// Key-value entity that maps a derivativeHash representing an existing derivative to its respective buyer's and seller's payouts.
    /// Both the buyer's and seller's are cached when a derivative's position is successfully executed for the first time
    /// derivativePayouts[derivativeHash][0] => buyer's payout
    /// derivativePayouts[derivativeHash][1] => seller's payout
    mapping(bytes32 => uint256[2]) private derivativePayouts;

    /// Reseves vault
    /// Key-value entity that maps an address representing a reserve recipient to a token address and the balance associated to the token address. It keeps tracks of the balances of reserve recipients (i.e: derivative authors)
    mapping(address => mapping(address => uint256)) private reservesVault;

    /// @notice It is called only once upon deployment of the contract. It sets the current Opium.Registry address and assigns the current protocol parameters stored in the Opium.Registry to the Core.protocolParametersArgs private variable {see RegistryEntities.sol for a description of the ProtocolParametersArgs struct}
    function initialize(address _registry) external initializer {
        __RegistryManager__init(_registry);
        __ReentrancyGuard_init();
        protocolParametersArgs = IRegistry(_registry).getProtocolParameters();
    }

    // ****************** EXTERNAL FUNCTIONS ******************

    // ***** GETTERS *****

    /// @notice It returns Opium.Core's internal state of the protocol parameters fetched from the Opium.Registry
    /// @dev {see RegistryEntities.sol for a description of the ProtocolParametersArgs struct}
    /// @return ProtocolParametersArgs struct including the protocol's main parameters
    function getProtocolParametersArgs() external view returns (RegistryEntities.ProtocolParametersArgs memory) {
        return protocolParametersArgs;
    }

    /// @notice It returns Opium.Core's internal state of the protocol contracts' and recipients' addresses fetched from the Opium.Registry
    /// @dev {see RegistryEntities.sol for a description of the protocolAddressesArgs struct}
    /// @return ProtocolAddressesArgs struct including the protocol's main addresses - contracts and reseves recipients
    function getProtocolAddresses() external view returns (RegistryEntities.ProtocolAddressesArgs memory) {
        return protocolAddressesArgs;
    }

    /// @notice It returns the accrued reseves of a given address denominated in a specified token
    /// @param _reseveRecipient address of the reseve recipient
    /// @param _token address of a token used as a reseve compensation
    /// @return uint256 amount of the accrued reseves denominated in the provided token
    function getReservesVaultBalance(address _reseveRecipient, address _token) external view returns (uint256) {
        return reservesVault[_reseveRecipient][_token];
    }

    /// @notice It queries the buyer's and seller's payouts for a given derivative
    /// @notice if it returns [0, 0] then the derivative has not been executed yet
    /// @param _derivativeHash bytes32 unique derivative identifier
    /// @return uint256[2] tuple containing LONG and SHORT payouts
    function getDerivativePayouts(bytes32 _derivativeHash) external view returns (uint256[2] memory) {
        return derivativePayouts[_derivativeHash];
    }

    /// @notice It queries the amount of funds allocated for a given derivative
    /// @param _derivativeHash bytes32 unique derivative identifier
    /// @return uint256 representing the remaining derivative's funds
    function getP2pDerivativeVaultFunds(bytes32 _derivativeHash) external view returns (uint256) {
        return p2pVaults[_derivativeHash];
    }

    /// @notice It checks whether a given derivative has been cancelled
    /// @param _derivativeHash bytes32 unique derivative identifier
    /// @return bool true if derivative has been cancelled, false if derivative has not been cancelled
    function isDerivativeCancelled(bytes32 _derivativeHash) external view returns (bool) {
        return cancelledDerivatives[_derivativeHash];
    }

    // ***** SETTERS *****

    /// @notice It allows to update the Opium Protocol parameters according to the current state of the Opium.Registry
    /// @dev {see RegistryEntities.sol for a description of the ProtocolParametersArgs struct}
    /// @dev should be called immediately after the deployment of the contract
    /// @dev only accounts who have been assigned the CORE_CONFIGURATION_UPDATER_ROLE { See LibRoles.sol } should be able to call the function
    function updateProtocolParametersArgs() external onlyCoreConfigurationUpdater {
        protocolParametersArgs = registry.getProtocolParameters();
    }

    /// @notice Allows to sync the Core protocol's addresses with the Registry protocol's addresses in case the registry updates at least one of them
    /// @dev {see RegistryEntities.sol for a description of the protocolAddressesArgs struct}
    /// @dev should be called immediately after the deployment of the contract
    /// @dev only accounts who have been assigned the CORE_CONFIGURATION_UPDATER_ROLE { See LibRoles.sol } should be able to call the function
    function updateProtocolAddresses() external onlyCoreConfigurationUpdater {
        protocolAddressesArgs = registry.getProtocolAddresses();
    }

    /// @notice It allows a reseve recipient to claim their entire accrued reserves
    /// @param _tokenAddress address of the ERC20 token to withdraw
    function claimReserves(address _tokenAddress) external nonReentrant {
        require(!registry.isProtocolReserveClaimPaused(), "C22");
        uint256 balance = reservesVault[msg.sender][_tokenAddress];
        reservesVault[msg.sender][_tokenAddress] = 0;
        IERC20Upgradeable(_tokenAddress).safeTransfer(msg.sender, balance);
    }

    /// @notice It allows a reserves recipient to to claim the desired amount of accrued reserves
    /// @param _tokenAddress address of the ERC20 token to withdraw
    /// @param _amount uint256 amount of reserves to withdraw
    function claimReserves(address _tokenAddress, uint256 _amount) external nonReentrant {
        require(!registry.isProtocolReserveClaimPaused(), "C22");
        uint256 balance = reservesVault[msg.sender][_tokenAddress];
        require(balance >= _amount, "C15");
        reservesVault[msg.sender][_tokenAddress] -= _amount;
        IERC20Upgradeable(_tokenAddress).safeTransfer(msg.sender, _amount);
    }

    /// @notice It deploys and mints the two erc20 contracts representing a derivative's LONG and SHORT positions { see Core._create for the business logic description }
    /// @param _derivative LibDerivative.Derivative Derivative definition
    /// @param _amount uint256 Amount of positions to create
    /// @param _positionsOwners address[2] Addresses of buyer and seller
    /// [0] - buyer address
    /// [1] - seller address
    function create(
        LibDerivative.Derivative calldata _derivative,
        uint256 _amount,
        address[2] calldata _positionsOwners
    ) external nonReentrant {
        _create(_derivative, _derivative.getDerivativeHash(), _amount, _positionsOwners);
    }

    /// @notice It can either 1) deploy AND mint 2) only mint.
    /// @notice It checks whether the ERC20 contracts representing the LONG and SHORT positions of the provided `LibDerivative.Derivative` have been deployed. If not, then it deploys the respective ERC20 contracts and mints the supplied _amount respectively to the provided buyer's and seller's accounts. If they have already been deployed, it only mints the provided _amount to the provided buyer's and seller's accounts.
    /// @dev if the position contracts have been deployed, it uses Core._create()
    /// @dev if the position contracts have deployed, it uses Core._mint()
    /// @param _derivative LibDerivative.Derivative Derivative definition
    /// @param _amount uint256 Amount of LONG and SHORT positions create and/or mint
    /// @param _positionsOwners address[2] Addresses of buyer and seller
    /// _positionsOwners[0] - buyer address -> receives LONG position
    /// _positionsOwners[1] - seller address -> receives SHORT position
    function createAndMint(
        LibDerivative.Derivative calldata _derivative,
        uint256 _amount,
        address[2] calldata _positionsOwners
    ) external nonReentrant {
        bytes32 derivativeHash = _derivative.getDerivativeHash();
        address implementationAddress = IOpiumProxyFactory(protocolAddressesArgs.opiumProxyFactory)
            .getImplementationAddress();
        (address longPositionTokenAddress, bool isLongDeployed) = derivativeHash.predictAndCheckDeterministicAddress(
            true,
            implementationAddress,
            address(protocolAddressesArgs.opiumProxyFactory)
        );
        (address shortPositionTokenAddress, bool isShortDeployed) = derivativeHash.predictAndCheckDeterministicAddress(
            false,
            implementationAddress,
            protocolAddressesArgs.opiumProxyFactory
        );
        // both erc20 positions have not been deployed
        require(isLongDeployed == isShortDeployed, "C23");
        if (!isLongDeployed) {
            _create(_derivative, derivativeHash, _amount, _positionsOwners);
        } else {
            _mint(_amount, [longPositionTokenAddress, shortPositionTokenAddress], _positionsOwners);
        }
    }

    /// @notice This function mints the provided amount of LONG/SHORT positions to msg.sender for a previously deployed pair of LONG/SHORT ERC20 contracts { see Core._mint for the business logic description }
    /// @param _amount uint256 Amount of positions to create
    /// @param _positionsAddresses address[2] Addresses of buyer and seller
    /// [0] - LONG erc20 position address
    /// [1] - SHORT erc20 position address
    /// @param _positionsOwners address[2] Addresses of buyer and seller
    /// _positionsOwners[0] - buyer address
    /// _positionsOwners[1] - seller address
    function mint(
        uint256 _amount,
        address[2] calldata _positionsAddresses,
        address[2] calldata _positionsOwners
    ) external nonReentrant {
        _mint(_amount, _positionsAddresses, _positionsOwners);
    }

    /// @notice Executes a single position of `msg.sender` with specified `positionAddress` { see Core._execute for the business logic description }
    /// @param _positionAddress address `positionAddress` of position that needs to be executed
    /// @param _amount uint256 Amount of positions to execute
    function execute(address _positionAddress, uint256 _amount) external nonReentrant {
        _execute(msg.sender, _positionAddress, _amount);
    }

    /// @notice Executes a single position of `_positionsOwner` with specified `positionAddress` { see Core._execute for the business logic description }
    /// @param _positionOwner address Address of the owner of positions
    /// @param _positionAddress address `positionAddress` of positions that needs to be executed
    /// @param _amount uint256 Amount of positions to execute
    function execute(
        address _positionOwner,
        address _positionAddress,
        uint256 _amount
    ) external nonReentrant {
        _execute(_positionOwner, _positionAddress, _amount);
    }

    /// @notice Executes several positions of `msg.sender` with different `positionAddresses` { see Core._execute for the business logic description }
    /// @param _positionsAddresses address[] `positionAddresses` of positions that need to be executed
    /// @param _amounts uint256[] Amount of positions to execute for each `positionAddress`
    function execute(address[] calldata _positionsAddresses, uint256[] calldata _amounts) external nonReentrant {
        require(_positionsAddresses.length == _amounts.length, "C1");
        for (uint256 i; i < _positionsAddresses.length; i++) {
            _execute(msg.sender, _positionsAddresses[i], _amounts[i]);
        }
    }

    /// @notice Executes several positions of `_positionsOwner` with different `positionAddresses` { see Core._execute for the business logic description }
    /// @param _positionsOwner address Address of the owner of positions
    /// @param _positionsAddresses address[] `positionAddresses` of positions that need to be executed
    /// @param _amounts uint256[] Amount of positions to execute for each `positionAddresses`
    function execute(
        address _positionsOwner,
        address[] calldata _positionsAddresses,
        uint256[] calldata _amounts
    ) external nonReentrant {
        require(_positionsAddresses.length == _amounts.length, "C1");
        for (uint256 i; i < _positionsAddresses.length; i++) {
            _execute(_positionsOwner, _positionsAddresses[i], _amounts[i]);
        }
    }

    /// @notice Redeems a single market neutral position pair { see Core._redeem for the business logic description }
    /// @param _positionsAddresses address[2] `_positionsAddresses` of the positions that need to be redeemed
    /// @param _amount uint256 Amount of tokens to redeem
    function redeem(address[2] calldata _positionsAddresses, uint256 _amount) external nonReentrant {
        _redeem(_positionsAddresses, _amount);
    }

    /// @notice Redeems several market neutral position pairs { see Core._redeem for the business logic description }
    /// @param _positionsAddresses address[2][] `_positionsAddresses` of the positions that need to be redeemed
    /// @param _amounts uint256[] Amount of tokens to redeem for each position pair
    function redeem(address[2][] calldata _positionsAddresses, uint256[] calldata _amounts) external nonReentrant {
        require(_positionsAddresses.length == _amounts.length, "C1");
        for (uint256 i = 0; i < _positionsAddresses.length; i++) {
            _redeem(_positionsAddresses[i], _amounts[i]);
        }
    }

    /// @notice It cancels the specified amount of a derivative's position { see Core._cancel for the business logic description }
    /// @param _positionAddress PositionType of positions to be canceled
    /// @param _amount uint256 Amount of positions to cancel
    function cancel(address _positionAddress, uint256 _amount) external nonReentrant {
        _cancel(_positionAddress, _amount);
    }

    /// @notice It cancels the specified amounts of a list of derivative's position { see Core._cancel for the business logic description }
    /// @param _positionsAddresses PositionTypes of positions to be cancelled
    /// @param _amounts uint256[] Amount of positions to cancel for each `positionAddress`
    function cancel(address[] calldata _positionsAddresses, uint256[] calldata _amounts) external nonReentrant {
        require(_positionsAddresses.length == _amounts.length, "C1");
        for (uint256 i; i < _positionsAddresses.length; i++) {
            _cancel(_positionsAddresses[i], _amounts[i]);
        }
    }

    // ****************** PRIVATE FUNCTIONS ******************

    // ***** SETTERS *****

    /// @notice It deploys two ERC20 contracts representing respectively the LONG and SHORT position of the provided `LibDerivative.Derivative` derivative and mints the provided amount of SHORT positions to a seller and LONG positions to a buyer
    /// @dev it can only be called if the ERC20 contracts for the derivative's positions have not yet been deployed
    /// @dev the uint256 _amount of positions to be minted can be 0 - which results in the deployment of the position contracts without any circulating supply
    /// @param _derivative LibDerivative.Derivative Derivative definition
    /// @param _derivativeHash unique identifier of a derivative which is used as a key in the p2pVaults mapping
    /// @param _amount uint256 Amount of positions to create
    /// @param _positionsOwners address[2] Addresses of buyer and seller
    /// [0] - buyer address -> receives LONG position
    /// [1] - seller address -> receives SHORT position
    function _create(
        LibDerivative.Derivative calldata _derivative,
        bytes32 _derivativeHash,
        uint256 _amount,
        address[2] calldata _positionsOwners
    ) private {
        require(block.timestamp < _derivative.endTime, "C16");
        require(!registry.isProtocolPositionCreationPaused(), "C17");

        // Validate input data against Derivative logic (`syntheticId`)
        require(IDerivativeLogic(_derivative.syntheticId).validateInput(_derivative), "C8");

        uint256[2] memory margins;
        // Get cached margin required according to logic from Opium.SyntheticAggregator
        // margins[0] - buyerMargin
        // margins[1] - sellerMargin
        (margins[0], margins[1]) = ISyntheticAggregator(protocolAddressesArgs.syntheticAggregator).getOrCacheMargin(
            _derivativeHash,
            _derivative
        );

        uint256 totalMargin = margins[0] + margins[1];
        require((totalMargin * _amount).modWithPrecisionFactor() == 0, "C5");
        uint256 totalMarginToE18 = totalMargin.mulWithPrecisionFactor(_amount);

        // Check ERC20 tokens allowance: (margins[0] + margins[1]) * amount
        // `msg.sender` must provide margin for position creation
        require(
            IERC20Upgradeable(_derivative.token).allowance(msg.sender, protocolAddressesArgs.tokenSpender) >=
                totalMarginToE18,
            "C12"
        );

        // Increment p2p positions balance by collected margin: vault += (margins[0] + margins[1]) * _amount
        _increaseP2PVault(_derivativeHash, totalMarginToE18);

        // Take ERC20 tokens from msg.sender, should never revert in correct ERC20 implementation
        ITokenSpender(protocolAddressesArgs.tokenSpender).claimTokens(
            IERC20Upgradeable(_derivative.token),
            msg.sender,
            address(this),
            totalMarginToE18
        );

        // Mint LONG and SHORT positions tokens
        IOpiumProxyFactory(protocolAddressesArgs.opiumProxyFactory).create(
            _positionsOwners[0],
            _positionsOwners[1],
            _amount,
            _derivativeHash,
            _derivative
        );

        emit LogCreated(_positionsOwners[0], _positionsOwners[1], _derivativeHash, _amount);
    }

    /// @notice It mints the provided amount of LONG and SHORT positions of a given derivative and it forwards them to the provided positions' owners
    /// @dev it can only be called if the ERC20 contracts for the derivative's positions have already been deployed
    /// @dev the uint256 _amount of positions to be minted can be 0
    /// @param _amount uint256 Amount of LONG and SHORT positions to mint
    /// @param _positionsAddresses address[2] tuple containing the addresses of the derivative's positions to be minted
    /// _positionsAddresses[0] -> erc20-based LONG position
    /// _positionsAddresses[1] - erc20-based SHORT position
    /// @param _positionsOwners address[2] Addresses of buyer and seller
    /// [0] - buyer address -> receives LONG position
    /// [1] - seller address -> receives SHORT position
    function _mint(
        uint256 _amount,
        address[2] memory _positionsAddresses,
        address[2] memory _positionsOwners
    ) private {
        require(!registry.isProtocolPositionMintingPaused(), "C18");
        IOpiumPositionToken.OpiumPositionTokenParams memory longOpiumPositionTokenParams = IOpiumPositionToken(
            _positionsAddresses[0]
        ).getPositionTokenData();
        IOpiumPositionToken.OpiumPositionTokenParams memory shortOpiumPositionTokenParams = IOpiumPositionToken(
            _positionsAddresses[1]
        ).getPositionTokenData();
        _onlyOpiumFactoryTokens(_positionsAddresses[0], longOpiumPositionTokenParams);
        _onlyOpiumFactoryTokens(_positionsAddresses[1], shortOpiumPositionTokenParams);
        require(shortOpiumPositionTokenParams.derivativeHash == longOpiumPositionTokenParams.derivativeHash, "C2");
        require(longOpiumPositionTokenParams.positionType == LibDerivative.PositionType.LONG, "C3");
        require(shortOpiumPositionTokenParams.positionType == LibDerivative.PositionType.SHORT, "C3");

        require(block.timestamp < longOpiumPositionTokenParams.derivative.endTime, "C16");

        uint256[2] memory margins;
        // Get cached margin required according to logic from Opium.SyntheticAggregator
        // margins[0] - buyerMargin
        // margins[1] - sellerMargin
        (margins[0], margins[1]) = ISyntheticAggregator(protocolAddressesArgs.syntheticAggregator).getOrCacheMargin(
            longOpiumPositionTokenParams.derivativeHash,
            longOpiumPositionTokenParams.derivative
        );

        uint256 totalMargin = margins[0] + margins[1];
        require((totalMargin * _amount).modWithPrecisionFactor() == 0, "C5");
        uint256 totalMarginToE18 = totalMargin.mulWithPrecisionFactor(_amount);

        // Check ERC20 tokens allowance: (margins[0] + margins[1]) * amount
        // `msg.sender` must provide margin for position creation
        require(
            IERC20Upgradeable(longOpiumPositionTokenParams.derivative.token).allowance(
                msg.sender,
                protocolAddressesArgs.tokenSpender
            ) >= totalMarginToE18,
            "C12"
        );

        // Increment p2p positions balance by collected margin: vault += (margins[0] + margins[1]) * _amount
        _increaseP2PVault(longOpiumPositionTokenParams.derivativeHash, totalMarginToE18);

        // Take ERC20 tokens from msg.sender, should never revert in correct ERC20 implementation
        ITokenSpender(protocolAddressesArgs.tokenSpender).claimTokens(
            IERC20Upgradeable(longOpiumPositionTokenParams.derivative.token),
            msg.sender,
            address(this),
            totalMarginToE18
        );

        // Mint LONG and SHORT positions tokens
        IOpiumProxyFactory(protocolAddressesArgs.opiumProxyFactory).mintPair(
            _positionsOwners[0],
            _positionsOwners[1],
            _positionsAddresses[0],
            _positionsAddresses[1],
            _amount
        );

        emit LogMinted(_positionsOwners[0], _positionsOwners[1], longOpiumPositionTokenParams.derivativeHash, _amount);
    }

    /// @notice It redeems the provided amount of a derivative's market neutral position pair (LONG/SHORT) owned by the msg.sender - redeeming a market neutral position pair results in an equal amount of LONG and SHORT positions being burned in exchange for their original collateral
    /// @param _positionsAddresses address[2] `positionAddresses` representing the tuple of market-neutral positions ordered in the following way:
    /// [0] LONG position
    /// [1] SHORT position
    /// @param _amount uint256 amount of the LONG and SHORT positions to be redeemed
    function _redeem(address[2] memory _positionsAddresses, uint256 _amount) private {
        require(!registry.isProtocolPositionRedemptionPaused(), "C19");
        IOpiumPositionToken.OpiumPositionTokenParams memory longOpiumPositionTokenParams = IOpiumPositionToken(
            _positionsAddresses[0]
        ).getPositionTokenData();
        IOpiumPositionToken.OpiumPositionTokenParams memory shortOpiumPositionTokenParams = IOpiumPositionToken(
            _positionsAddresses[1]
        ).getPositionTokenData();
        _onlyOpiumFactoryTokens(_positionsAddresses[0], longOpiumPositionTokenParams);
        _onlyOpiumFactoryTokens(_positionsAddresses[1], shortOpiumPositionTokenParams);
        require(shortOpiumPositionTokenParams.derivativeHash == longOpiumPositionTokenParams.derivativeHash, "C2");
        require(longOpiumPositionTokenParams.positionType == LibDerivative.PositionType.LONG, "C3");
        require(shortOpiumPositionTokenParams.positionType == LibDerivative.PositionType.SHORT, "C3");

        ISyntheticAggregator.SyntheticCache memory syntheticCache = ISyntheticAggregator(
            protocolAddressesArgs.syntheticAggregator
        ).getOrCacheSyntheticCache(
                shortOpiumPositionTokenParams.derivativeHash,
                shortOpiumPositionTokenParams.derivative
            );

        uint256 totalMargin = (syntheticCache.buyerMargin + syntheticCache.sellerMargin).mulWithPrecisionFactor(
            _amount
        );
        uint256 reserves = _computeReserves(
            syntheticCache.authorAddress,
            shortOpiumPositionTokenParams.derivative.token,
            protocolAddressesArgs.protocolRedemptionReserveClaimer,
            protocolParametersArgs.derivativeAuthorRedemptionReservePart,
            protocolParametersArgs.protocolRedemptionReservePart,
            totalMargin
        );

        _decreaseP2PVault(shortOpiumPositionTokenParams.derivativeHash, totalMargin);

        IOpiumProxyFactory(protocolAddressesArgs.opiumProxyFactory).burnPair(
            msg.sender,
            _positionsAddresses[0],
            _positionsAddresses[1],
            _amount
        );

        IERC20Upgradeable(shortOpiumPositionTokenParams.derivative.token).safeTransfer(
            msg.sender,
            totalMargin - reserves
        );

        emit LogRedeemed(msg.sender, shortOpiumPositionTokenParams.derivativeHash, _amount);
    }

    /// @notice It executes the provided amount of a derivative's position owned by a given position's owner - which results in the distribution of the position's payout and related reseves if the position is profitable and in the executed position's amount being burned regardless of its profitability
    /// @param _positionOwner address Address of the owner of positions
    /// @param _positionAddress address `_positionAddress` of the ERC20 OpiumPositionToken that needs to be executed
    /// @param _amount uint256 Amount of position to execute for the provided `positionAddress`
    function _execute(
        address _positionOwner,
        address _positionAddress,
        uint256 _amount
    ) private {
        require(!registry.isProtocolPositionExecutionPaused(), "C20");
        IOpiumPositionToken.OpiumPositionTokenParams memory opiumPositionTokenParams = IOpiumPositionToken(
            _positionAddress
        ).getPositionTokenData();
        _onlyOpiumFactoryTokens(_positionAddress, opiumPositionTokenParams);
        // Check if ticker was canceled
        require(!cancelledDerivatives[opiumPositionTokenParams.derivativeHash], "C7");
        // Check if execution is performed at a timestamp greater than or equal to the maturity date of the derivative
        require(block.timestamp >= opiumPositionTokenParams.derivative.endTime, "C10");

        // Checking whether execution is performed by `_positionsOwner` or `_positionsOwner` allowed third party executions on its behalf
        require(
            _positionOwner == msg.sender ||
                IDerivativeLogic(opiumPositionTokenParams.derivative.syntheticId).thirdpartyExecutionAllowed(
                    _positionOwner
                ),
            "C11"
        );

        // Burn executed position tokens
        IOpiumProxyFactory(protocolAddressesArgs.opiumProxyFactory).burn(_positionOwner, _positionAddress, _amount);

        // Returns payout for all positions
        uint256 payout = _computePayout(
            opiumPositionTokenParams,
            _amount,
            ISyntheticAggregator(protocolAddressesArgs.syntheticAggregator),
            IOracleAggregator(protocolAddressesArgs.oracleAggregator)
        );

        // Transfer payout
        if (payout > 0) {
            IERC20Upgradeable(opiumPositionTokenParams.derivative.token).safeTransfer(_positionOwner, payout);
        }

        emit LogExecuted(_positionOwner, _positionAddress, _amount);
    }

    /// @notice Cancels tickers, burns positions and returns margins to the position owner in case no data were provided within `protocolParametersArgs.noDataCancellationPeriod`
    /// @param _positionAddress PositionTypes of positions to be canceled
    /// @param _amount uint256[] Amount of positions to cancel for each `positionAddress`
    function _cancel(address _positionAddress, uint256 _amount) private {
        require(!registry.isProtocolPositionCancellationPaused(), "C21");
        IOpiumPositionToken.OpiumPositionTokenParams memory opiumPositionTokenParams = IOpiumPositionToken(
            _positionAddress
        ).getPositionTokenData();
        _onlyOpiumFactoryTokens(_positionAddress, opiumPositionTokenParams);

        // It's sufficient to perform all the sanity checks only if a derivative has not yet been canceled
        if (!cancelledDerivatives[opiumPositionTokenParams.derivativeHash]) {
            // Don't allow to cancel tickers with "dummy" oracleIds
            require(opiumPositionTokenParams.derivative.oracleId != address(0), "C6");

            // Check if cancellation is called after `protocolParametersArgs.noDataCancellationPeriod` and `oracleId` didn't provide the required data
            require(
                opiumPositionTokenParams.derivative.endTime + protocolParametersArgs.noDataCancellationPeriod <=
                    block.timestamp,
                "C13"
            );
            // Ensures that `Opium.OracleAggregator` has still not been provided with data after noDataCancellationperiod
            // The check needs to be performed only the first time a derivative is being canceled as to avoid preventing other parties from canceling their positions in case `Opium.OracleAggregator` receives data after the successful cancelation
            require(
                !IOracleAggregator(protocolAddressesArgs.oracleAggregator).hasData(
                    opiumPositionTokenParams.derivative.oracleId,
                    opiumPositionTokenParams.derivative.endTime
                ),
                "C13"
            );
            cancelledDerivatives[opiumPositionTokenParams.derivativeHash] = true;
            // Emit `LogDerivativeHashCancelled` event only once and mark ticker as canceled
            emit LogDerivativeHashCancelled(msg.sender, opiumPositionTokenParams.derivativeHash);
        }

        uint256 payout;
        // Check if `_positionsAddresses` is a LONG position
        if (opiumPositionTokenParams.positionType == LibDerivative.PositionType.LONG) {
            // Get cached margin required according to logic from Opium.SyntheticAggregator
            // (buyerMargin, sellerMargin) = syntheticAggregator.getMargin
            (uint256 buyerMargin, ) = ISyntheticAggregator(protocolAddressesArgs.syntheticAggregator).getOrCacheMargin(
                opiumPositionTokenParams.derivativeHash,
                opiumPositionTokenParams.derivative
            );
            // Set payout to buyerPayout
            payout = buyerMargin.mulWithPrecisionFactor(_amount);

            // Check if `positionAddress` is a SHORT position
        } else {
            // Get cached margin required according to logic from Opium.SyntheticAggregator
            // (buyerMargin, sellerMargin) = syntheticAggregator.getMargin
            (, uint256 sellerMargin) = ISyntheticAggregator(protocolAddressesArgs.syntheticAggregator).getOrCacheMargin(
                opiumPositionTokenParams.derivativeHash,
                opiumPositionTokenParams.derivative
            );
            // Set payout to sellerPayout
            payout = sellerMargin.mulWithPrecisionFactor(_amount);
        }

        _decreaseP2PVault(opiumPositionTokenParams.derivativeHash, payout);

        // Burn cancelled position tokens
        IOpiumProxyFactory(protocolAddressesArgs.opiumProxyFactory).burn(msg.sender, _positionAddress, _amount);

        // Transfer payout * _amounts[i]
        if (payout > 0) {
            IERC20Upgradeable(opiumPositionTokenParams.derivative.token).safeTransfer(msg.sender, payout);
        }

        emit LogCancelled(msg.sender, opiumPositionTokenParams.derivativeHash, _amount);
    }

    /// @notice Helper function consumed by `Core._execute` to calculate the execution's payout of a settled derivative's position
    /// @param _opiumPositionTokenParams it includes information about the derivative whose position is being executed { see OpiumPositionToken.sol for the implementation }
    /// @param _amount uint256 amount of positions of the same type (either LONG or SHORT) whose payout is being calculated
    /// @param _syntheticAggregator interface/address of `Opium SyntheticAggregator.sol`
    /// @param _oracleAggregator interface/address of `Opium OracleAggregator.sol`
    /// @return payout uint256 representing the net payout (gross payout - reserves) of the executed amount of positions
    function _computePayout(
        IOpiumPositionToken.OpiumPositionTokenParams memory _opiumPositionTokenParams,
        uint256 _amount,
        ISyntheticAggregator _syntheticAggregator,
        IOracleAggregator _oracleAggregator
    ) private returns (uint256 payout) {
        /// if the derivativePayout tuple's items (buyer payout and seller payout) are 0, it assumes it's the first time the _computePayout function is being executed, hence it fetches the payouts from the syntheticId and caches them.
        (uint256 buyerPayoutRatio, uint256 sellerPayoutRatio) = _getDerivativePayouts(
            _opiumPositionTokenParams.derivativeHash
        ); // gas saving
        if (buyerPayoutRatio == 0 && sellerPayoutRatio == 0) {
            /// fetches the derivative's data from the related oracleId
            /// opium allows the usage of "dummy" oracleIds - oracleIds whose address is null - in which case the data is set to 0
            uint256 data = _opiumPositionTokenParams.derivative.oracleId == address(0)
                ? 0
                : _oracleAggregator.getData(
                    _opiumPositionTokenParams.derivative.oracleId,
                    _opiumPositionTokenParams.derivative.endTime
                );
            // Get payout ratio from Derivative logic
            // payoutRatio[0] - buyerPayout
            // payoutRatio[1] - sellerPayout
            (buyerPayoutRatio, sellerPayoutRatio) = IDerivativeLogic(_opiumPositionTokenParams.derivative.syntheticId)
                .getExecutionPayout(_opiumPositionTokenParams.derivative, data);
            derivativePayouts[_opiumPositionTokenParams.derivativeHash] = [buyerPayoutRatio, sellerPayoutRatio]; // gas saving
        }

        ISyntheticAggregator.SyntheticCache memory syntheticCache = _syntheticAggregator.getOrCacheSyntheticCache(
            _opiumPositionTokenParams.derivativeHash,
            _opiumPositionTokenParams.derivative
        );

        uint256 positionMargin;

        // Check if `_positionType` is LONG
        if (_opiumPositionTokenParams.positionType == LibDerivative.PositionType.LONG) {
            // Calculates buyerPayout from ratio = (buyerMargin + sellerMargin) * buyerPayoutRatio / (buyerPayoutRatio + sellerPayoutRatio)
            // Set payout to buyerPayout multiplied by amount
            payout = (((syntheticCache.buyerMargin + syntheticCache.sellerMargin) * buyerPayoutRatio) /
                (buyerPayoutRatio + sellerPayoutRatio)).mulWithPrecisionFactor(_amount);
            // sets positionMargin to buyerMargin * amount
            positionMargin = syntheticCache.buyerMargin.mulWithPrecisionFactor(_amount);
            // Check if `_positionType` is a SHORT position
        } else {
            // Calculates sellerPayout from ratio = sellerPayout = (buyerMargin + sellerMargin) * sellerPayoutRatio / (buyerPayoutRatio + sellerPayoutRatio)
            // Set payout to sellerPayout multiplied by amount
            payout = (((syntheticCache.buyerMargin + syntheticCache.sellerMargin) * sellerPayoutRatio) /
                (buyerPayoutRatio + sellerPayoutRatio)).mulWithPrecisionFactor(_amount);
            // sets positionMargin to sellerMargin * amount
            positionMargin = syntheticCache.sellerMargin.mulWithPrecisionFactor(_amount);
        }

        _decreaseP2PVault(_opiumPositionTokenParams.derivativeHash, payout);

        // The reserves are deducted only from profitable positions: payout > positionMargin * amount
        if (payout > positionMargin) {
            payout =
                payout -
                _computeReserves(
                    syntheticCache.authorAddress,
                    _opiumPositionTokenParams.derivative.token,
                    protocolAddressesArgs.protocolExecutionReserveClaimer,
                    syntheticCache.authorCommission,
                    protocolParametersArgs.protocolExecutionReservePart,
                    payout - positionMargin
                );
        }
    }

    /// @notice It computes the total reserve to be distributed to the recipients provided as arguments
    /// @param _derivativeAuthorAddress address of the derivative author that receives a portion of the reserves being calculated
    /// @param _tokenAddress address of the token being used to distribute the reserves
    /// @param _protocolReserveReceiver  address of the designated recipient that receives a portion of the reserves being calculated
    /// @param _reservePercentage uint256 portion of the reserves that is being distributed from initial amount
    /// @param _protocolReservePercentage uint256 portion of the reserves that is being distributed to `_protocolReserveReceiver`
    /// @param _initialAmount uint256 the amount from which the reserves will be detracted
    /// @return totalReserve uint256 total reserves being calculated which corresponds to the sum of the reserves distributed to the derivative author and the designated recipient
    function _computeReserves(
        address _derivativeAuthorAddress,
        address _tokenAddress,
        address _protocolReserveReceiver,
        uint256 _reservePercentage,
        uint256 _protocolReservePercentage,
        uint256 _initialAmount
    ) private returns (uint256 totalReserve) {
        totalReserve = (_initialAmount * _reservePercentage) / LibCalculator.PERCENTAGE_BASE;

        // If totalReserve is zero, finish
        if (totalReserve == 0) {
            return 0;
        }

        uint256 protocolReserve = (totalReserve * _protocolReservePercentage) / LibCalculator.PERCENTAGE_BASE;

        // Update reservesVault for _protocolReserveReceiver
        reservesVault[_protocolReserveReceiver][_tokenAddress] += protocolReserve;

        // Update reservesVault for `syntheticId` author
        reservesVault[_derivativeAuthorAddress][_tokenAddress] += totalReserve - protocolReserve;
    }

    /// @notice It increases the balance associated to a given derivative stored in the p2pVaults mapping
    /// @param _derivativeHash unique identifier of a derivative which is used as a key in the p2pVaults mapping
    /// @param _amount uint256 representing how much the p2pVaults derivative's balance will increase
    function _increaseP2PVault(bytes32 _derivativeHash, uint256 _amount) private {
        p2pVaults[_derivativeHash] += _amount;
    }

    /// @notice It decreases the balance associated to a given derivative stored in the p2pVaults mapping
    /// @param _derivativeHash unique identifier of a derivative which is used as a key in the p2pVaults mapping
    /// @param _amount uint256 representing how much the p2pVaults derivative's balance will decrease
    function _decreaseP2PVault(bytes32 _derivativeHash, uint256 _amount) private {
        require(p2pVaults[_derivativeHash] >= _amount, "C9");
        p2pVaults[_derivativeHash] -= _amount;
    }

    // ***** GETTERS *****

    /// @notice ensures that a token was minted by the OpiumProxyFactory
    /// @dev usage of a private function rather than a modifier to avoid `stack too deep` error
    /// @param _tokenAddress address of the erc20 token to validate
    /// @param _opiumPositionTokenParams derivatives data of the token to validate
    function _onlyOpiumFactoryTokens(
        address _tokenAddress,
        IOpiumPositionToken.OpiumPositionTokenParams memory _opiumPositionTokenParams
    ) private view {
        address predicted = _opiumPositionTokenParams.derivativeHash.predictDeterministicAddress(
            _opiumPositionTokenParams.positionType == LibDerivative.PositionType.LONG,
            IOpiumProxyFactory(protocolAddressesArgs.opiumProxyFactory).getImplementationAddress(),
            address(protocolAddressesArgs.opiumProxyFactory)
        );
        require(_tokenAddress == predicted, "C14");
    }

    /// @notice private getter to destructure the derivativePayouts tuple. its only purpose is gas optimization
    /// @param _derivativeHash bytes32 identifier of the derivative whose payout is being fetched
    function _getDerivativePayouts(bytes32 _derivativeHash) private view returns (uint256, uint256) {
        return (derivativePayouts[_derivativeHash][0], derivativePayouts[_derivativeHash][1]);
    }

    // Reserved storage space to allow for layout changes in the future.
    uint256[50] private __gap;
}
