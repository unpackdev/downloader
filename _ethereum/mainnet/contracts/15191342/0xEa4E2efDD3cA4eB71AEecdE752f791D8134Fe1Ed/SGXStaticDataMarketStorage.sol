pragma solidity >=0.4.21 <0.6.0;
import "./ProgramProxyInterface.sol";
import "./KeyVerifierInterface.sol";
import "./Ownable.sol";
import "./SignatureVerifier.sol";
import "./GasRewardTool.sol";
import "./PaymentConfirmTool.sol";
import "./TrustListTools.sol";
import "./SGXStaticData.sol";
import "./OwnerProxyInterface.sol";

contract SGXStaticDataMarketStorage is Ownable, GasRewardTool, PaymentConfirmTool, TrustListTools{
  mapping(bytes32=>SGXStaticData.Data) public all_data;

  bool public paused;

  ProgramProxyInterface public program_proxy;
  OwnerProxyInterface public owner_proxy;
  address public payment_token;
  uint256 public request_revoke_block_num;

  address payable public fee_pool;
  uint256 public ratio_base;
  uint256 public fee_ratio;
}
