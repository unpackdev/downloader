pragma solidity ^0.5.17;

// yarn add @openzeppelin/contracts@2.5.1
import "./IERC20.sol";
import "./SafeMath.sol";
import "./Address.sol";
import "./SafeERC20.sol";
import "./console.sol";

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

interface IVoterProxy {
  function withdraw(
    address _gauge,
    address _token,
    uint256 _amount
  ) external returns (uint256);

  function balanceOf(address _gauge) external view returns (uint256);

  function withdrawAll(address _gauge, address _token)
    external
    returns (uint256);

  function deposit(address _gauge, address _token) external;

  function harvest(address _gauge, bool _snxRewards) external;

  function lock() external;
}

interface Sushi {
  function swapExactTokensForTokens(
    uint256,
    uint256,
    address[] calldata,
    address,
    uint256
  ) external;

  function getAmountsOut(uint256, address[] calldata)
    external
    returns (uint256[] memory);
}

interface ICurveFi {
  function add_liquidity(uint256[3] calldata, uint256) external;

  function calc_token_amount(uint256[3] calldata, bool)
    external
    returns (uint256);
}

contract Strategy3CrvConvex {
  using SafeERC20 for IERC20;
  using Address for address;
  using SafeMath for uint256;

  // 3crv
  address public constant want =
    address(0x6c3F90f043a72FA612cbac8115EE7e52BDe6E490);

  address public constant crv =
    address(0xD533a949740bb3306d119CC777fa900bA034cd52);

  address public constant cvx =
    address(0x4e3FBD56CD56c3e72c1403e103b45Db9da5B9D2B);

  address public constant usdc =
    address(0xA0b86991c6218b36c1d19D4a2e9Eb0cE3606eB48);

  address public constant weth =
    address(0xC02aaA39b223FE8D0A0e5C4F27eAD9083C756Cc2);

  address public constant voter =
    address(0x52f541764E6e90eeBc5c21Ff570De0e2D63766B6);

  address public constant sushiRouter =
    address(0xd9e1cE17f2641f24aE83637ab66a2cca9C378B9F);

  address public constant curve =
    address(0xbEbc44782C7dB0a1A60Cb6fe97d0b483032FF1C7);

  uint256 public keepCRV = 1000;
  uint256 public performanceFee = 1500;
  uint256 public withdrawalFee = 50;
  uint256 public constant FEE_DENOMINATOR = 10000;

  address public proxy;

  address public governance;
  address public controller;
  address public strategist;

  uint256 public earned; // lifetime strategy earnings denominated in `want` token

  // convex booster
  address public booster;
  address public baseRewardPool;

  event Harvested(uint256 wantEarned, uint256 lifetimeEarned);

  modifier onlyGovernance() {
    require(msg.sender == governance, '!governance');
    _;
  }

  modifier onlyController() {
    require(msg.sender == controller, '!controller');
    _;
  }

  constructor(address _controller, address _proxy) public {
    governance = msg.sender;
    strategist = msg.sender;
    controller = _controller;
    proxy = _proxy;
    booster = address(0xF403C135812408BFbE8713b5A23a04b3D48AAE31);
    baseRewardPool = address(0x689440f2Ff927E1f24c72F1087E1FAF471eCe1c8);
  }

  function getName() external pure returns (string memory) {
    return 'Strategy3CrvConvex';
  }

  function setStrategist(address _strategist) external {
    require(
      msg.sender == governance || msg.sender == strategist,
      '!authorized'
    );
    strategist = _strategist;
  }

  function setKeepCRV(uint256 _keepCRV) external onlyGovernance {
    keepCRV = _keepCRV;
  }

  function setWithdrawalFee(uint256 _withdrawalFee) external onlyGovernance {
    withdrawalFee = _withdrawalFee;
  }

  function setPerformanceFee(uint256 _performanceFee) external onlyGovernance {
    performanceFee = _performanceFee;
  }

  function setProxy(address _proxy) external onlyGovernance {
    proxy = _proxy;
  }

  function deposit() public {
    uint256 _want = IERC20(want).balanceOf(address(this));
    IERC20(want).safeApprove(booster, 0);
    IERC20(want).safeApprove(booster, _want);
    IBooster(booster).depositAll(9, true);
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

  // slippageCRV = 100 for 1% max slippage
  function harvest(
    uint256 maxSlippageCRV,
    uint256 maxSlippageCVX,
    uint256 maxSlippageCRVAddLiquidity
  ) public {
    require(
      msg.sender == strategist || msg.sender == governance,
      '!authorized'
    );
    IBaseRewardPool(baseRewardPool).getReward(address(this), true);

    uint256 _crv = IERC20(crv).balanceOf(address(this));
    uint256 _cvx = IERC20(cvx).balanceOf(address(this));

    if (_crv > 0) {
      uint256 _keepCRV = _crv.mul(keepCRV).div(FEE_DENOMINATOR);

      IERC20(crv).safeTransfer(voter, _keepCRV);
      _crv = _crv.sub(_keepCRV);

      IERC20(crv).safeApprove(sushiRouter, 0);
      IERC20(crv).safeApprove(sushiRouter, _crv);

      address[] memory path = new address[](3);
      path[0] = crv;
      path[1] = weth;
      path[2] = usdc;

      uint256[] memory _amounts = Sushi(sushiRouter).getAmountsOut(_crv, path);
      uint256 _minimalAmount =
        _amounts[2].mul(10000 - maxSlippageCRV).div(10000);

      Sushi(sushiRouter).swapExactTokensForTokens(
        _crv,
        _minimalAmount,
        path,
        address(this),
        now.add(1800)
      );
    }

    if (_cvx > 0) {
      IERC20(cvx).safeApprove(sushiRouter, 0);
      IERC20(cvx).safeApprove(sushiRouter, _cvx);

      address[] memory path = new address[](3);
      path[0] = cvx;
      path[1] = weth;
      path[2] = usdc;

      uint256[] memory _amounts = Sushi(sushiRouter).getAmountsOut(_cvx, path);
      uint256 _minimalAmount =
        _amounts[2].mul(10000 - maxSlippageCVX).div(10000);

      Sushi(sushiRouter).swapExactTokensForTokens(
        _cvx,
        _minimalAmount,
        path,
        address(this),
        now.add(1800)
      );
    }

    uint256 _usdc = IERC20(usdc).balanceOf(address(this));

    if (_usdc > 0) {
      IERC20(usdc).safeApprove(curve, 0);
      IERC20(usdc).safeApprove(curve, _usdc);

      uint256 _tokenAmount =
        ICurveFi(curve).calc_token_amount([0, _usdc, 0], true);

      uint256 _minimalAmount =
        _tokenAmount.mul(10000 - maxSlippageCRVAddLiquidity).div(10000);
      ICurveFi(curve).add_liquidity([0, _usdc, 0], _minimalAmount);
    }

    uint256 _want = IERC20(want).balanceOf(address(this));

    if (_want > 0) {
      uint256 _fee = _want.mul(performanceFee).div(FEE_DENOMINATOR);
      IERC20(want).safeTransfer(IController(controller).rewards(), _fee);
      deposit();
    }

    IVoterProxy(proxy).lock();
    earned = earned.add(_want);
    emit Harvested(_want, earned);
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
