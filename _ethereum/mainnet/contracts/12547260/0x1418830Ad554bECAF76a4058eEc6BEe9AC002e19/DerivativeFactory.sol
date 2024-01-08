// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity ^0.6.12;
pragma experimental ABIEncoderV2;
import "./IDeploymentSignature.sol";
import "./IFinder.sol";
import "./Constants.sol";
import "./PerpetutalPoolPartyCreator.sol";

/** @title Contract factory of derivatives
 */
contract SynthereumDerivativeFactory is
  PerpetualPoolPartyCreator,
  IDeploymentSignature
{
  //----------------------------------------
  // Storage
  //----------------------------------------

  bytes4 public override deploymentSignature;

  //----------------------------------------
  // Constructor
  //----------------------------------------

  /**
   * @notice Constructs the SynthereumDerivativeFactory contract
   * @param _umaFinder UMA protocol Finder used to discover other protocol contracts.
   * @param _synthereumFinder Synthereum Finder address used to discover other contracts
   * @param _timerAddress Contract that stores the current time in a testing environment.
   */
  constructor(
    address _umaFinder,
    address _synthereumFinder,
    address _timerAddress
  )
    public
    PerpetualPoolPartyCreator(_umaFinder, _synthereumFinder, _timerAddress)
  {
    deploymentSignature = this.createPerpetual.selector;
  }

  /**
   * @notice Check if the sender is the deployer and deploy a perpetual derivative
   * @param params input parameters of perpetual derivative
   * @return derivative address of the derivative created
   */
  function createPerpetual(Params memory params)
    public
    override
    returns (address derivative)
  {
    address deployer =
      ISynthereumFinder(synthereumFinder).getImplementationAddress(
        SynthereumInterfaces.Deployer
      );
    require(msg.sender == deployer, 'Sender must be Synthereum deployer');
    derivative = super.createPerpetual(params);
  }
}
