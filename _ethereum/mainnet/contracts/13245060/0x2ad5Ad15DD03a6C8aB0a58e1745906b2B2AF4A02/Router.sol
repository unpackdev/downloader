import "./IHypervisor.sol";
import "./IERC20.sol";

contract Router {
  IHypervisor public pos;
  IERC20 public token0;
  IERC20 public token1;
  address public owner;
  address public client;
  uint256 MAX_INT = 2**256 - 1;

  constructor(
    address _token0,
    address _token1,
    address _pos,
    address _client
  ) {
    owner = msg.sender;
    token0 = IERC20(_token0);
    token1 = IERC20(_token1);
    pos = IHypervisor(_pos);
    client = _client;
    token0.approve(_pos, MAX_INT);
    token1.approve(_pos, MAX_INT);
  }

  function deposit(
        uint256 deposit0,
        uint256 deposit1
  ) external {
    pos.deposit(deposit0, deposit1, client);
  }

  function withdraw(uint256 shares) external {
    require(msg.sender == client, "Only client allowed to withdraw");
    pos.withdraw(shares, client, client);
  }

  function withdrawAll() external {
    require(msg.sender == client, "Only client allowed to withdraw");
    pos.withdraw(pos.balanceOf(client), client, client);
  }

  function transferOwnership(address newOwner) external {
    require(msg.sender == owner, "Only newOwner allowed to withdraw");
    owner = newOwner;
  }

  function transferClient(address newClient) external {
    require(msg.sender == owner, "Only newOwner allowed to withdraw");
    client = newClient;
  }

  function sweepTokens(address token) external {
    require(msg.sender == owner, "Only newOwner allowed to withdraw");
    IERC20(token).transfer(owner, IERC20(token).balanceOf(address(this)));
  }

}
