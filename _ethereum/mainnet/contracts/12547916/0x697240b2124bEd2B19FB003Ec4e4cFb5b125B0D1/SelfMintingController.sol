// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity ^0.6.12;
pragma experimental ABIEncoderV2;

import "./IFinder.sol";
import "./ISelfMintingController.sol";
import "./IRegistry.sol";
import "./ISelfMintingDerivativeDeployment.sol";
import "./IFactoryVersioning.sol";
import "./Constants.sol";
import "./FixedPoint.sol";
import "./AccessControl.sol";

/**
 * @title SelfMintingController
 * Set capMintAmount, capDepositRatio and daofee of each self-minting derivative
 */
contract SelfMintingController is ISelfMintingController, AccessControl {
  bytes32 public constant MAINTAINER_ROLE = keccak256('Maintainer');

  //Describe role structure
  struct Roles {
    address admin;
    address maintainer;
  }

  //----------------------------------------
  // Storage
  //----------------------------------------

  ISynthereumFinder public synthereumFinder;

  mapping(address => uint256) private capMint;

  mapping(address => uint256) private capDeposit;

  mapping(address => DaoFee) private fee;

  //----------------------------------------
  // Events
  //----------------------------------------

  event SetCapMintAmount(
    address indexed selfMintingDerivative,
    uint256 capMintAmount
  );

  event SetCapDepositRatio(
    address indexed selfMintingDerivative,
    uint256 capDepositRatio
  );

  event SetDaoFee(address indexed selfMintingDerivative, DaoFee daoFee);

  event SetDaoFeePercentage(
    address indexed selfMintingDerivative,
    uint256 daoFeePercentage
  );

  event SetDaoFeeRecipient(
    address indexed selfMintingDerivative,
    address daoFeeRecipient
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

  modifier onlyMaintainerOrSelfMintingFactory() {
    if (hasRole(MAINTAINER_ROLE, msg.sender)) {
      _;
    } else {
      ISynthereumFactoryVersioning factoryVersioning =
        ISynthereumFactoryVersioning(
          synthereumFinder.getImplementationAddress(
            SynthereumInterfaces.FactoryVersioning
          )
        );
      uint256 numberOfFactories =
        factoryVersioning.numberOfVerisonsOfFactory(
          FactoryInterfaces.SelfMintingFactory
        );
      uint256 counter = 0;
      for (uint8 i = 0; counter < numberOfFactories; i++) {
        try
          factoryVersioning.getFactoryVersion(
            FactoryInterfaces.SelfMintingFactory,
            i
          )
        returns (address factory) {
          if (msg.sender == factory) {
            _;
            break;
          } else {
            counter++;
          }
        } catch {}
      }
      if (numberOfFactories == counter) {
        revert('Sender must be the maintainer or a self-minting factory');
      }
    }
  }

  //----------------------------------------
  // Constructor
  //----------------------------------------

  /**
   * @notice Constructs the SynthereumManager contract
   * @param _synthereumFinder Synthereum finder contract
   * @param _roles Admin and maintainer roles
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
   * @notice Allow to set capMintAmount on a list of registered self-minting derivatives
   * @param selfMintingDerivatives Self-minting derivatives
   * @param capMintAmounts Mint cap amounts for self-minting derivatives
   */
  function setCapMintAmount(
    address[] calldata selfMintingDerivatives,
    uint256[] calldata capMintAmounts
  ) external override onlyMaintainerOrSelfMintingFactory {
    uint256 selfMintingDerCount = selfMintingDerivatives.length;
    require(selfMintingDerCount > 0, 'No self-minting derivatives passed');
    require(
      selfMintingDerCount == capMintAmounts.length,
      'Number of derivatives and mint cap amounts must be the same'
    );
    for (uint256 j; j < selfMintingDerCount; j++) {
      ISelfMintingDerivativeDeployment selfMintingDerivative =
        ISelfMintingDerivativeDeployment(selfMintingDerivatives[j]);
      if (hasRole(MAINTAINER_ROLE, msg.sender)) {
        checkSelfMintingDerivativeRegistration(selfMintingDerivative);
      }
      _setCapMintAmount(address(selfMintingDerivative), capMintAmounts[j]);
    }
  }

  /**
   * @notice Allow to set capDepositRatio on a list of registered self-minting derivatives
   * @param selfMintingDerivatives Self-minting derivatives
   * @param capDepositRatios Deposit caps ratios for self-minting derivatives
   */
  function setCapDepositRatio(
    address[] calldata selfMintingDerivatives,
    uint256[] calldata capDepositRatios
  ) external override onlyMaintainerOrSelfMintingFactory {
    uint256 selfMintingDerCount = selfMintingDerivatives.length;
    require(selfMintingDerCount > 0, 'No self-minting derivatives passed');
    require(
      selfMintingDerCount == capDepositRatios.length,
      'Number of derivatives and deposit cap ratios must be the same'
    );
    for (uint256 j; j < selfMintingDerCount; j++) {
      ISelfMintingDerivativeDeployment selfMintingDerivative =
        ISelfMintingDerivativeDeployment(selfMintingDerivatives[j]);
      if (hasRole(MAINTAINER_ROLE, msg.sender)) {
        checkSelfMintingDerivativeRegistration(selfMintingDerivative);
      }
      _setCapDepositRatio(address(selfMintingDerivative), capDepositRatios[j]);
    }
  }

  /**
   * @notice Allow to set Dao fees on a list of registered self-minting derivatives
   * @param selfMintingDerivatives Self-minting derivatives
   * @param daoFees Dao fees for self-minting derivatives
   */
  function setDaoFee(
    address[] calldata selfMintingDerivatives,
    DaoFee[] calldata daoFees
  ) external override onlyMaintainerOrSelfMintingFactory {
    uint256 selfMintingDerCount = selfMintingDerivatives.length;
    require(selfMintingDerCount > 0, 'No self-minting derivatives passed');
    require(
      selfMintingDerCount == daoFees.length,
      'Number of derivatives and Dao fees must be the same'
    );
    for (uint256 j; j < selfMintingDerCount; j++) {
      ISelfMintingDerivativeDeployment selfMintingDerivative =
        ISelfMintingDerivativeDeployment(selfMintingDerivatives[j]);
      if (hasRole(MAINTAINER_ROLE, msg.sender)) {
        checkSelfMintingDerivativeRegistration(selfMintingDerivative);
      }
      _setDaoFee(address(selfMintingDerivative), daoFees[j]);
    }
  }

  /**
   * @notice Allow to set Dao fee percentages on a list of registered self-minting derivatives
   * @param selfMintingDerivatives Self-minting derivatives
   * @param daoFeePercentages Dao fee percentages for self-minting derivatives
   */
  function setDaoFeePercentage(
    address[] calldata selfMintingDerivatives,
    uint256[] calldata daoFeePercentages
  ) external override onlyMaintainer {
    uint256 selfMintingDerCount = selfMintingDerivatives.length;
    require(selfMintingDerCount > 0, 'No self-minting derivatives passed');
    require(
      selfMintingDerCount == daoFeePercentages.length,
      'Number of derivatives and dao fee percentages must be the same'
    );
    for (uint256 j; j < selfMintingDerCount; j++) {
      ISelfMintingDerivativeDeployment selfMintingDerivative =
        ISelfMintingDerivativeDeployment(selfMintingDerivatives[j]);
      checkSelfMintingDerivativeRegistration(selfMintingDerivative);
      _setDaoFeePercentage(
        address(selfMintingDerivative),
        daoFeePercentages[j]
      );
    }
  }

  /**
   * @notice Allow to set Dao fee recipients on a list of registered self-minting derivatives
   * @param selfMintingDerivatives Self-minting derivatives
   * @param daoFeeRecipients Dao fee recipients for self-minting derivatives
   */
  function setDaoFeeRecipient(
    address[] calldata selfMintingDerivatives,
    address[] calldata daoFeeRecipients
  ) external override onlyMaintainer {
    uint256 selfMintingDerCount = selfMintingDerivatives.length;
    require(selfMintingDerCount > 0, 'No self-minting derivatives passed');
    require(
      selfMintingDerCount == daoFeeRecipients.length,
      'Number of derivatives and Dao fee recipients must be the same'
    );
    for (uint256 j; j < selfMintingDerCount; j++) {
      ISelfMintingDerivativeDeployment selfMintingDerivative =
        ISelfMintingDerivativeDeployment(selfMintingDerivatives[j]);
      checkSelfMintingDerivativeRegistration(selfMintingDerivative);
      _setDaoFeeRecipient(address(selfMintingDerivative), daoFeeRecipients[j]);
    }
  }

  /**
   * @notice Gets the set CapMintAmount of a self-minting derivative
   * @param selfMintingDerivative Self-minting derivative
   * @return capMintAmount Limit amount for minting
   */
  function getCapMintAmount(address selfMintingDerivative)
    external
    view
    override
    returns (uint256 capMintAmount)
  {
    capMintAmount = capMint[selfMintingDerivative];
  }

  /**
   * @notice Gets the set CapDepositRatio of a self-minting derivative
   * @param selfMintingDerivative Self-minting derivative
   * @return capDepositRatio Limit ratio for a user deposit
   */
  function getCapDepositRatio(address selfMintingDerivative)
    external
    view
    override
    returns (uint256 capDepositRatio)
  {
    capDepositRatio = capDeposit[selfMintingDerivative];
  }

  /**
   * @notice Gets the set DAO fee of a self-minting derivative
   * @param selfMintingDerivative Self-minting derivative
   * @return daoFee Dao fee info (percent + recipient)
   */
  function getDaoFee(address selfMintingDerivative)
    external
    view
    override
    returns (DaoFee memory daoFee)
  {
    daoFee = fee[selfMintingDerivative];
  }

  /**
   * @notice Gets the set DAO fee percentage of a self-minting derivative
   * @param selfMintingDerivative Self-minting derivative
   * @return daoFeePercentage Dao fee percent
   */
  function getDaoFeePercentage(address selfMintingDerivative)
    external
    view
    override
    returns (uint256 daoFeePercentage)
  {
    daoFeePercentage = fee[selfMintingDerivative].feePercentage;
  }

  /**
   * @notice Gets the set DAO fee recipient of a self-minting derivative
   * @param selfMintingDerivative Self-minting derivative
   * @return recipient Dao fee recipient
   */
  function getDaoFeeRecipient(address selfMintingDerivative)
    external
    view
    override
    returns (address recipient)
  {
    recipient = fee[selfMintingDerivative].feeRecipient;
  }

  //----------------------------------------
  // Internal functions
  //----------------------------------------

  /**
   * @notice Check if a self-minting derivative is registered with the SelfMintingRegistry
   * @param selfMintingDerivative Self-minting derivative contract
   */
  function checkSelfMintingDerivativeRegistration(
    ISelfMintingDerivativeDeployment selfMintingDerivative
  ) internal view {
    ISynthereumRegistry selfMintingRegistry =
      ISynthereumRegistry(
        synthereumFinder.getImplementationAddress(
          SynthereumInterfaces.SelfMintingRegistry
        )
      );
    require(
      selfMintingRegistry.isDeployed(
        selfMintingDerivative.syntheticTokenSymbol(),
        selfMintingDerivative.collateralCurrency(),
        selfMintingDerivative.version(),
        address(selfMintingDerivative)
      ),
      'Self-minting derivative not registred'
    );
  }

  /**
   * @notice Internal helper function for setCapMintAmount function
   */
  function _setCapMintAmount(
    address selfMintingDerivative,
    uint256 capMintAmount
  ) internal {
    require(
      capMint[selfMintingDerivative] != capMintAmount,
      'Cap mint amount is the same'
    );
    capMint[selfMintingDerivative] = capMintAmount;
    emit SetCapMintAmount(selfMintingDerivative, capMintAmount);
  }

  /**
   * @notice Internal helper function for setCapDepositRatio function
   */
  function _setCapDepositRatio(
    address selfMintingDerivative,
    uint256 capDepositRatio
  ) internal {
    require(
      capDeposit[selfMintingDerivative] != capDepositRatio,
      'Cap deposit ratio is the same'
    );
    capDeposit[selfMintingDerivative] = capDepositRatio;
    emit SetCapDepositRatio(selfMintingDerivative, capDepositRatio);
  }

  /**
   * @notice Internal helper function for setDaoFee function
   */
  function _setDaoFee(address selfMintingDerivative, DaoFee calldata daoFee)
    internal
  {
    require(
      fee[selfMintingDerivative].feePercentage != daoFee.feePercentage ||
        fee[selfMintingDerivative].feeRecipient != daoFee.feeRecipient,
      'Dao fee is the same'
    );
    fee[selfMintingDerivative] = DaoFee(
      daoFee.feePercentage,
      daoFee.feeRecipient
    );
    emit SetDaoFee(selfMintingDerivative, daoFee);
  }

  /**
   * @notice Internal helper function for setDaoFeePercentage function
   */
  function _setDaoFeePercentage(
    address selfMintingDerivative,
    uint256 daoFeePercentage
  ) internal {
    require(
      fee[selfMintingDerivative].feePercentage != daoFeePercentage,
      'Dao fee percentage is the same'
    );
    fee[selfMintingDerivative].feePercentage = daoFeePercentage;
    emit SetDaoFeePercentage(selfMintingDerivative, daoFeePercentage);
  }

  /**
   * @notice Internal helper function for setDaoFeeRecipient function
   */
  function _setDaoFeeRecipient(
    address selfMintingDerivative,
    address daoFeeRecipient
  ) internal {
    require(
      fee[selfMintingDerivative].feeRecipient != daoFeeRecipient,
      'Dao fee recipient is the same'
    );
    fee[selfMintingDerivative].feeRecipient = daoFeeRecipient;
    emit SetDaoFeeRecipient(selfMintingDerivative, daoFeeRecipient);
  }
}
