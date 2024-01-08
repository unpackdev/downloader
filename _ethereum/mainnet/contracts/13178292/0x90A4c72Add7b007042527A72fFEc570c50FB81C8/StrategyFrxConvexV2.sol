pragma solidity ^0.5.17;

// yarn add @openzeppelin/contracts@2.5.1
import "./IERC20.sol";
import "./SafeMath.sol";
import "./Address.sol";
import "./SafeERC20.sol";

interface IBooster {
  function depositAll(uint256 _pid, bool _stake) external returns (bool);
}

interface IBaseRewardPool {
  function withdrawAndUnwrap(uint256 amount, bool claim)
    external
    returns (bool);

  function withdrawAllAndUnwrap(bool claim) external;

  function getReward(address _account, bool _claimExtras)
    external
    returns (bool);

  function balanceOf(address) external view returns (uint256);
}

interface IController {
  function withdraw(address, uint256) external;

  function balanceOf(address) external view returns (uint256);

  function earn(address, uint256) external;

  function want(address) external view returns (address);

  function rewards() external view returns (address);

  function vaults(address) external view returns (address);

  function strategies(address) external view returns (address);
}


contract StrategyFrxConvexV2 {
  using SafeERC20 for IERC20;
  using Address for address;
  using SafeMath for uint256;

  // Frax3crv
  address public constant want =
    address(0xd632f22692FaC7611d2AA1C0D552930D43CAEd3B);

  address public constant fxs =
    address(0x3432B6A60D23Ca0dFCa7761B7ab56459D9C964D0);

  address public constant crv =
    address(0xD533a949740bb3306d119CC777fa900bA034cd52);

  address public constant cvx =
    address(0x4e3FBD56CD56c3e72c1403e103b45Db9da5B9D2B);

  uint256 public withdrawalFee = 50;
  uint256 public constant FEE_DENOMINATOR = 10000;

  address public governance;
  address public controller;
  address public strategist;

  address public fraxFeeDistribution;
  address public stakedaoFeeDistribution;

  // convex booster
  address public booster;
  address public baseRewardPool;

  modifier onlyGovernance() {
    require(msg.sender == governance, '!governance');
    _;
  }

  modifier onlyController() {
    require(msg.sender == controller, '!controller');
    _;
  }

  constructor(
    address _controller,
    address _fraxFeeDistribution,
    address _stakedaoFeeDistribution
  ) public {
    governance = msg.sender;
    strategist = msg.sender;
    controller = _controller;
    fraxFeeDistribution = _fraxFeeDistribution;
    stakedaoFeeDistribution = _stakedaoFeeDistribution;

    booster = address(0xF403C135812408BFbE8713b5A23a04b3D48AAE31);
    baseRewardPool = address(0xB900EF131301B307dB5eFcbed9DBb50A3e209B2e);
  }

  function getName() external pure returns (string memory) {
    return 'StrategyFrxConvexV2';
  }

  function setStrategist(address _strategist) external {
    require(
      msg.sender == governance || msg.sender == strategist,
      '!authorized'
    );
    strategist = _strategist;
  }

  function setWithdrawalFee(uint256 _withdrawalFee) external onlyGovernance {
    withdrawalFee = _withdrawalFee;
  }

  function setFraxFeeDistribution(address _fraxFeeDistribution)
    external
    onlyGovernance
  {
    fraxFeeDistribution = _fraxFeeDistribution;
  }

  function setStakedaoFeeDistribution(address _stakedaoFeeDistribution)
    external
    onlyGovernance
  {
    stakedaoFeeDistribution = _stakedaoFeeDistribution;
  }

  function deposit() public {
    uint256 _want = IERC20(want).balanceOf(address(this));
    IERC20(want).safeApprove(booster, 0);
    IERC20(want).safeApprove(booster, _want);
    IBooster(booster).depositAll(32, true);
  }

  // Controller only function for creating additional rewards from dust
  function withdraw(IERC20 _asset)
    external
    onlyController
    returns (uint256 balance)
  {
    require(want != address(_asset), 'want');
    require(cvx != address(_asset), 'cvx');
    require(crv != address(_asset), 'crv');
    balance = _asset.balanceOf(address(this));
    _asset.safeTransfer(controller, balance);
  }

  // Withdraw partial funds, normally used with a vault withdrawal
  function withdraw(uint256 _amount) external onlyController {
    uint256 _balance = IERC20(want).balanceOf(address(this));
    if (_balance < _amount) {
      _amount = _withdrawSome(_amount.sub(_balance));
      _amount = _amount.add(_balance);
    }

    uint256 _fee = _amount.mul(withdrawalFee).div(FEE_DENOMINATOR);

    IERC20(want).safeTransfer(IController(controller).rewards(), _fee);
    address _vault = IController(controller).vaults(address(want));
    require(_vault != address(0), '!vault'); // additional protection so we don't burn the funds
    IERC20(want).safeTransfer(_vault, _amount.sub(_fee));
  }

  function _withdrawSome(uint256 _amount) internal returns (uint256) {
    uint256 wantBefore = IERC20(want).balanceOf(address(this));
    IBaseRewardPool(baseRewardPool).withdrawAndUnwrap(_amount, false);
    uint256 wantAfter = IERC20(want).balanceOf(address(this));
    return wantAfter.sub(wantBefore);
  }

  // Withdraw all funds, normally used when migrating strategies
  function withdrawAll() external onlyController returns (uint256 balance) {
    _withdrawAll();

    balance = IERC20(want).balanceOf(address(this));

    address _vault = IController(controller).vaults(address(want));
    require(_vault != address(0), '!vault'); // additional protection so we don't burn the funds
    IERC20(want).safeTransfer(_vault, balance);
  }

  function _withdrawAll() internal {
    IBaseRewardPool(baseRewardPool).withdrawAllAndUnwrap(false);
  }

  function harvest()
    public
  {
    require(
      msg.sender == strategist || msg.sender == governance,
      '!authorized'
    );
    IBaseRewardPool(baseRewardPool).getReward(address(this), true);

    uint256 _crv = IERC20(crv).balanceOf(address(this));
    uint256 _cvx = IERC20(cvx).balanceOf(address(this));
    uint256 _fxs = IERC20(fxs).balanceOf(address(this));

    if (_crv > 0) {
      IERC20(crv).safeTransfer(stakedaoFeeDistribution, _crv);
    }

    if (_fxs > 0) {
      IERC20(fxs).safeTransfer(stakedaoFeeDistribution, _fxs);
    }

    if (_cvx > 0) {
      IERC20(cvx).safeTransfer(fraxFeeDistribution, _cvx);
    }
  }

  function balanceOfWant() public view returns (uint256) {
    return IERC20(want).balanceOf(address(this));
  }

  function balanceOfPool() public view returns (uint256) {
    return IBaseRewardPool(baseRewardPool).balanceOf(address(this));
  }

  function balanceOf() public view returns (uint256) {
    return balanceOfWant().add(balanceOfPool());
  }

  function setGovernance(address _governance) external onlyGovernance {
    governance = _governance;
  }

  function setController(address _controller) external onlyGovernance {
    controller = _controller;
  }
}
