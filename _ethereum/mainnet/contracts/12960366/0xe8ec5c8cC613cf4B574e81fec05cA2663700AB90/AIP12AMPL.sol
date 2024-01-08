// SPDX-License-Identifier: AGPL-3.0
pragma solidity 0.6.12;
pragma experimental ABIEncoderV2;

import "./IERC20.sol";
import "./ILendingPoolConfiguratorV2.sol";
import "./IOverlyingAsset.sol";
import "./ILendingPoolAddressesProvider.sol";
import "./IAAMPL.sol";
import "./ILendingPool.sol";
/**
 * @title AssetListingProposalGenericExecutor
 * @notice Proposal payload to be executed by the Aave Governance contract via DELEGATECALL
 * @author Aave
 **/
contract AIP12AMPL {
  event ProposalExecuted();
  // Mainnet
  ILendingPoolAddressesProvider public constant LENDING_POOL_ADDRESSES_PROVIDER =
    ILendingPoolAddressesProvider(0xB53C1a33016B2DC2fF3653530bfF1848a515c8c5);

  address public constant token = 0xD46bA6D942050d489DBd938a2C909A5d5039A161;
  address public constant aToken = 0x6fBC3BE5ee5273598d1491D41bB45F6d05a7541A;
  address public constant stableDebtToken = 0x0e8f4fc4c261d454b13C74507Bce8C38AA990361;
  address public constant variableDebtToken = 0x3A38bbc6438d2CE2a9e8F116F315a23433755947;
  address public constant interestStrategy = 0x9A8CA7e1d64AFfF2664443B3803f280345F5336B;
  uint256 public constant ltv = 0;
  uint256 public constant liquidationThreshold = 0;
  uint256 public constant liquidationBonus = 0;
  uint256 public constant reserveFactor = 2000;
  uint8 public constant decimals = 9;


  // Kovan


//  ILendingPoolAddressesProvider public constant LENDING_POOL_ADDRESSES_PROVIDER =
//  ILendingPoolAddressesProvider(0x88757f2f99175387aB4C6a4b3067c77A695b0349);
//
//  address public constant token = 0x3E0437898a5667a4769B1Ca5A34aAB1ae7E81377;
//  address public constant aToken = 0x6421504aBFE7B17d0B751fba13FF5F7D1e2Dd3F9;
//  address public constant stableDebtToken = 0x0C6f0690462165c6CB7Ebb0BE54502Df21E6aEAe;
//  address public constant variableDebtToken = 0x66FD8b4a795E99AfCDED8aa81DC68E2019b0863d;
//  address public constant interestStrategy = 0x3aD3116f2426C213d19CA8563bA90cA2a3650238;
//  uint256 public constant ltv = 0;
//  uint256 public constant liquidationThreshold = 0;
//  uint256 public constant liquidationBonus = 0;
//  uint256 public constant reserveFactor = 2000;
//  uint8 public constant decimals = 9;

  /**
   * @dev Payload execution function, called once a proposal passed in the Aave governance
   */
  function execute() external {
    ILendingPoolConfiguratorV2 LENDING_POOL_CONFIGURATOR_V2 =
      ILendingPoolConfiguratorV2(LENDING_POOL_ADDRESSES_PROVIDER.getLendingPoolConfigurator());
    require(
      token == IOverlyingAsset(aToken).UNDERLYING_ASSET_ADDRESS(),
      'ATOKEN: WRONG_UNDERLYING_TOKEN'
    );
    require(
      token == IOverlyingAsset(stableDebtToken).UNDERLYING_ASSET_ADDRESS(),
      'STABLE_DEBT: WRONG_UNDERLYING_TOKEN'
    );
    require(
      token == IOverlyingAsset(variableDebtToken).UNDERLYING_ASSET_ADDRESS(),
      'VARIABLE_DEBT: WRONG_UNDERLYING_TOKEN'
    );
    LENDING_POOL_CONFIGURATOR_V2.initReserve(
      aToken,
      stableDebtToken,
      variableDebtToken,
      decimals,
      interestStrategy
    );
    LENDING_POOL_CONFIGURATOR_V2.enableBorrowingOnReserve(token, false);
    LENDING_POOL_CONFIGURATOR_V2.setReserveFactor(token, reserveFactor);

    ILendingPool pool = ILendingPool(LENDING_POOL_ADDRESSES_PROVIDER.getLendingPool());

    DataTypes.ReserveData memory reserve = pool.getReserveData(token);

    IAAMPL(reserve.aTokenAddress).initializeDebtTokens();

    emit ProposalExecuted();
  }
}
