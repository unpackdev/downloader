// SPDX-License-Identifier: AGPL-3.0
pragma solidity 0.7.5;
pragma abicoder v2;

import "./IERC20.sol";
import "./ILendingPoolAddressesProvider.sol";
import "./ILendingPoolConfigurator.sol";
import "./IAaveIncentivesController.sol";
import "./IAaveEcosystemReserveController.sol";
import "./ISimpleExecutor.sol";
import "./DistributionTypes.sol";
import "./DataTypes.sol";
import "./ILendingPoolData.sol";
import "./IATokenDetailed.sol";
import "./PercentageMath.sol";
import "./SafeMath.sol";

contract SimpleProposalIncentivesExecutor is ISimpleExecutor {
  using SafeMath for uint256;
  using PercentageMath for uint256;

  address constant AAVE_TOKEN = 0x7Fc66500c84A76Ad7e9c93437bFc5Ac33E2DDaE9;
  address constant LENDING_POOL = 0x7d2768dE32b0b80b7a3454c06BdAc94A69DDc7A9;
  address constant ECO_RESERVE_ADDRESS = 0x1E506cbb6721B83B1549fa1558332381Ffa61A93;
  address constant INCENTIVES_CONTROLLER_PROXY_ADDRESS = 0xd784927Ff2f95ba542BfC824c8a8a98F3495f6b5;

  uint256 constant DISTRIBUTION_DURATION = 7776000; // 90 days
  uint256 constant DISTRIBUTION_AMOUNT = 2000e18 * 90; //2000 AAVE daily for 90 days (total 180,000 AAVE)

  function execute() external override {
    uint256 tokensCounter;

    address[] memory assets = new address[](32);

    address payable[16] memory reserves =
      [
        0x6B175474E89094C44Da98b954EedeAC495271d0F, // DAI
        0x056Fd409E1d7A124BD7017459dFEa2F387b6d5Cd, // GUSD
        0xA0b86991c6218b36c1d19D4a2e9Eb0cE3606eB48, // USDC
        0xdAC17F958D2ee523a2206206994597C13D831ec7, // USDT
        0x2260FAC5E5542a773Aa44fBCfeDf7C193bc2C599, // WBTC
        0xC02aaA39b223FE8D0A0e5C4F27eAD9083C756Cc2, // WETH
        0x57Ab1ec28D129707052df4dF418D58a2D46d5f51, // sUSD --NEW--
        0x0000000000085d4780B73119b644AE5ecd22b376, // TUSD --NEW--
        0x8E870D67F660D95d5be530380D0eC0bd388289E1, // PAX --NEW--
        0x03ab458634910AaD20eF5f1C8ee96F1D6ac54919, // RAI --NEW--
        0xba100000625a3754423978a60c9317c58a424e3D, // BAL --NEW--
        0x0bc529c00C6401aEF6D220BE8C6Ea1667F6Ad93e, // YFI --NEW--
        0x8798249c2E607446EfB7Ad49eC89dD1865Ff4272, // xSUSHI --NEW--
        0x514910771AF9Ca656af840dff83E8264EcF986CA, // LINK --NEW--
        0x1f9840a85d5aF5bf1D1762F925BDADdC4201F984, // UNI --NEW--
        0x9f8F72aA9304c8B593d555F12eF6589cC3A579A2 // MKR --NEW--
      ];

    uint256[] memory emissions = new uint256[](32);

    emissions[0] = _convertEmissionDayToSecond(200e18); //aDAI
    emissions[1] = _convertEmissionDayToSecond(200e18); //vDebtDAI
    emissions[2] = _convertEmissionDayToSecond(2.5e18); //aGUSD
    emissions[3] = _convertEmissionDayToSecond(2.5e18); //vDebtGUSD
    emissions[4] = _convertEmissionDayToSecond(400e18); //aUSDC
    emissions[5] = _convertEmissionDayToSecond(400e18); //vDebtUSDC
    emissions[6] = _convertEmissionDayToSecond(162.5e18); //aUSDT
    emissions[7] = _convertEmissionDayToSecond(162.5e18); //vDebtUSDT
    emissions[8] = _convertEmissionDayToSecond(142.5e18); //aWBTC
    emissions[9] = _convertEmissionDayToSecond(7.5e18); //vDebtWBTC
    emissions[10] = _convertEmissionDayToSecond(171e18); //aWETH
    emissions[11] = _convertEmissionDayToSecond(9e18); //vDebtWETH
    emissions[12] = _convertEmissionDayToSecond(10e18); // asUSD
    emissions[13] = _convertEmissionDayToSecond(10e18); // vDebtsUSD
    emissions[14] = _convertEmissionDayToSecond(5e18); // aTUSD
    emissions[15] = _convertEmissionDayToSecond(5e18); // vDebtTUSD
    emissions[16] = _convertEmissionDayToSecond(2.5e18); // aPAX
    emissions[17] = _convertEmissionDayToSecond(2.5e18); // vDebtPAX
    emissions[18] = _convertEmissionDayToSecond(5e18); // aRAI
    emissions[19] = _convertEmissionDayToSecond(5e18); // vDebtRAI
    emissions[20] = _convertEmissionDayToSecond(10e18); // aBAL
    emissions[21] = 0; // vDebtBAL
    emissions[22] = _convertEmissionDayToSecond(15e18); // aYFI
    emissions[23] = 0; // vDebtYFI
    emissions[24] = _convertEmissionDayToSecond(15e18); // axSUSHI
    emissions[25] = 0; // vDebtxSUSHI
    emissions[26] = _convertEmissionDayToSecond(25e18); // aLINK
    emissions[27] = 0; // vDebtLINK
    emissions[28] = _convertEmissionDayToSecond(15e18); // aUNI
    emissions[29] = 0; // vDebtUNI
    emissions[30] = _convertEmissionDayToSecond(15e18); // aMKR
    emissions[31] = 0; // vDebtMKR

    IAaveIncentivesController incentivesController =
      IAaveIncentivesController(INCENTIVES_CONTROLLER_PROXY_ADDRESS);
    IAaveEcosystemReserveController ecosystemReserveController =
      IAaveEcosystemReserveController(ECO_RESERVE_ADDRESS);

    // Prepare the asset array for the incentives
    for (uint256 x = 0; x < reserves.length; x++) {
      DataTypes.ReserveData memory reserveData =
        ILendingPoolData(LENDING_POOL).getReserveData(reserves[x]);

      assets[tokensCounter++] = reserveData.aTokenAddress;

      // Configure variable debt token at incentives controller
      assets[tokensCounter++] = reserveData.variableDebtTokenAddress;
    }
    // Transfer AAVE funds to the Incentives Controller
    ecosystemReserveController.transfer(
      AAVE_TOKEN,
      INCENTIVES_CONTROLLER_PROXY_ADDRESS,
      DISTRIBUTION_AMOUNT
    );

    // Enable incentives in aTokens and Variable Debt tokens
    incentivesController.configureAssets(assets, emissions);

    // Sets the end date for the distribution
    incentivesController.setDistributionEnd(block.timestamp + DISTRIBUTION_DURATION);
  }

  function _convertEmissionDayToSecond(uint256 emission) internal pure returns (uint256) {
    return emission / 86400;
  }
}
