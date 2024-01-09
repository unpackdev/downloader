// SPDX-License-Identifier: MIT

/*

  Coded for MakerDAO and The Keep3r Network with ♥ by
  ██████╗░███████╗███████╗██╗  ░██╗░░░░░░░██╗░█████╗░███╗░░██╗██████╗░███████╗██████╗░██╗░░░░░░█████╗░███╗░░██╗██████╗░
  ██╔══██╗██╔════╝██╔════╝██║  ░██║░░██╗░░██║██╔══██╗████╗░██║██╔══██╗██╔════╝██╔══██╗██║░░░░░██╔══██╗████╗░██║██╔══██╗
  ██║░░██║█████╗░░█████╗░░██║  ░╚██╗████╗██╔╝██║░░██║██╔██╗██║██║░░██║█████╗░░██████╔╝██║░░░░░███████║██╔██╗██║██║░░██║
  ██║░░██║██╔══╝░░██╔══╝░░██║  ░░████╔═████║░██║░░██║██║╚████║██║░░██║██╔══╝░░██╔══██╗██║░░░░░██╔══██║██║╚████║██║░░██║
  ██████╔╝███████╗██║░░░░░██║  ░░╚██╔╝░╚██╔╝░╚█████╔╝██║░╚███║██████╔╝███████╗██║░░██║███████╗██║░░██║██║░╚███║██████╔╝
  ╚═════╝░╚══════╝╚═╝░░░░░╚═╝  ░░░╚═╝░░░╚═╝░░░╚════╝░╚═╝░░╚══╝╚═════╝░╚══════╝╚═╝░░╚═╝╚══════╝╚═╝░░╚═╝╚═╝░░╚══╝╚═════╝░
  https://defi.sucks

*/

pragma solidity >=0.8.4 <0.9.0;

import "./Governable.sol";
import "./Pausable.sol";
import "./DustCollector.sol";
import "./Keep3rMeteredFallbackJob.sol";
import "./Keep3rBondedJob.sol";
import "./ISequencer.sol";
import "./IJob.sol";
import "./IKeep3rV2.sol";
import "./IMakerDAOUpkeep.sol";

contract MakerDAOUpkeep is IMakerDAOUpkeep, Governable, Keep3rBondedJob, Keep3rMeteredFallbackJob, Pausable, DustCollector {
  address public override sequencer = 0x9566eB72e47E3E20643C0b1dfbEe04Da5c7E4732;
  bytes32 public override network;

  address internal constant DAI = 0x6B175474E89094C44Da98b954EedeAC495271d0F;
  address internal constant DAI_WETH_POOL = 0xC2e9F25Be6257c210d7Adf0D4Cd6E3E881ba25f8;

  constructor(address _governor, bytes32 _network) Governable(_governor) Keep3rMeteredFallbackJob(DAI, DAI_WETH_POOL) {
    network = _network;
  }

  function work(address _job, bytes calldata _data) external override upkeep {
    _work(_job, _data);
  }

  function workMetered(address _job, bytes calldata _data) external override upkeepFallbackMetered {
    _work(_job, _data);
  }

  function setNetwork(bytes32 _network) external override onlyGovernor {
    network = _network;
    emit NetworkSet(network);
  }

  function setSequencerAddress(address _sequencer) external override onlyGovernor {
    sequencer = _sequencer;
    emit SequencerAddressSet(sequencer);
  }

  // Internals

  function _work(address _job, bytes calldata _data) internal {
    if (paused) revert Paused();
    if (!ISequencer(sequencer).hasJob(_job)) revert NotValidJob();
    IJob(_job).work(network, _data);
    emit JobWorked(_job);
  }

  function _isValidKeeper(address _keeper) internal override(Keep3rBondedJob, Keep3rJob) {
    super._isValidKeeper(_keeper);
  }
}
