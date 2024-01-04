// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity ^0.6.12;
pragma experimental ABIEncoderV2;
import "./IDeploymentSignature.sol";
import "./IFinder.sol";
import "./Constants.sol";
import "./PerpetutalPoolPartyCreator.sol";

contract SynthereumDerivativeFactory is
  PerpetualPoolPartyCreator,
  IDeploymentSignature
{
  address public synthereumFinder;

  bytes4 public override deploymentSignature;

  constructor(
    address _synthereumFinder,
    address _umaFinder,
    address _tokenFactoryAddress,
    address _timerAddress
  )
    public
    PerpetualPoolPartyCreator(_umaFinder, _tokenFactoryAddress, _timerAddress)
  {
    synthereumFinder = _synthereumFinder;
    deploymentSignature = this.createPerpetual.selector;
  }

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
