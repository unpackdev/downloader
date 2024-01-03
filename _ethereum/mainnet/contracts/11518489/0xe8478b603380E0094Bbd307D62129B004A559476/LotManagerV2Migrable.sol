// SPDX-License-Identifier: MIT

pragma solidity >=0.6.8;

import "./SafeMath.sol";

import "./ILotManagerMetadata.sol";
import "./ILotManagerV2ProtocolParameters.sol";
import "./ILotManagerV2Migrable.sol";

import "./LotManagerV2ProtocolParameters.sol";

abstract
contract LotManagerV2Migrable is 
  LotManagerV2ProtocolParameters, 
  ILotManagerV2Migrable {
  
  function _migrate(address _newLotManager) internal {
    require(_newLotManager != address(0) && ILotManagerMetadata(_newLotManager).isLotManager(), 'LotManagerV2Migrable::_migrate::not-a-lot-manager');
    require(address(ILotManagerV2ProtocolParameters(_newLotManager).pool()) == address(pool), 'LotManagerV2Migrable::_migrate::migrate-pool-discrepancy');
    hegicStakingETH.transfer(_newLotManager, hegicStakingETH.balanceOf(address(this)));
    hegicStakingWBTC.transfer(_newLotManager, hegicStakingWBTC.balanceOf(address(this)));
    token.transfer(address(pool), token.balanceOf(address(this)));
    emit LotManagerMigrated(_newLotManager);
  }
}
