// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity ^0.6.12;
pragma experimental ABIEncoderV2;

import "./IFinder.sol";
import "./IDeployer.sol";
import "./IFactoryVersioning.sol";
import "./IRegistry.sol";
import "./IManager.sol";
import "./IERC20.sol";
import "./IDeploymentSignature.sol";
import "./IPoolDeployment.sol";
import "./IDerivativeDeployment.sol";
import "./ISelfMintingDerivativeDeployment.sol";
import "./IRole.sol";
import "./Constants.sol";
import "./Address.sol";
import "./EnumerableSet.sol";
import "./Lockable.sol";
import "./AccessControl.sol";

contract SynthereumDeployer is ISynthereumDeployer, AccessControl, Lockable {
  using Address for address;
  using EnumerableSet for EnumerableSet.AddressSet;

  bytes32 public constant MAINTAINER_ROLE = keccak256('Maintainer');

  bytes32 private constant ADMIN_ROLE = 0x00;

  bytes32 private constant POOL_ROLE = keccak256('Pool');

  bytes32 private constant MINTER_ROLE = keccak256('Minter');

  bytes32 private constant BURNER_ROLE = keccak256('Burner');

  //Describe role structure
  struct Roles {
    address admin;
    address maintainer;
  }

  //----------------------------------------
  // State variables
  //----------------------------------------

  ISynthereumFinder public synthereumFinder;

  //----------------------------------------
  // Events
  //----------------------------------------

  event PoolDeployed(
    uint8 indexed poolVersion,
    address indexed derivative,
    address indexed newPool
  );
  event DerivativeDeployed(
    uint8 indexed derivativeVersion,
    address indexed pool,
    address indexed newDerivative
  );
  event SelfMintingDerivativeDeployed(
    uint8 indexed selfMintingDerivativeVersion,
    address indexed selfMintingDerivative
  );

  //----------------------------------------
  // Modifiers
  //----------------------------------------

  modifier onlyMaintainer() {
    require(
      hasRole(MAINTAINER_ROLE, msg.sender),
      'Sender must be the maintainer'
    );
    _;
  }

  //----------------------------------------
  // Constructor
  //----------------------------------------

  /**
   * @notice Constructs the SynthereumDeployer contract
   * @param _synthereumFinder Synthereum finder contract
   * @param _roles Admin and Maintainer roles
   */
  constructor(ISynthereumFinder _synthereumFinder, Roles memory _roles) public {
    synthereumFinder = _synthereumFinder;
    _setRoleAdmin(DEFAULT_ADMIN_ROLE, DEFAULT_ADMIN_ROLE);
    _setRoleAdmin(MAINTAINER_ROLE, DEFAULT_ADMIN_ROLE);
    _setupRole(DEFAULT_ADMIN_ROLE, _roles.admin);
    _setupRole(MAINTAINER_ROLE, _roles.maintainer);
  }

  //----------------------------------------
  // External functions
  //----------------------------------------

  /**
   * @notice Deploys derivative and pool linking the contracts together
   * @param derivativeVersion Version of derivative contract
   * @param poolVersion Version of the pool contract
   * @param derivativeParamsData Input params of derivative constructor
   * @param poolParamsData Input params of pool constructor
   * @return derivative Derivative contract deployed
   * @return pool Pool contract deployed
   */
  function deployPoolAndDerivative(
    uint8 derivativeVersion,
    uint8 poolVersion,
    bytes calldata derivativeParamsData,
    bytes calldata poolParamsData
  )
    external
    override
    onlyMaintainer
    nonReentrant
    returns (IDerivativeDeployment derivative, ISynthereumPoolDeployment pool)
  {
    ISynthereumFactoryVersioning factoryVersioning = getFactoryVersioning();
    derivative = deployDerivative(
      factoryVersioning,
      derivativeVersion,
      derivativeParamsData
    );
    checkDerivativeRoles(derivative);
    pool = deployPool(
      factoryVersioning,
      poolVersion,
      derivative,
      poolParamsData
    );
    checkPoolDeployment(pool, poolVersion);
    checkPoolAndDerivativeMatching(pool, derivative, true);
    setDerivativeRoles(derivative, pool, false);
    setSyntheticTokenRoles(derivative);
    ISynthereumRegistry poolRegistry = getPoolRegistry();
    poolRegistry.register(
      pool.syntheticTokenSymbol(),
      pool.collateralToken(),
      poolVersion,
      address(pool)
    );
    emit PoolDeployed(poolVersion, address(derivative), address(pool));
    emit DerivativeDeployed(
      derivativeVersion,
      address(pool),
      address(derivative)
    );
  }

  /**
   * @notice Deploys a pool and links it with an already existing derivative
   * @param poolVersion Version of the pool contract
   * @param poolParamsData Input params of pool constructor
   * @param derivative Existing derivative contract to link with the new pool
   * @return pool Pool contract deployed
   */
  function deployOnlyPool(
    uint8 poolVersion,
    bytes calldata poolParamsData,
    IDerivativeDeployment derivative
  )
    external
    override
    onlyMaintainer
    nonReentrant
    returns (ISynthereumPoolDeployment pool)
  {
    ISynthereumFactoryVersioning factoryVersioning = getFactoryVersioning();
    pool = deployPool(
      factoryVersioning,
      poolVersion,
      derivative,
      poolParamsData
    );
    checkPoolDeployment(pool, poolVersion);
    checkPoolAndDerivativeMatching(pool, derivative, true);
    setPoolRole(derivative, pool);
    ISynthereumRegistry poolRegistry = getPoolRegistry();
    poolRegistry.register(
      pool.syntheticTokenSymbol(),
      pool.collateralToken(),
      poolVersion,
      address(pool)
    );
    emit PoolDeployed(poolVersion, address(derivative), address(pool));
  }

  /**
   * @notice Deploys a derivative and option to links it with an already existing pool
   * @param derivativeVersion Version of the derivative contract
   * @param derivativeParamsData Input params of derivative constructor
   * @param pool Existing pool contract to link with the new derivative
   * @return derivative Derivative contract deployed
   */
  function deployOnlyDerivative(
    uint8 derivativeVersion,
    bytes calldata derivativeParamsData,
    ISynthereumPoolDeployment pool
  )
    external
    override
    onlyMaintainer
    nonReentrant
    returns (IDerivativeDeployment derivative)
  {
    ISynthereumFactoryVersioning factoryVersioning = getFactoryVersioning();
    derivative = deployDerivative(
      factoryVersioning,
      derivativeVersion,
      derivativeParamsData
    );
    checkDerivativeRoles(derivative);
    if (address(pool) != address(0)) {
      checkPoolAndDerivativeMatching(pool, derivative, false);
      checkPoolRegistration(pool);
      setDerivativeRoles(derivative, pool, false);
    } else {
      setDerivativeRoles(derivative, pool, true);
    }
    setSyntheticTokenRoles(derivative);
    emit DerivativeDeployed(
      derivativeVersion,
      address(pool),
      address(derivative)
    );
  }

  /**
   * @notice Deploys a self minting derivative contract
   * @param selfMintingDerVersion Version of the self minting derivative contract
   * @param selfMintingDerParamsData Input params of self minting derivative constructor
   * @return selfMintingDerivative Self minting derivative contract deployed
   */
  function deployOnlySelfMintingDerivative(
    uint8 selfMintingDerVersion,
    bytes calldata selfMintingDerParamsData
  )
    external
    override
    onlyMaintainer
    nonReentrant
    returns (ISelfMintingDerivativeDeployment selfMintingDerivative)
  {
    ISynthereumFactoryVersioning factoryVersioning = getFactoryVersioning();
    selfMintingDerivative = deploySelfMintingDerivative(
      factoryVersioning,
      selfMintingDerVersion,
      selfMintingDerParamsData
    );
    checkSelfMintingDerivativeDeployment(
      selfMintingDerivative,
      selfMintingDerVersion
    );
    address tokenCurrency = address(selfMintingDerivative.tokenCurrency());
    addSyntheticTokenRoles(tokenCurrency, address(selfMintingDerivative));
    ISynthereumRegistry selfMintingRegistry = getSelfMintingRegistry();
    selfMintingRegistry.register(
      selfMintingDerivative.syntheticTokenSymbol(),
      selfMintingDerivative.collateralCurrency(),
      selfMintingDerVersion,
      address(selfMintingDerivative)
    );
    emit SelfMintingDerivativeDeployed(
      selfMintingDerVersion,
      address(selfMintingDerivative)
    );
  }

  //----------------------------------------
  // Internal functions
  //----------------------------------------

  /**
   * @notice Deploys a derivative contract of a particular version
   * @param factoryVersioning factory versioning contract
   * @param derivativeVersion Version of derivate contract to deploy
   * @param derivativeParamsData Input parameters of constructor of derivative
   * @return derivative Derivative deployed
   */
  function deployDerivative(
    ISynthereumFactoryVersioning factoryVersioning,
    uint8 derivativeVersion,
    bytes memory derivativeParamsData
  ) internal returns (IDerivativeDeployment derivative) {
    address derivativeFactory =
      factoryVersioning.getFactoryVersion(
        FactoryInterfaces.DerivativeFactory,
        derivativeVersion
      );
    bytes memory derivativeDeploymentResult =
      derivativeFactory.functionCall(
        abi.encodePacked(
          getDeploymentSignature(derivativeFactory),
          derivativeParamsData
        ),
        'Wrong derivative deployment'
      );
    derivative = IDerivativeDeployment(
      abi.decode(derivativeDeploymentResult, (address))
    );
  }

  /**
   * @notice Deploys a pool contract of a particular version
   * @param factoryVersioning factory versioning contract
   * @param poolVersion Version of pool contract to deploy
   * @param poolParamsData Input parameters of constructor of the pool
   * @return pool Pool deployed
   */
  function deployPool(
    ISynthereumFactoryVersioning factoryVersioning,
    uint8 poolVersion,
    IDerivativeDeployment derivative,
    bytes memory poolParamsData
  ) internal returns (ISynthereumPoolDeployment pool) {
    address poolFactory =
      factoryVersioning.getFactoryVersion(
        FactoryInterfaces.PoolFactory,
        poolVersion
      );
    bytes memory poolDeploymentResult =
      poolFactory.functionCall(
        abi.encodePacked(
          getDeploymentSignature(poolFactory),
          bytes32(uint256(address(derivative))),
          poolParamsData
        ),
        'Wrong pool deployment'
      );
    pool = ISynthereumPoolDeployment(
      abi.decode(poolDeploymentResult, (address))
    );
  }

  /**
   * @notice Deploys a self minting derivative contract of a particular version
   * @param factoryVersioning factory versioning contract
   * @param selfMintingDerVersion Version of self minting derivate contract to deploy
   * @param selfMintingDerParamsData Input parameters of constructor of self minting derivative
   * @return selfMintingDerivative Self minting derivative deployed
   */
  function deploySelfMintingDerivative(
    ISynthereumFactoryVersioning factoryVersioning,
    uint8 selfMintingDerVersion,
    bytes calldata selfMintingDerParamsData
  ) internal returns (ISelfMintingDerivativeDeployment selfMintingDerivative) {
    address selfMintingDerFactory =
      factoryVersioning.getFactoryVersion(
        FactoryInterfaces.SelfMintingFactory,
        selfMintingDerVersion
      );
    bytes memory selfMintingDerDeploymentResult =
      selfMintingDerFactory.functionCall(
        abi.encodePacked(
          getDeploymentSignature(selfMintingDerFactory),
          selfMintingDerParamsData
        ),
        'Wrong self-minting derivative deployment'
      );
    selfMintingDerivative = ISelfMintingDerivativeDeployment(
      abi.decode(selfMintingDerDeploymentResult, (address))
    );
  }

  /**
   * @notice Grants admin role of derivative contract to Manager contract
   * Assing POOL_ROLE of the derivative contract to a pool if bool set to True
   * @param derivative Derivative contract
   * @param pool Pool contract
   * @param isOnlyDerivative A boolean value that can be set to true/false
   */
  function setDerivativeRoles(
    IDerivativeDeployment derivative,
    ISynthereumPoolDeployment pool,
    bool isOnlyDerivative
  ) internal {
    IRole derivativeRoles = IRole(address(derivative));
    if (!isOnlyDerivative) {
      derivativeRoles.grantRole(POOL_ROLE, address(pool));
    }
    derivativeRoles.grantRole(ADMIN_ROLE, address(getManager()));
    derivativeRoles.renounceRole(ADMIN_ROLE, address(this));
  }

  /**
   * @notice Sets roles of the synthetic token contract to a derivative
   * @param derivative Derivative contract
   */
  function setSyntheticTokenRoles(IDerivativeDeployment derivative) internal {
    IRole tokenCurrency = IRole(address(derivative.tokenCurrency()));
    if (
      !tokenCurrency.hasRole(MINTER_ROLE, address(derivative)) ||
      !tokenCurrency.hasRole(BURNER_ROLE, address(derivative))
    ) {
      addSyntheticTokenRoles(address(tokenCurrency), address(derivative));
    }
  }

  /**
   * @notice Grants minter and burner role of syntehtic token to derivative
   * @param tokenCurrency Address of the token contract
   * @param derivative Derivative contract
   */
  function addSyntheticTokenRoles(address tokenCurrency, address derivative)
    internal
  {
    ISynthereumManager manager = getManager();
    address[] memory contracts = new address[](2);
    bytes32[] memory roles = new bytes32[](2);
    address[] memory accounts = new address[](2);
    contracts[0] = tokenCurrency;
    contracts[1] = tokenCurrency;
    roles[0] = MINTER_ROLE;
    roles[1] = BURNER_ROLE;
    accounts[0] = derivative;
    accounts[1] = derivative;
    manager.grantSynthereumRole(contracts, roles, accounts);
  }

  /**
   * @notice Grants pool role of derivative to pool
   * @param derivative Derivative contract
   * @param pool Pool contract
   */
  function setPoolRole(
    IDerivativeDeployment derivative,
    ISynthereumPoolDeployment pool
  ) internal {
    ISynthereumManager manager = getManager();
    address[] memory contracts = new address[](1);
    bytes32[] memory roles = new bytes32[](1);
    address[] memory accounts = new address[](1);
    contracts[0] = address(derivative);
    roles[0] = POOL_ROLE;
    accounts[0] = address(pool);
    manager.grantSynthereumRole(contracts, roles, accounts);
  }

  //----------------------------------------
  // Internal view functions
  //----------------------------------------

  /**
   * @notice Get factory versioning contract from the finder
   * @return factoryVersioning Factory versioning contract
   */
  function getFactoryVersioning()
    internal
    view
    returns (ISynthereumFactoryVersioning factoryVersioning)
  {
    factoryVersioning = ISynthereumFactoryVersioning(
      synthereumFinder.getImplementationAddress(
        SynthereumInterfaces.FactoryVersioning
      )
    );
  }

  /**
   * @notice Get pool registry contract from the finder
   * @return poolRegistry Registry of pools
   */
  function getPoolRegistry()
    internal
    view
    returns (ISynthereumRegistry poolRegistry)
  {
    poolRegistry = ISynthereumRegistry(
      synthereumFinder.getImplementationAddress(
        SynthereumInterfaces.PoolRegistry
      )
    );
  }

  /**
   * @notice Get self minting registry contract from the finder
   * @return selfMintingRegistry Registry of self-minting derivatives
   */
  function getSelfMintingRegistry()
    internal
    view
    returns (ISynthereumRegistry selfMintingRegistry)
  {
    selfMintingRegistry = ISynthereumRegistry(
      synthereumFinder.getImplementationAddress(
        SynthereumInterfaces.SelfMintingRegistry
      )
    );
  }

  /**
   * @notice Get manager contract from the finder
   * @return manager Synthereum manager
   */
  function getManager() internal view returns (ISynthereumManager manager) {
    manager = ISynthereumManager(
      synthereumFinder.getImplementationAddress(SynthereumInterfaces.Manager)
    );
  }

  /**
   * @notice Get signature of function to deploy a contract
   * @param factory Factory contract
   * @return signature Signature of deployment function of the factory
   */
  function getDeploymentSignature(address factory)
    internal
    view
    returns (bytes4 signature)
  {
    signature = IDeploymentSignature(factory).deploymentSignature();
  }

  /**
   * @notice Check derivative roles temporarily assigned to the deployer
   * @param derivative Derivative contract
   */
  function checkDerivativeRoles(IDerivativeDeployment derivative)
    internal
    view
  {
    address[] memory derivativeAdmins = derivative.getAdminMembers();
    require(derivativeAdmins.length == 1, 'The derivative must have one admin');
    require(
      derivativeAdmins[0] == address(this),
      'The derivative admin must be the deployer'
    );
    address[] memory derivativePools = derivative.getPoolMembers();
    require(derivativePools.length == 0, 'The derivative must have no pools');
  }

  /**
   * @notice Check correct finder and version of the deployed pool
   * @param pool Contract pool to check
   * @param version Pool version to check
   */
  function checkPoolDeployment(ISynthereumPoolDeployment pool, uint8 version)
    internal
    view
  {
    require(
      pool.synthereumFinder() == synthereumFinder,
      'Wrong finder in pool deployment'
    );
    require(pool.version() == version, 'Wrong version in pool deployment');
  }

  /**
   * @notice Check correct collateral and synthetic token matching between pool and derivative
   * @param pool Pool contract
   * @param derivative Derivative contract
   * @param isPoolLinked Flag that defines if pool is linked with derivative
   */
  function checkPoolAndDerivativeMatching(
    ISynthereumPoolDeployment pool,
    IDerivativeDeployment derivative,
    bool isPoolLinked
  ) internal view {
    require(
      pool.collateralToken() == derivative.collateralCurrency(),
      'Wrong collateral matching'
    );
    require(
      pool.syntheticToken() == derivative.tokenCurrency(),
      'Wrong synthetic token matching'
    );
    if (isPoolLinked) {
      require(
        pool.isDerivativeAdmitted(address(derivative)),
        'Pool doesnt support derivative'
      );
    }
  }

  /**
   * @notice Check correct registration of a pool with PoolRegistry
   * @param pool Contract pool to check
   */
  function checkPoolRegistration(ISynthereumPoolDeployment pool) internal view {
    ISynthereumRegistry poolRegistry = getPoolRegistry();
    require(
      poolRegistry.isDeployed(
        pool.syntheticTokenSymbol(),
        pool.collateralToken(),
        pool.version(),
        address(pool)
      ),
      'Pool not registred'
    );
  }

  /**
   * @notice Check correct finder and version of the deployed self minting derivative
   * @param selfMintingDerivative Self minting derivative to check
   * @param version Self minting derivative version to check
   */
  function checkSelfMintingDerivativeDeployment(
    ISelfMintingDerivativeDeployment selfMintingDerivative,
    uint8 version
  ) internal view {
    require(
      selfMintingDerivative.synthereumFinder() == synthereumFinder,
      'Wrong finder in self-minting deployment'
    );
    require(
      selfMintingDerivative.version() == version,
      'Wrong version in self-minting deployment'
    );
  }
}
