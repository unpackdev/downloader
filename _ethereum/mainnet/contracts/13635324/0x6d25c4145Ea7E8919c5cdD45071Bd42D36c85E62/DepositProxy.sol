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
  address public client;
  address public keeper;
  uint256 public deposit0Max;
  uint256 public deposit1Max;
  uint256 public maxTotalSupply;
  bool public retired = false; 
  mapping(address=>bool) public list;

  uint256 MAX_INT = 2**256 - 1;

  constructor(address _pos) {
    owner = msg.sender;
    client = msg.sender;
    keeper = msg.sender;
    pos = IHypervisor(_pos);
    pos.token0().approve(_pos, MAX_INT);
    pos.token1().approve(_pos, MAX_INT);
  }

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
    require(maxTotalSupply == 0 || pos.totalSupply() <= maxTotalSupply, "maxTotalSupply");
  }

  function deposit(
        uint256 deposit0,
        uint256 deposit1
  ) external {
    require(msg.sender == keeper, "Only keeper allowed to execute deposit");
    pos.deposit(deposit0, deposit1, client);
  }

  function depositAll() external {
    require(msg.sender == keeper, "Only keeper allowed to execute deposit");
    pos.deposit(
      pos.token0().balanceOf(address(this)),
      pos.token1().balanceOf(address(this)),
      client
    );
  }

  function withdraw(uint256 shares) external {
    require(msg.sender == client, "Only client allowed to withdraw");
    pos.transferFrom(client, address(this), shares);
    pos.withdraw(shares, client, address(this));
  }

  function withdrawAll() external {
    require(msg.sender == client, "Only client allowed to withdraw");
    pos.transferFrom(client, address(this), pos.balanceOf(client)); 
    pos.withdraw(pos.balanceOf(address(this)), client, address(this));
  }

  function sweepTokens(address token) external {
    require(msg.sender == client, "Only client allowed to pull tokens");
    IERC20(token).transfer(owner, IERC20(token).balanceOf(address(this)));
  }

  function transferClient(address newClient) external {
    require(msg.sender == client, "Only client allowed to change client");
    client = newClient;
  }

  function transferKeeper(address newKeeper) external {
    require(msg.sender == owner, "Only owner allowed to change keeper");
    keeper = newKeeper; 
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

  function setMaxTotalSupply(uint256 _maxTotalSupply) external {
      require(msg.sender == owner, "Only owner");
      maxTotalSupply = _maxTotalSupply;
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
