// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity ^0.6.0;
pragma experimental ABIEncoderV2;

import "./MintableBurnableIERC20.sol";
import "./IFinder.sol";
import "./ISelfMintingController.sol";
import "./Constants.sol";
import "./FinderInterface.sol";
import "./IdentifierWhitelistInterface.sol";
import "./Constants.sol";
import "./FixedPoint.sol";
import "./SelfMintingPerpetualMultiPartyLib.sol";
import "./SelfMintingPerpetualMultiParty.sol";
import "./ContractCreator.sol";
import "./Testable.sol";
import "./Lockable.sol";

/**
 * @title Self-Minting Perpetual Contract creator.
 * @notice Factory contract to create and register new instances of self-minting perpetual contracts.
 * Responsible for constraining the parameters used to construct a new self-minting perpetual. This creator contains a number of constraints
 * that are applied to newly created  contracts. These constraints can evolve over time and are
 * initially constrained to conservative values in this first iteration. Technically there is nothing in the
 * Perpetual contract requiring these constraints. However, because `createPerpetual()` is intended
 * to be the only way to create valid financial contracts that are registered with the DVM (via _registerContract),
  we can enforce deployment configurations here.
 */
contract SelfMintingPerpetutalMultiPartyCreator is
  ContractCreator,
  Testable,
  Lockable
{
  using FixedPoint for FixedPoint.Unsigned;

  struct Params {
    address collateralAddress;
    bytes32 priceFeedIdentifier;
    string syntheticName;
    string syntheticSymbol;
    address syntheticToken;
    FixedPoint.Unsigned collateralRequirement;
    FixedPoint.Unsigned disputeBondPct;
    FixedPoint.Unsigned sponsorDisputeRewardPct;
    FixedPoint.Unsigned disputerDisputeRewardPct;
    FixedPoint.Unsigned minSponsorTokens;
    uint256 withdrawalLiveness;
    uint256 liquidationLiveness;
    address excessTokenBeneficiary;
    uint8 version;
    ISelfMintingController.DaoFee daoFee;
    uint256 capMintAmount;
    uint256 capDepositRatio;
  }

  // Address of Synthereum Finder
  ISynthereumFinder public synthereumFinder;

  //----------------------------------------
  // Events
  //----------------------------------------
  event CreatedPerpetual(
    address indexed perpetualAddress,
    address indexed deployerAddress
  );

  //----------------------------------------
  // Constructor
  //----------------------------------------

  /**
   * @notice Constructs the Perpetual contract.
   * @param _umaFinderAddress UMA protocol Finder used to discover other protocol contracts.
   * @param _synthereumFinder Synthereum Finder address used to discover other contracts
   * @param _timerAddress Contract that stores the current time in a testing environment.
   */
  constructor(
    address _umaFinderAddress,
    address _synthereumFinder,
    address _timerAddress
  )
    public
    ContractCreator(_umaFinderAddress)
    Testable(_timerAddress)
    nonReentrant()
  {
    synthereumFinder = ISynthereumFinder(_synthereumFinder);
  }

  //----------------------------------------
  // External functions
  //----------------------------------------

  /**
   * @notice Creates an instance of perpetual and registers it within the registry.
   * @param params is a `ConstructorParams` object from Perpetual.
   * @return address of the deployed contract.
   */
  function createPerpetual(Params calldata params)
    public
    virtual
    nonReentrant()
    returns (address)
  {
    // Create a new synthetic token using the params.
    require(bytes(params.syntheticName).length != 0, 'Missing synthetic name');
    require(
      bytes(params.syntheticSymbol).length != 0,
      'Missing synthetic symbol'
    );
    require(
      params.syntheticToken != address(0),
      'Synthetic token address cannot be 0x00'
    );
    address derivative;
    // If the collateral token does not have a `decimals()` method,
    // then a default precision of 18 will be applied to the newly created synthetic token.
    MintableBurnableIERC20 tokenCurrency =
      MintableBurnableIERC20(params.syntheticToken);
    require(
      keccak256(abi.encodePacked(tokenCurrency.name())) ==
        keccak256(abi.encodePacked(params.syntheticName)),
      'Wrong synthetic token name'
    );
    require(
      keccak256(abi.encodePacked(tokenCurrency.symbol())) ==
        keccak256(abi.encodePacked(params.syntheticSymbol)),
      'Wrong synthetic token symbol'
    );
    require(
      tokenCurrency.decimals() == uint8(18),
      'Decimals of synthetic token must be 18'
    );
    derivative = SelfMintingPerpetualMultiPartyLib.deploy(
      _convertParams(params)
    );

    _setControllerValues(
      derivative,
      params.daoFee,
      params.capMintAmount,
      params.capDepositRatio
    );

    _registerContract(new address[](0), address(derivative));

    emit CreatedPerpetual(address(derivative), msg.sender);

    return address(derivative);
  }

  //----------------------------------------
  // Internal functions
  //----------------------------------------

  // Converts createPerpetual params to Perpetual constructor params.
  function _convertParams(Params calldata params)
    internal
    view
    returns (
      SelfMintingPerpetualMultiParty.ConstructorParams memory constructorParams
    )
  {
    // Known from creator deployment.

    constructorParams.positionManagerParams.finderAddress = finderAddress;
    constructorParams.positionManagerParams.synthereumFinder = synthereumFinder;
    constructorParams.positionManagerParams.timerAddress = timerAddress;

    // Enforce configuration constraints.
    require(params.withdrawalLiveness != 0, 'Withdrawal liveness cannot be 0');
    require(
      params.liquidationLiveness != 0,
      'Liquidation liveness cannot be 0'
    );
    require(
      params.excessTokenBeneficiary != address(0),
      'Token Beneficiary cannot be 0x00'
    );
    require(
      params.daoFee.feeRecipient != address(0),
      'Fee recipient cannot be 0x00'
    );
    // We don't want perpetual deployers to be able to intentionally or unintentionally set
    // liveness periods that could induce arithmetic overflow, but we also don't want
    // to be opinionated about what livenesses are "correct", so we will somewhat
    // arbitrarily set the liveness upper bound to 100 years (5200 weeks). In practice, liveness
    // periods even greater than a few days would make the perpetual unusable for most users.
    require(
      params.withdrawalLiveness < 5200 weeks,
      'Withdrawal liveness too large'
    );
    require(
      params.liquidationLiveness < 5200 weeks,
      'Liquidation liveness too large'
    );

    // Input from function call.
    constructorParams.positionManagerParams.tokenAddress = params
      .syntheticToken;
    constructorParams.positionManagerParams.collateralAddress = params
      .collateralAddress;
    constructorParams.positionManagerParams.priceFeedIdentifier = params
      .priceFeedIdentifier;
    constructorParams.liquidatableParams.collateralRequirement = params
      .collateralRequirement;
    constructorParams.liquidatableParams.disputeBondPct = params.disputeBondPct;
    constructorParams.liquidatableParams.sponsorDisputeRewardPct = params
      .sponsorDisputeRewardPct;
    constructorParams.liquidatableParams.disputerDisputeRewardPct = params
      .disputerDisputeRewardPct;
    constructorParams.positionManagerParams.minSponsorTokens = params
      .minSponsorTokens;
    constructorParams.positionManagerParams.withdrawalLiveness = params
      .withdrawalLiveness;
    constructorParams.liquidatableParams.liquidationLiveness = params
      .liquidationLiveness;
    constructorParams.positionManagerParams.excessTokenBeneficiary = params
      .excessTokenBeneficiary;
    constructorParams.positionManagerParams.version = params.version;
  }

  /** @notice Sets the controller values for a self-minting derivative
   * @param derivative Address of the derivative to set controller values
   * @param daoFee The DAO fee that will be paid when interacting with the self-minting derivative
   * @param capMintAmount Cap on mint amount. How much synthetic tokens can be minted through a self-minting derivative.
   * This value is updatable
   * @param capDepositRatio The cap set on the deposit ratio for a self-minting derivative. This value is updatable.
   */
  function _setControllerValues(
    address derivative,
    ISelfMintingController.DaoFee calldata daoFee,
    uint256 capMintAmount,
    uint256 capDepositRatio
  ) internal {
    ISelfMintingController selfMintingController =
      ISelfMintingController(
        synthereumFinder.getImplementationAddress(
          SynthereumInterfaces.SelfMintingController
        )
      );
    address[] memory inputAddress = new address[](1);
    inputAddress[0] = derivative;
    ISelfMintingController.DaoFee[] memory inuptFee =
      new ISelfMintingController.DaoFee[](1);
    inuptFee[0] = daoFee;
    uint256[] memory inputCapMint = new uint256[](1);
    inputCapMint[0] = capMintAmount;
    uint256[] memory inputCapRatio = new uint256[](1);
    inputCapRatio[0] = capDepositRatio;
    selfMintingController.setDaoFee(inputAddress, inuptFee);
    selfMintingController.setCapMintAmount(inputAddress, inputCapMint);
    selfMintingController.setCapDepositRatio(inputAddress, inputCapRatio);
  }
}
