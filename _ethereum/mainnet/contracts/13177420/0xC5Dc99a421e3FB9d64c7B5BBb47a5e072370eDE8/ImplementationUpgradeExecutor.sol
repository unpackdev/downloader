// SPDX-License-Identifier: AGPL-3.0
pragma solidity 0.7.5;
pragma abicoder v2;

import "./ILendingPoolConfigurator.sol";
import "./IImplementationUpgradeExecutor.sol";
import "./IAaveIncentivesController.sol";
import "./ILendingPoolData.sol";
import "./IATokenDetailed.sol";
import "./DataTypes.sol";

contract ImplementationUpgradeExecutor is IImplementationUpgradeExecutor {
  address constant POOL_CONFIGURATOR = 0x311Bb771e4F8952E6Da169b425E7e92d6Ac45756;
  address constant INCENTIVES_CONTROLLER_PROXY_ADDRESS = 0xd784927Ff2f95ba542BfC824c8a8a98F3495f6b5;
  address constant LENDING_POOL = 0x7d2768dE32b0b80b7a3454c06BdAc94A69DDc7A9;

  uint256 constant DISTRIBUTION_DURATION = 7776000; // 90 days
  uint256 constant INITIAL_DISTRIBUTION_TIMESTAMP = 1629797400; // 24/08/2021

  function execute() external override {
    address payable[10] memory reserves = [
      0xba100000625a3754423978a60c9317c58a424e3D, // BAL
      0x514910771AF9Ca656af840dff83E8264EcF986CA, // LINK
      0x9f8F72aA9304c8B593d555F12eF6589cC3A579A2, // MKR
      0x03ab458634910AaD20eF5f1C8ee96F1D6ac54919, // RAI
      0x57Ab1ec28D129707052df4dF418D58a2D46d5f51, // sUSD
      0x0000000000085d4780B73119b644AE5ecd22b376, // TUSD
      0x1f9840a85d5aF5bf1D1762F925BDADdC4201F984, // UNI
      0x8E870D67F660D95d5be530380D0eC0bd388289E1, // USDP
      0x8798249c2E607446EfB7Ad49eC89dD1865Ff4272, // xSUSHI
      0x0bc529c00C6401aEF6D220BE8C6Ea1667F6Ad93e // YFI
    ];

    address payable[10] memory aTokenImplementations = [
      0x3FC5bBafE3285257CCe2Ede6736F153F78274e67, // aBAL
      0x491bEF802bFD56Ddee8410F6190025f802a75ef2, // aLINK
      0x6BF3D969B9Cdf277d17f9B7787B1223Ab07b47d6, // aMKR
      0xB97Fa7A950B19C8Fe7d9bcD06909D3e67F20f16a, // aRAI
      0x7590dCc7AE7Ce770C1243808ddf5677cBd913257, // sUSD
      0xeDa678212EB1E9694fC1455b2426c7aF30f69Bd5, // aTUSD
      0x66706cEfeBd6268D853bA5112a3E9e99eF476d08, // aUNI
      0x333660C060F56Fcb5DE92dfEB3EbaF3F1834b04f, // aUSDP
      0xEa90db312783e45B98502f55a62a81a924F8D492, // axSUSHI
      0x1cC1cF0AfE797b96bd66a194F0Bf2f37040Bf326 // aYFI
    ];
    address payable[10] memory variableDebtImplementations = [
      0x6C179Cc11aEe78e87c63d1c61B8602FaD6a1655d, // variable BAL
      0x8e12Af1ef540D740C5822799776a2Fd2730F8d06, // variable LINK
      0x5a11383F867137781C205Fe334B148E697e18637, // variable MKR
      0x36166a0B13759632365d28dfe69f3f4e5974BAfB, // variable RAI
      0xB421eBfd0854705696B0bD1cc3BB53891eC4416B, // variable sUSD
      0xD0fe84864a9d599AEd7D77f16D9ac196E57eCE79, // variable TUSD
      0x7681A51C93465f8e4f7B15bBE74C5F621B2d8396, // variable UNI
      0x42F7895b2CA1F9870574958cF2BF6879d445F1a3, // variable USDP
      0x8133267827F41902d32F6f9d8D6aAAF080f2aF8F, // variable xSUSHI
      0x8FEBfb5EaF456C1A420c0522DbC6ddbfb105e131 // variable YFI
    ];

    require(
      aTokenImplementations.length == variableDebtImplementations.length &&
        aTokenImplementations.length == reserves.length,
      'ARRAY_LENGTH_MISMATCH'
    );

    address[] memory assets = new address[](20);

    uint256[] memory emissions = new uint256[](20);

    emissions[0] = _recalculateEmission(10e18); // aBAL
    emissions[1] = 0; // vDebtBAL
    emissions[2] = _recalculateEmission(25e18); // aLINK
    emissions[3] = 0; // vDebtLINK
    emissions[4] = _recalculateEmission(15e18); // aMKR
    emissions[5] = 0; // vDebtMKR
    emissions[6] = _recalculateEmission(5e18); // aRAI
    emissions[7] = _recalculateEmission(5e18); // vDebtRAI
    emissions[8] = _recalculateEmission(10e18); // asUSD
    emissions[9] = _recalculateEmission(10e18); // vDebtsUSD
    emissions[10] = _recalculateEmission(5e18); // aTUSD
    emissions[11] = _recalculateEmission(5e18); // vDebtTUSD
    emissions[12] = _recalculateEmission(15e18); // aUNI
    emissions[13] = 0; // vDebtUNI
    emissions[14] = _recalculateEmission(2.5e18); // aUSDP
    emissions[15] = _recalculateEmission(2.5e18); // vDebtUSDP
    emissions[16] = _recalculateEmission(15e18); // axSUSHI
    emissions[17] = 0; // vDebtxSUSHI
    emissions[18] = _recalculateEmission(15e18); // aYFI
    emissions[19] = 0; // vDebtYFI

    ILendingPoolConfigurator poolConfigurator = ILendingPoolConfigurator(POOL_CONFIGURATOR);
    IAaveIncentivesController incentivesController = IAaveIncentivesController(
      INCENTIVES_CONTROLLER_PROXY_ADDRESS
    );

    uint256 tokensCounter;
    // Prepare the asset array for the incentives
    for (uint256 x = 0; x < reserves.length; x++) {
      require(
        IATokenDetailed(aTokenImplementations[x]).UNDERLYING_ASSET_ADDRESS() == reserves[x],
        'AToken underlying does not match'
      );
      require(
        IATokenDetailed(variableDebtImplementations[x]).UNDERLYING_ASSET_ADDRESS() == reserves[x],
        'Debt Token underlying does not match'
      );

      // Update aToken impl
      poolConfigurator.updateAToken(reserves[x], aTokenImplementations[x]);

      // Update variable debt impl
      poolConfigurator.updateVariableDebtToken(reserves[x], variableDebtImplementations[x]);

      DataTypes.ReserveData memory reserveData = ILendingPoolData(LENDING_POOL).getReserveData(
        reserves[x]
      );
      assets[tokensCounter++] = reserveData.aTokenAddress;
      assets[tokensCounter++] = reserveData.variableDebtTokenAddress;
    }
    incentivesController.configureAssets(assets, emissions);
  }

  // Proportianally incresing the rewards considering the time when emissions where
  function _recalculateEmission(uint256 emission) internal view returns (uint256) {
    return
      (emission * 90) /
      (DISTRIBUTION_DURATION - (block.timestamp - INITIAL_DISTRIBUTION_TIMESTAMP));
  }
}
