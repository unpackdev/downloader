// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity ^0.6.0;
pragma experimental ABIEncoderV2;

import "./MintableBurnableIERC20.sol";
import "./ContractCreator.sol";
import "./Testable.sol";
import "./AddressWhitelist.sol";
import "./Lockable.sol";
import "./MintableBurnableTokenFactory.sol";
import "./PerpetualPoolPartyLib.sol";

contract PerpetualPoolPartyCreator is ContractCreator, Testable, Lockable {
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
    address[] admins;
    address[] pools;
  }

  address public tokenFactoryAddress;

  event CreatedPerpetual(
    address indexed perpetualAddress,
    address indexed deployerAddress
  );

  constructor(
    address _finderAddress,
    address _tokenFactoryAddress,
    address _timerAddress
  )
    public
    ContractCreator(_finderAddress)
    Testable(_timerAddress)
    nonReentrant()
  {
    tokenFactoryAddress = _tokenFactoryAddress;
  }

  function createPerpetual(Params memory params)
    public
    virtual
    nonReentrant()
    returns (address)
  {
    require(bytes(params.syntheticName).length != 0, 'Missing synthetic name');
    require(
      bytes(params.syntheticSymbol).length != 0,
      'Missing synthetic symbol'
    );
    MintableBurnableTokenFactory tf =
      MintableBurnableTokenFactory(tokenFactoryAddress);
    address derivative;
    if (params.syntheticToken == address(0)) {
      MintableBurnableIERC20 tokenCurrency =
        tf.createToken(params.syntheticName, params.syntheticSymbol, 18);
      derivative = PerpetualPoolPartyLib.deploy(
        _convertParams(params, tokenCurrency)
      );

      tokenCurrency.addAdminAndMinterAndBurner(derivative);
      tokenCurrency.renounceAdmin();
    } else {
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
      derivative = PerpetualPoolPartyLib.deploy(
        _convertParams(params, tokenCurrency)
      );
    }

    _registerContract(new address[](0), address(derivative));

    emit CreatedPerpetual(address(derivative), msg.sender);

    return address(derivative);
  }

  function _convertParams(
    Params memory params,
    MintableBurnableIERC20 newTokenCurrency
  )
    private
    view
    returns (PerpetualPoolParty.ConstructorParams memory constructorParams)
  {
    constructorParams.positionManagerParams.finderAddress = finderAddress;
    constructorParams.positionManagerParams.timerAddress = timerAddress;

    require(params.withdrawalLiveness != 0, 'Withdrawal liveness cannot be 0');
    require(
      params.liquidationLiveness != 0,
      'Liquidation liveness cannot be 0'
    );
    require(
      params.excessTokenBeneficiary != address(0),
      'Token Beneficiary cannot be 0x0'
    );
    require(params.admins.length > 0, 'No admin addresses set');
    _requireWhitelistedCollateral(params.collateralAddress);

    require(
      params.withdrawalLiveness < 5200 weeks,
      'Withdrawal liveness too large'
    );
    require(
      params.liquidationLiveness < 5200 weeks,
      'Liquidation liveness too large'
    );

    constructorParams.positionManagerParams.tokenAddress = address(
      newTokenCurrency
    );
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
    constructorParams.roles.admins = params.admins;
    constructorParams.roles.pools = params.pools;
  }
}
