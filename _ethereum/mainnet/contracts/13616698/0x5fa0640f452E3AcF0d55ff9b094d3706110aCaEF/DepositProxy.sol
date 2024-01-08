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
  bool public freeDeposit = false;
  uint256 public depositDelta = 1e17;
  uint256 public ratio;
  uint256 MAX_INT = 2**256 - 1;
  
  constructor(address _pos, uint256 _ratio) {
    owner = msg.sender;
    pos = IHypervisor(_pos);
    pos.token0().approve(_pos, MAX_INT);
    pos.token1().approve(_pos, MAX_INT);
    ratio = _ratio;
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
    if(!freeDeposit) {      
      require( deposit0 != 0 && deposit1 != 0, 'Cannot deposit 0');
      require(properDepositRatio(deposit0, deposit1), 'Improper ratio'); 
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

  function getDepositAmount(address token, uint256 deposit) external view returns(uint256) {
      if(token == address(pos.token0())) {
          //token0 amount, return token1 amount
          return deposit.div(ratio);
      }
      else {
          return deposit.mul(ratio);
      }
  }

  function properDepositRatio(uint256 deposit0, uint256 deposit1) public view returns(bool) {
      return (
        deposit1.mul(ratio) < deposit0.add(1e17) &&      
        deposit1.mul(ratio) > deposit0.sub(1e17)
      );
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

  function setTokenRatio(uint256 _ratio) external {
      require(msg.sender == owner, "Only owner");
      ratio = _ratio;
  }

  function setDepositDelta(uint256 _depositDelta) external {
      require(msg.sender == owner, "Only owner");
      depositDelta = _depositDelta;
  }

  function toggleDepositFree() external {
      require(msg.sender == owner, "Only owner");
      freeDeposit = !freeDeposit;
  }

}
