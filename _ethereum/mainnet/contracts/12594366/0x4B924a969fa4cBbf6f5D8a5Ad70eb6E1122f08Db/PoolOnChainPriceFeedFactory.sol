// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity ^0.6.12;
pragma experimental ABIEncoderV2;
import "./IDerivative.sol";
import "./IFinder.sol";
import "./IPoolOnChainPriceFeed.sol";
import "./PoolOnChainPriceFeed.sol";
import "./Constants.sol";
import "./IDeploymentSignature.sol";
import "./PoolOnChainPriceFeedCreator.sol";

contract SynthereumPoolOnChainPriceFeedFactory is
  SynthereumPoolOnChainPriceFeedCreator,
  IDeploymentSignature
{
  //----------------------------------------
  // Storage
  //----------------------------------------

  address public synthereumFinder;

  bytes4 public override deploymentSignature;

  //----------------------------------------
  // Constructor
  //----------------------------------------
  /**
   * @notice Set synthereum finder
   * @param _synthereumFinder Synthereum finder contract
   */
  constructor(address _synthereumFinder) public {
    synthereumFinder = _synthereumFinder;
    deploymentSignature = this.createPool.selector;
  }

  //----------------------------------------
  // Public functions
  //----------------------------------------

  /**
   * @notice The derivative's collateral currency must be an ERC20
   * @notice The validator will generally be an address owned by the LP
   * @notice `startingCollateralization should be greater than the expected asset price multiplied
   *      by the collateral requirement. The degree to which it is greater should be based on
   *      the expected asset volatility.
   * @notice Only Synthereum deployer can deploy a pool
   * @param derivative The perpetual derivative
   * @param finder The Synthereum finder
   * @param version Synthereum version
   * @param roles The addresses of admin, maintainer, liquidity provider
   * @param startingCollateralization Collateralization ratio to use before a global one is set
   * @param fee The fee structure
   * @return poolDeployed Pool contract deployed
   */
  function createPool(
    IDerivative derivative,
    ISynthereumFinder finder,
    uint8 version,
    ISynthereumPoolOnChainPriceFeed.Roles memory roles,
    uint256 startingCollateralization,
    ISynthereumPoolOnChainPriceFeed.Fee memory fee
  ) public override returns (SynthereumPoolOnChainPriceFeed poolDeployed) {
    address deployer =
      ISynthereumFinder(synthereumFinder).getImplementationAddress(
        SynthereumInterfaces.Deployer
      );
    require(msg.sender == deployer, 'Sender must be Synthereum deployer');
    poolDeployed = super.createPool(
      derivative,
      finder,
      version,
      roles,
      startingCollateralization,
      fee
    );
  }
}
