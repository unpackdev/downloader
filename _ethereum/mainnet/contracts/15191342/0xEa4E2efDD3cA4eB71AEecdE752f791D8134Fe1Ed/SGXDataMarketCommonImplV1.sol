pragma solidity >=0.4.21 <0.6.0;
import "./DataMarketPlaceInterface.sol";
import "./SGXStaticData.sol";
import "./SGXStaticDataMarketStorage.sol";
import "./SignatureVerifier.sol";
import "./IERC20.sol";
import "./SafeERC20.sol";


contract SGXDataMarketCommonImplV1 is SGXStaticDataMarketStorage{
  using SGXStaticData for mapping(bytes32=>SGXStaticData.Data);
  using SignatureVerifier for bytes32;
  using ECDSA for bytes32;
  using SafeERC20 for IERC20;

  constructor() public{}
  function createStaticData(bytes32 _hash,
                            string memory _data_uri,
                            uint _price,
                            bytes memory _pkey,
                            bytes memory _hash_sig) public returns(bytes32){

    require(!paused, "already paused to use");

    bytes32 vhash = keccak256(abi.encodePacked(_hash));
    {
      bool v = vhash.toEthSignedMessageHash().verify_signature(_hash_sig, _pkey);
      require(v, "invalid hash signature");
    }

    vhash = all_data.init(_hash, _data_uri, _price, request_revoke_block_num, _pkey);
    return vhash;
  }

  function removeStaticData(bytes32 _vhash) public {
    all_data.remove(_vhash);
  }

  function transferRequestOwnership(bytes32 _vhash, bytes32 request_hash, address payable new_owner) public{
    all_data[_vhash].requests[request_hash].from = new_owner;
  }

  function rejectRequest(bytes32 _vhash, bytes32 request_hash) public{
    require(all_data[_vhash].exists, "data not exist");

    require(all_data[_vhash].requests[request_hash].exists, "request not exist");
    SGXRequest.Request storage r = all_data[_vhash].requests[request_hash];
    require(r.status == SGXRequest.RequestStatus.init, "invalid status");

    r.status = SGXRequest.RequestStatus.rejected;
    if(r.target_token != address(0x0)){
      IERC20(r.target_token).safeTransfer(r.from, r.token_amount);
    }
  }

  function changeRequestRevokeBlockNum(bytes32 _vhash, uint256 _new_block_num) public {
    require(all_data[_vhash].exists, "data not exist");
    require(_new_block_num > 0, "invalid new_block_num");
    all_data[_vhash].revoke_timeout_block_num = _new_block_num;
  }

  function getRequestOwner(bytes32 _vhash, bytes32 request_hash) public view returns(address){
    return all_data[_vhash].requests[request_hash].from;
  }
  function changeDataPrice(bytes32 _vhash, uint256 new_price) public returns(uint256){
    require(!paused, "already paused to use");
    require(all_data[_vhash].exists, "data vhash not exist");
    uint256 old_price = all_data[_vhash].price;
    all_data[_vhash].price = new_price;
    return old_price;
  }

}
