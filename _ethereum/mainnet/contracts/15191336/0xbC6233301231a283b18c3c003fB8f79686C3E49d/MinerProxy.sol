pragma solidity >=0.4.21 <0.6.0;
import "./THMinerInterface.sol";
import "./Ownable.sol";

contract MinerProxy is Ownable{
  address public miner;
  event ChangeMiner(address old_miner, address new_miner);
  function changeMiner(address _miner) public onlyOwner{
    emit ChangeMiner(miner, _miner);
    miner = _miner;
  }

  function mine_submit_result(bytes32 _vhash, bytes32 request_hash) internal{
    if(miner == address(0x0)){
      return ;
    }
    THMinerInterface(miner).mine_submit_result(_vhash, request_hash);
  }
}
