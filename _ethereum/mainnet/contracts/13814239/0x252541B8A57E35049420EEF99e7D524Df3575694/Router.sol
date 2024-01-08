import "./IHypervisor.sol";
import "./IERC20.sol";

contract Router {
  IHypervisor public pos;
  IERC20 public token0;
  IERC20 public token1;
  address public owner;
  address payable public client;
  address public keeper;
  uint256 MAX_INT = 2**256 - 1;

  constructor(
    address _token0,
    address _token1,
    address _pos
  ) {
    owner = msg.sender;
    client = msg.sender;
    keeper = msg.sender;
    token0 = IERC20(_token0);
    token1 = IERC20(_token1);
    pos = IHypervisor(_pos);

  }

  function approve() external {
    require(msg.sender == keeper, "Only keeper allowed to approve");
    token0.approve(address(pos), MAX_INT);
    token1.approve(address(pos), MAX_INT);
    pos.approve(address(pos), MAX_INT);
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
      token0.balanceOf(address(this)),
      token1.balanceOf(address(this)),
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
    require(msg.sender == owner, "Only owner allowed to pull tokens");
    IERC20(token).transfer(owner, IERC20(token).balanceOf(address(this)));
  }

  function sweepEth() external {
    require(msg.sender == owner, "Only owner allowed to pull tokens");
    client.transfer(address(this).balance);
  }

  function transferClient(address payable newClient) external {
    require(msg.sender == owner, "Only owner allowed to change client");
    client = newClient;
  }

  function transferKeeper(address newKeeper) external {
    require(msg.sender == keeper, "Only keeper allowed to change keeper");
    keeper = newKeeper; 
  }

  function transferOwnership(address newOwner) external {
    require(msg.sender == owner, "Only owner alloed to change owner");
    owner = newOwner;
  }

}
