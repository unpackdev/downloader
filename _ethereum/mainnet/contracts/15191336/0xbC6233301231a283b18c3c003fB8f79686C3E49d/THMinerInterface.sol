pragma solidity >=0.4.21 <0.6.0;

interface THMinerInterface{
  function mine_submit_result(bytes32 _vhash, bytes32 request_hash) external;
}
