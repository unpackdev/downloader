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
  address owner;
  uint256 MAX_INT = 2**256 - 1;
  bool public freeDeposit = false;
  uint256 public depositDelta = 20;

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
    if(!freeDeposit) {      
      require(properDepositRatio(deposit0, deposit1), 'Improper ratio'); 
    }
    if(deposit0 != 0) {
      pos.token0().transferFrom(msg.sender, address(this), deposit0);
    }
    if(deposit1 != 0) {
      pos.token1().transferFrom(msg.sender, address(this), deposit1);
    }
    shares = pos.deposit(deposit0, deposit1, to);
  }

  function properDepositRatio(uint256 deposit0, uint256 deposit1) public view returns (bool) {
      (uint256 hype0, uint256 hype1) = pos.getTotalAmounts();
      if (pos.totalSupply() != 0) {
          uint256 depositRatio = deposit0 == 0 ? 10e18 : deposit1.mul(1e18).div(deposit0);
          depositRatio = depositRatio > 10e18 ? 10e18 : depositRatio;
          depositRatio = depositRatio < 10e16 ? 10e16 : depositRatio;
          uint256 hypeRatio = hype0 == 0 ? 10e18 : hype1.mul(1e18).div(hype0);
          hypeRatio = hypeRatio > 10e18 ? 10e18 : hypeRatio;
          hypeRatio = hypeRatio < 10e16 ? 10e16 : hypeRatio;
          return (FullMath.mulDiv(depositRatio, 10, hypeRatio) < depositDelta &&
                  FullMath.mulDiv(hypeRatio, 10, depositRatio) < depositDelta);
      }
      return true;
  }

  function getDepositAmount(address token, uint256 deposit)
        external
        view
        returns (uint256 amountStart, uint256 amountEnd)
    {
        require(token == address(pos.token0()) || token == address(pos.token1()), "token mistmatch");
        require(deposit > 0, "deposits can't be zero");
        (uint256 total0, uint256 total1) = pos.getTotalAmounts();
        if (pos.totalSupply() == 0 || total0 == 0 || total1 == 0) return (0, 0);

        uint256 ratioStart = total0.mul(1e18).div(total1).mul(depositDelta).div(10); //1e17
        uint256 ratioEnd = total0.mul(1e18).div(total1).div(depositDelta).mul(10); // 1e19

        if (token == address(pos.token0())) {
            return (deposit.mul(1e18).div(ratioStart), deposit.mul(1e18).div(ratioEnd));
        }
        return (deposit.mul(ratioStart).div(1e18), deposit.mul(ratioEnd).div(1e18));
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

    function setDepositDelta(uint256 _depositDelta) external {
        require(msg.sender == owner, "Only owner");
        depositDelta = _depositDelta;
    }

    function toggleDepositFree() external {
        require(msg.sender == owner, "Only owner");
        freeDeposit = !freeDeposit;
    }

}
