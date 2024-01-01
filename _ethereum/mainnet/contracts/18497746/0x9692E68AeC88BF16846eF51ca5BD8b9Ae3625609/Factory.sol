//SPDX-License-Identifier: CC-BY-NC-ND-2.5
pragma solidity 0.8.16;

import "./OwnableUpgradeable.sol";
import "./ClonesUpgradeable.sol";
import "./UUPSUpgradeable.sol";
import "./Initializable.sol";
import "./SafeERC20Upgradeable.sol";
import "./IERC20Upgradeable.sol";


import "./Venture.sol";
import "./Types.sol";
import "./NftAllocator.sol";
import "./ERC20FixedPriceAllocator.sol";
import "./IJubiERC20.sol";
import "./ERC20ManualAllocator.sol";
import "./ERC20OptionsAllocator.sol";

/**
* @title Contract factory to manage ventures
* @notice You can use this Contract to create new Ventures and Allocators
*/
contract Factory is OwnableUpgradeable, UUPSUpgradeable {
    using SafeERC20Upgradeable for IERC20Upgradeable;

    /// @notice Is the address where Jubi fees will be sent
    address public jubiFundsAddress;

    /// @notice Is the % fee jubi will be charging IE: 1% num: 1, den: 100
    Types.Fraction public jubiFeePercent;

    /// @notice A list of all ventures created by this factory
    Venture[] public ventures;

    /// @notice A list of ventures managed by this factory
    mapping(address => bool) public managedVentures;

    /// @notice The address to use when creating a new Venture
    address public ventureImpl;

    /// @notice The address to use when creating a new NftAllocator
    address public nftAllocatorImpl;

    /// @notice The address to use when creating a new SignatureStore
    address public signatureStoreNftAllocatorImpl;

    /// @notice The address to use when creating a new FixedPrice ERC20 allocator
    address public ERC20FixedPriceAllocatorImpl;

    /// @notice The address to use when creating a new SignatureStore
    address public ERC20FixedPriceAllocatorSignatureStoreImpl;

    /// @notice The address to use when creating a new FixedPrice ERC20 allocator
    address public ERC20ManualAllocatorImpl;

        /// @notice The address to use when creating a new ERC20 Options allocator
    address public ERC20OptionsAllocatorImpl;

    /**
    * @notice This event is emitted when a Venture(`venture`) is created, by `owner` with `config` at a specific `version`
    * @param owner The venture owner.
    * @param venture The venture that was created.
    * @param config The config that was used to create the Venture.
    * @param impl The ventureImpl that was used.
    */
    event VentureCreated(address indexed owner, Venture indexed venture, Types.VentureConfig config, address impl);

    /**
    * @notice This event is emitted when an NFT Allocator(`allocator`) is created, of type `allocatorType` with `config`
    * at a specific `version` it will be attached to a Venture(`venture`)
    * @param venture The venture that manages this allocator.
    * @param allocator The allocator that was created.
    * @param config The config that was used to create the Allocator.
    * @param impl The allocatorImpl that was used.
    */
    event NFTAllocatorCreated(address indexed venture, address indexed allocator, Types.AllocatorType allocatorType, Types.NftAllocatorConfig config, address impl);

    /**
    * @notice This event is emitted when an ERC20 Allocator(`allocator`) is created, of type `allocatorType` with `config`
    * at a specific `version` it will be attached to a Venture(`venture`)
    * @param venture The venture that manages this allocator.
    * @param allocator The allocator that was created.
    * @param config The config that was used to create the Allocator.
    * @param impl The allocatorImpl that was used.
    */
    event ERC20FixedPriceAllocatorCreated(address indexed venture, address indexed allocator, Types.AllocatorType allocatorType, Types.ERC20FixedPriceAllocatorConfig config, address impl);

    /**
    * @notice This event is emitted when an ERC20 Allocator(`allocator`) is created, of type `allocatorType` with `config`
    * at a specific `version` it will be attached to a Venture(`venture`)
    * @param venture The venture that manages this allocator.
    * @param allocator The allocator that was created.
    * @param config The config that was used to create the Allocator.
    * @param impl The allocatorImpl that was used.
    */
    event ERC20ManualAllocatorCreated(address indexed venture, address indexed allocator, Types.AllocatorType allocatorType, Types.AllocatorConfig config, address impl);

    /**
    * @notice This event is emitted when an ERC20 Allocator(`allocator`) is created, of type `allocatorType` with `config`
    * at a specific `version` it will be attached to a Venture(`venture`)
    * @param venture The venture that manages this allocator.
    * @param allocator The allocator that was created.
    * @param config The config that was used to create the Allocator.
    * @param impl The allocatorImpl that was used.
    */
    event ERC20OptionsAllocatorCreated(address indexed venture, address indexed allocator, Types.AllocatorType allocatorType, Types.AllocatorConfig config, address impl);

    /**
    * @notice This event is emitted when an Allocator is updated to a new impl `newImpl`
    * @param newImpl The address of the new implementation to be used
    * @param allocatorType The type of allocator that was updated
    */
    event AllocatorImplUpdated(address newImpl, Types.AllocatorType allocatorType);

    /**
    * @notice This event is emitted when the ventureImpl is updated
    * @param newImpl The address of the new implementation to be used
    */
    event VentureImplUpdated(address newImpl);


    /**
    * @notice This event is emitted when the signatureStoreImpl is updated
    * @param newImpl The address of the new implementation to be used
    */
    event SignatureStoreNftAllocatorImplUpdated(address newImpl);

    /**
    * @notice This event is emitted when the ERC20 signatureStoreImpl is updated
    * @param newImpl The address of the new implementation to be used
    */
    event ERC20FixedPriceSignatureStoreImplUpdated(address newImpl);

    /// @custom:oz-upgrades-unsafe-allow constructor
    constructor() {
        _disableInitializers();
    }

    /**
    *  @param _ventureImpl The initial address to use for Venture Clones.
    *  @param _nftAllocatorImpl The initial address to use for nftAllocator Clones.
    *  @param _ERC20FixedPriceAllocatorImpl The initial address to use for ERC20FixedPriceAllocator Clones.
    */
    function initialize(
        address _ventureImpl,
        address _nftAllocatorImpl,
        address _ERC20FixedPriceAllocatorImpl,
        address _jubiFundsAddress,
        uint128 jubiFeePercentNumerator,
        uint128 jubiFeePercentDenominator
    ) initializer public {
        __Ownable_init();
        __UUPSUpgradeable_init();
        ventureImpl = _ventureImpl;
        nftAllocatorImpl = _nftAllocatorImpl;
        ERC20FixedPriceAllocatorImpl = _ERC20FixedPriceAllocatorImpl;
        jubiFundsAddress = _jubiFundsAddress;
        jubiFeePercent.num = jubiFeePercentNumerator;
        jubiFeePercent.den = jubiFeePercentDenominator;
    }

    /**
    * @notice This function is used to set/initialize new variables upon each upgrade of the contract
    * @param _fixedPriceERC20AllocatorImpl The address of the Fixed Price ERC20 Allocator implementation.
    */
    function initializeAtUpgrade(address _fixedPriceERC20AllocatorImpl) reinitializer(2) external onlyOwner {
        /* TODO: Possibly replace calling with upgradeAndCall ?? */
        require(_fixedPriceERC20AllocatorImpl != address(0), "Factory: fixedPriceERC20AllocatorImpl cannot be 0" );
        _updateAllocatorImpl(_fixedPriceERC20AllocatorImpl, Types.AllocatorType.ERC20_FIXED_PRICE);
    }

    /**
     * @notice Sets the Jubi fee percentage.
     * @dev Only the contract owner can call this function.
     * @param _fee The new Jubi fee percentage as a fraction.
     */
    function setJubiFeePercent(Types.Fraction calldata _fee) external onlyOwner {
        jubiFeePercent.num = _fee.num;
        jubiFeePercent.den = _fee.den;
    }

    /**
    * @notice Creates a Venture with `config` as params
    * @param config The configuration to create the Venture
    *
    * Emits a {VentureCreated} event.
    */
    function createVenture(Types.VentureConfig memory config) external {
        require(config.fundsAddress != address(0), "Factory: invalid funds address");
        require(address(config.treasuryToken) != address(0), "Factory: Treasury token cannot be 0 address");
        bytes32 salt = keccak256(abi.encodePacked(msg.sender, config.fundsAddress));
        Venture venture = Venture(ClonesUpgradeable.cloneDeterministic(ventureImpl, salt));
        venture.initialize(config, msg.sender);

        ventures.push(venture);
        managedVentures[address(venture)] = true;
        emit VentureCreated(msg.sender, venture, config, ventureImpl);
    }

    /**
    * @notice Creates a NftAllocator with `config` as params
    * @param config The configuration to create the NftAllocator
    *
    * Emits a {AllocatorCreated} event.
    */
    function createNftAllocator(Types.NftAllocatorConfig memory config) external {
        Venture venture = config.venture;
        require(managedVentures[address(venture)], "Factory: invalid venture address");
        require(venture.isAdminOrAllocatorManager(msg.sender), "Factory: only venture manager can add allocator");

        NftAllocator allocator = NftAllocator(ClonesUpgradeable.clone(nftAllocatorImpl));
        allocator.initialize(jubiFundsAddress, jubiFeePercent, config, msg.sender);
        venture.addAllocator(address(allocator), uint256(Types.AllocatorType.NFT), config.tokensForAllocation);

        emit NFTAllocatorCreated(address(venture), address(allocator), Types.AllocatorType.NFT, config, nftAllocatorImpl);
    }

    /**
    * @notice Creates a NftAllocator with `config` as params
    * @param config The configuration to create the NftAllocator
    *
    * Emits a {AllocatorCreated} event.
    */
    function createERC20FixedPriceAllocator(Types.ERC20FixedPriceAllocatorConfig memory config) external {
        Venture venture = config.venture;
        require(managedVentures[address(venture)], "Factory: invalid venture address");
        require(venture.isAdminOrAllocatorManager(msg.sender), "Factory: only venture manager can add allocator");

        ERC20FixedPriceAllocator allocator = ERC20FixedPriceAllocator(ClonesUpgradeable.clone(ERC20FixedPriceAllocatorImpl));
        if (address(config.allocationToken) != address(0)) {
            IERC20Upgradeable allocationToken = IERC20Upgradeable(address(config.allocationToken));
            allocationToken.safeTransferFrom(
                msg.sender,
                address(this),
                config.tokensForAllocation
            );
            allocationToken.safeApprove(address(allocator), config.tokensForAllocation);
        }
        allocator.initialize(msg.sender, config);
        venture.addAllocator(address(allocator), uint256(Types.AllocatorType.ERC20_FIXED_PRICE), config.tokensForAllocation);

        emit ERC20FixedPriceAllocatorCreated(address(venture), address(allocator), Types.AllocatorType.ERC20_FIXED_PRICE, config, ERC20FixedPriceAllocatorImpl);
    }

     /**
    * @notice Creates a ERC20ManualAllocator with `config` as params
    * @param config The configuration to create the Allocator
    *
    * Emits a {AllocatorCreated} event.
    */
    function createERC20ManualAllocator(Types.AllocatorConfig memory config) external {
        Venture venture = config.venture;
        require(managedVentures[address(venture)], "Factory: invalid venture address");
        require(venture.isAdminOrAllocatorManager(msg.sender), "Factory: only venture manager can add allocator");

        ERC20ManualAllocator allocator = ERC20ManualAllocator(ClonesUpgradeable.clone(ERC20ManualAllocatorImpl));
        if (address(config.allocationToken) != address(0)) {
            IERC20Upgradeable allocationToken = IERC20Upgradeable(address(config.allocationToken));
            allocationToken.safeTransferFrom(
                msg.sender,
                address(this),
                config.tokensForAllocation
            );
            allocationToken.safeApprove(address(allocator), config.tokensForAllocation);
        }
        allocator.initialize(config);
        venture.addAllocator(address(allocator), uint256(Types.AllocatorType.ERC20_MANUAL), config.tokensForAllocation);

        emit ERC20ManualAllocatorCreated(address(venture), address(allocator), Types.AllocatorType.ERC20_MANUAL, config, ERC20ManualAllocatorImpl);
    }

    /**
    * @notice Creates a ERC20ManualAllocator with `config` as params
    * @param config The configuration to create the Allocator
    *
    * Emits a {AllocatorCreated} event.
    */
    function createERC20OptionsAllocator(Types.AllocatorConfig memory config) external {
        Venture venture = config.venture;
        require(managedVentures[address(venture)], "Factory: invalid venture address");
        require(venture.isAdminOrAllocatorManager(msg.sender), "Factory: only venture manager can add allocator");

        ERC20OptionsAllocator allocator = ERC20OptionsAllocator(ClonesUpgradeable.clone(ERC20OptionsAllocatorImpl));
        if (address(config.allocationToken) != address(0)) {
            IERC20Upgradeable allocationToken = IERC20Upgradeable(address(config.allocationToken));
            allocationToken.safeTransferFrom(
                msg.sender,
                address(this),
                config.tokensForAllocation
            );
            allocationToken.safeApprove(address(allocator), config.tokensForAllocation);
        }
        allocator.initialize(config);
        venture.addAllocator(address(allocator), uint256(Types.AllocatorType.ERC20_OPTIONS_ALLOCATOR), config.tokensForAllocation);

        emit ERC20OptionsAllocatorCreated(address(venture), address(allocator), Types.AllocatorType.ERC20_OPTIONS_ALLOCATOR, config, ERC20OptionsAllocatorImpl);
    }

        /**
     * @notice Mints multiple tokens to the specified recipients.
     * @param tokenAddress The address of the token contract to mint tokens from.
     * @param recipients An array of addresses to receive the minted tokens.
     * @param amounts An array of amounts to mint for each recipient.
     */
    function bulkMintTokens(address tokenAddress, address[] memory recipients, uint256[] memory amounts) public {
        require(recipients.length == amounts.length, "Each recipient must have an amount");
        IJubiERC20 token = IJubiERC20(tokenAddress);
        require(token.minters(msg.sender) || token.owner() == msg.sender, "Only minters can bulk mint tokens");
        for (uint256 i; i < recipients.length; ++i) {
            token.mint(recipients[i], amounts[i]);
        }
    }

    /// @notice Helper to get all ventures
    function getVentures() external view returns (Venture[] memory) {
        return ventures;
    }

    /**
    * @notice Updates the address of an allocator, so new Clones use it.
    * @param newImpl The new address for allocator `_type`.
    * @param _type Which allocator are we updating.
    */
    function updateAllocatorImpl(address newImpl, Types.AllocatorType _type) external onlyOwner {
        _updateAllocatorImpl(newImpl,_type);
    }

    /**
    * @notice Updates the address of ventureImpl, so new Clones use it.
    * @param newImpl The new address for allocator `_type`.
    */
    function updateVentureImpl(address newImpl) external onlyOwner {
        require(newImpl != address(0), "Factory: invalid address for new Impl");
        require(newImpl != ventureImpl, "Factory: cannot update to same version");
        ventureImpl = newImpl;
        emit VentureImplUpdated(newImpl);
    }

    /**
    * @notice Updates the address of an allocator, so new Clones use it.
    * @param newImpl The new address for allocator `_type`.
    * @param _type Which allocator are we updating.
    */
    function _updateAllocatorImpl(address newImpl, Types.AllocatorType _type) internal {
        require(newImpl != address(0), "Factory: invalid address for new Impl");
        if (_type == Types.AllocatorType.NFT) {
            require(newImpl != nftAllocatorImpl, "Factory: cannot update to same version");
            nftAllocatorImpl = newImpl;
        }
        if (_type == Types.AllocatorType.ERC20_FIXED_PRICE) {
            require(newImpl != ERC20FixedPriceAllocatorImpl, "Factory: cannot update to same version");
            ERC20FixedPriceAllocatorImpl = newImpl;
        }
        if (_type == Types.AllocatorType.ERC20_MANUAL) {
            require(newImpl != ERC20ManualAllocatorImpl, "Factory: cannot update to same version");
            ERC20ManualAllocatorImpl = newImpl;
        }
        if (_type == Types.AllocatorType.ERC20_OPTIONS_ALLOCATOR) {
            require(newImpl != ERC20OptionsAllocatorImpl, "Factory: cannot update to same version");
            ERC20OptionsAllocatorImpl = newImpl;
        }
        emit AllocatorImplUpdated(newImpl, _type);
    }

    /**
     * @dev Function that should revert when `msg.sender` is not authorized to upgrade the contract. Called by
     * {upgradeTo} and {upgradeToAndCall}.
     *
     * Normally, this function will use an xref:access.adoc[access control] modifier such as {Ownable-onlyOwner}.
     *
     * ```solidity
     * function _authorizeUpgrade(address) internal override onlyOwner {}
     * ```
     */
    function _authorizeUpgrade(address newImplementation)
        internal
        onlyOwner
        override
    {}
}

