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
contract AIP35AMPL {
  event ProposalExecuted();
  // Mainnet
  ILendingPoolAddressesProvider public constant LENDING_POOL_ADDRESSES_PROVIDER =
    ILendingPoolAddressesProvider(0xB53C1a33016B2DC2fF3653530bfF1848a515c8c5);

  address public constant token = 0xD46bA6D942050d489DBd938a2C909A5d5039A161;
  address public constant interestStrategy = 0x84d1FaD9559b8AC1Fda17d073B8542c8Fb6986dd;

  /**
   * @dev Payload execution function, called once a proposal passed in the Aave governance
   */
  function execute() external {
    ILendingPoolConfiguratorV2 LENDING_POOL_CONFIGURATOR_V2 =
      ILendingPoolConfiguratorV2(LENDING_POOL_ADDRESSES_PROVIDER.getLendingPoolConfigurator());
    LENDING_POOL_CONFIGURATOR_V2.setReserveInterestRateStrategyAddress(token, interestStrategy);
    emit ProposalExecuted();
  }
}
