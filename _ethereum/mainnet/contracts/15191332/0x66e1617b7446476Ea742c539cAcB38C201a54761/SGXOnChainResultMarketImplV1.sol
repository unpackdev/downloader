pragma solidity >=0.4.21 <0.6.0;
import "./ProgramProxyInterface.sol";
import "./KeyVerifierInterface.sol";
import "./SignatureVerifier.sol";
import "./IERC20.sol";
import "./SafeERC20.sol";
import "./Address.sol";
import "./SGXRequest.sol";
import "./SGXStaticData.sol";
import "./SGXOnChainResult.sol";
import "./SGXStaticDataMarketStorage.sol";

contract SGXOnChainResultMarketImplV1 is SGXStaticDataMarketStorage{

  using SGXRequest for mapping(bytes32 => SGXRequest.Request);
  using SGXOnChainResult for mapping(bytes32=>SGXRequest.Request);

  using SignatureVerifier for bytes32;
  using ECDSA for bytes32;
  using SafeERC20 for IERC20;
  using Address for address;

  constructor() public {}

  function remindRequestCost(bytes32 _vhash, bytes32 request_hash, uint64 cost,
                             bytes memory sig) public view returns(uint256 gap){
    require(all_data[_vhash].exists, "not exist");
    SGXStaticData.Data storage d = all_data[_vhash];
    //This is unncessary
    //require(d.owner == msg.sender, "only data owner can remind");
    return d.requests.remind_cost(d.data_hash, d.price, program_proxy, request_hash, cost, sig, ratio_base, fee_ratio);
  }

  function refundRequest(bytes32 _vhash, bytes32 request_hash, uint256 refund_amount) public {
    require(all_data[_vhash].exists, "not exist");
    SGXStaticData.Data storage d = all_data[_vhash];
    d.requests.refund_request(request_hash, refund_amount);
  }

  function revokeRequest(bytes32 _vhash, bytes32 request_hash) public returns(uint256 token_amount){
    require(all_data[_vhash].exists, "not exist");
    SGXStaticData.Data storage d = all_data[_vhash];
    return d.requests.revoke_request(request_hash);
  }


  function requestOnChain(bytes32 _vhash, bytes memory secret,
                          bytes memory input,
                          bytes memory forward_sig,
                          bytes32 program_hash, uint gas_price,
                          bytes memory pkey, uint256 amount) public returns(bytes32 request_hash){

    require(all_data[_vhash].exists, "data vhash not exist");
    require(program_proxy.is_program_hash_available(program_hash), "invalid program");
    request_hash = keccak256(abi.encode(msg.sender, pkey, secret, input, forward_sig, program_hash, gas_price, block.number));
    mapping(bytes32=>SGXRequest.Request) storage request_infos = all_data[_vhash].requests;
    require(request_infos[request_hash].exists == false, "already exist");

    if(amount > 0 && payment_token != address(0x0)){
      IERC20(payment_token).safeTransferFrom(msg.sender, address(this), amount);
    }

    request_infos[request_hash].from = msg.sender;
    request_infos[request_hash].pkey4v = pkey;
    request_infos[request_hash].secret = secret;
    request_infos[request_hash].input = input;
    request_infos[request_hash].data_use_price = all_data[_vhash].price;
    request_infos[request_hash].program_use_price = program_proxy.program_price(program_hash);
    request_infos[request_hash].forward_sig = forward_sig;
    request_infos[request_hash].program_hash = program_hash;
    request_infos[request_hash].token_amount = amount;
    request_infos[request_hash].gas_price = gas_price;
    request_infos[request_hash].block_number = block.number;
    request_infos[request_hash].revoke_block_num = all_data[_vhash].revoke_timeout_block_num;
    request_infos[request_hash].status = SGXRequest.RequestStatus.init;
    request_infos[request_hash].result_type = SGXRequest.ResultType.onchain;
    request_infos[request_hash].exists = true;
    request_infos[request_hash].target_token = payment_token;
  }

  function submitOnChainResult(bytes32 _vhash, bytes32 request_hash, uint64 cost, bytes memory result,
                               bytes memory sig) public returns(bool){
    require(all_data[_vhash].exists, "data vhash not exist");
    SGXStaticData.Data storage d = all_data[_vhash];
    SGXOnChainResult.ResultParam memory p;
    p.data_hash = d.data_hash;
    p.data_recver = owner_proxy.ownerOf(_vhash).toPayable();
    p.program_proxy = program_proxy;
    p.cost = cost;
    p.result = result;
    p.sig = sig;
    p.fee_pool = fee_pool;
    p.fee = fee_ratio;
    p.ratio_base = ratio_base;
    return d.requests.submit_onchain_result(request_hash, p);
  }

  function internalTransferRequestOwnership(bytes32 _vhash, bytes32 request_hash, address payable new_owner) public{
    all_data[_vhash].requests[request_hash].from = new_owner;
  }

}

