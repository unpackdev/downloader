import "./IHypervisor.sol";
import "./IERC20.sol";
import "./SafeERC20.sol";
import "./FullMath.sol";
import "./SafeMath.sol";
import "./SignedSafeMath.sol";

contract DepositProxy {

  using SafeERC20 for IERC20;
  using SafeMath for uint256;
  using SignedSafeMath for int256;

  IHypervisor public pos;
  address public owner;
  bool public retired = false; 
  uint256 public deposit0Max;
  uint256 public deposit1Max;
  mapping(address=>bool) public list;

  uint256 MAX_INT = 2**256 - 1;

  constructor(address _pos) {
    owner = msg.sender;
    pos = IHypervisor(_pos);
    pos.token0().approve(_pos, MAX_INT);
    pos.token1().approve(_pos, MAX_INT);
  }

  // @param deposit0 Amount of token0 transfered from sender to Hypervisor
  // @param deposit1 Amount of token1 transfered from sender to Hypervisor
  // @param to Address to which liquidity tokens are minted
  // @return shares Quantity of liquidity tokens minted as a result of deposit
  function deposit(
      uint256 deposit0,
      uint256 deposit1,
      address to
  ) external returns (uint256 shares) {
    require(!retired, "proxy retired"); 
    require(to != address(0) && to != address(this), "to");

    if(!list[msg.sender]) {
      require(deposit0 < deposit0Max && deposit1 < deposit1Max, "deposits must be less than maximum amounts");
    }  

    if(deposit0 != 0) {
      pos.token0().transferFrom(msg.sender, address(this), deposit0);
    }
    if(deposit1 != 0) {
      pos.token1().transferFrom(msg.sender, address(this), deposit1);
    }
    shares = pos.deposit(deposit0, deposit1, address(this));
    pos.transfer(to, shares);
  }

  function changeHypervisor(address _pos) external {
    require(msg.sender == owner, "Only owner");
    pos = IHypervisor(_pos);
    pos.token0().approve(_pos, MAX_INT);
    pos.token1().approve(_pos, MAX_INT);
  }

  function transferOwnership(address newOwner) external {
      require(msg.sender == owner, "Only owner");
      owner = newOwner;
  }

  function setDepositMax(uint256 _deposit0Max, uint256 _deposit1Max) external {
      require(msg.sender == owner, "Only owner");
      deposit0Max = _deposit0Max;
      deposit1Max = _deposit1Max;
  }

  function appendList(address[] memory listed) external {
      require(msg.sender == owner, "Only owner");
      for (uint8 i; i < listed.length; i++) {
        list[listed[i]] = true; 
      }
  }

  function removeListed(address listed) external {
      require(msg.sender == owner, "Only owner");
      list[listed] = false;
  }

  function retireProxy() external {
      require(msg.sender == owner, "Only owner");
      retired = true;
  }

}
