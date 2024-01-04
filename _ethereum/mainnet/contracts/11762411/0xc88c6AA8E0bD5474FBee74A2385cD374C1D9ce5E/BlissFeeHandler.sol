pragma solidity ^0.6.0;

import "./IERC20.sol";
import "./AccessControl.sol";
import "./IUniswapV2Router02.sol";
import "./IUniswapV2Pair.sol";
import "./UniswapV2Library.sol";

interface ILPERC20Staking {
  function epochCalculationStartBlock() external returns (uint256);

  function addPendingRewards() external;

  function startNewEpoch() external;
}

interface IBliss is IERC20 {
  function toggleFeeless(address _for) external;

  function UniswapETHPair() external returns (address);
}

/** @dev This contract receives Bliss fees and is used to market sell that fee and buy WBTC with the ETH amount gained.
 * The wBTC bought is then sent into a staking contract
 */
contract BlissFeeHandler is AccessControlUpgradeSafe {
  bytes32 public constant TOKEN_ROLE = keccak256("TOKEN_ROLE");

  using SafeMath for uint256;

  // tokens
  IERC20 public wbtc;
  IBliss public bliss;

  // staking contract that receives the wBTC
  ILPERC20Staking public feeReceiver;

  // uniswap contracts
  IUniswapV2Router02 public UNIRouter;
  address public UNIFactory;

  // enlighten-caller rewards
  uint256 public callerRewardDivisor;

  // min amount to hold bliss for enlighten call
  uint256 public minRebalanceAmount;

  // last time enlighten was called
  uint256 public lastRebalance;

  // wait time to call it again
  uint256 public rebalanceInterval;

  event Enlightenment(uint256);

  // Initializer due proxy usage
  function initialize(
    address _wbtc,
    address _feeReceiver,
    address _bliss,
    address _uniRouter,
    address _uniFactory
  ) external initializer {
    __AccessControl_init();

    // wbtc token
    wbtc = IERC20(_wbtc);

    // wbtc receiver
    feeReceiver = ILPERC20Staking(_feeReceiver);

    UNIRouter = IUniswapV2Router02(_uniRouter);
    UNIFactory = _uniFactory;

    // bliss protocol token
    bliss = IBliss(_bliss);

    bliss.approve(address(UNIRouter), uint256(-1));
    wbtc.approve(address(UNIRouter), uint256(-1));
    IERC20(UNIRouter.WETH()).approve(address(UNIRouter), uint256(-1));

    lastRebalance = block.timestamp;

    // enlighten caller rewards
    callerRewardDivisor = 25;

    // how often enlighten can be called
    rebalanceInterval = 5 minutes;

    // min amount of bliss to hold
    minRebalanceAmount = 100 ether;
  }

  // Sets the wBTC receiver
  function setFeeReceiver(address _newReceiver) external onlyOwner {
    feeReceiver = ILPERC20Staking(_newReceiver);
  }

  // Set the interval time for allowing purchases of wBTC
  function setRebalanceInterval(uint256 _interval) external onlyOwner {
    rebalanceInterval = _interval;
  }

  // Sets the amount rewarded from wBTC bought to caller
  function setCallerRewardDivisior(uint256 _rewardDivisor) external onlyOwner {
    if (_rewardDivisor != 0) {
      require(_rewardDivisor >= 10, "BLISS::setCallerRewardDivisor: too small");
    }
    callerRewardDivisor = _rewardDivisor;
  }

  // Set the minimum amount of Bliss that the enlighten-caller must hold.
  function setMinRebalanceAmount(uint256 amount_) external onlyOwner {
    minRebalanceAmount = amount_;
  }

  // Set wBTC contract address
  function setwBTC(address _newImpl) external onlyOwner {
    wbtc = IERC20(_newImpl);
  }

  // Refresh approval values
  function refreshApprovals() external onlyOwner {
    bliss.approve(address(UNIRouter), uint256(-1));
    wbtc.approve(address(UNIRouter), uint256(-1));
  }

  // Sell Bliss and purchase wBTC.
  // Set a slippage value for trades - 1000 = 10%.
  function enlighten(uint256 _slippage) external {
    // validate caller Bliss-balance and interval.
    require(bliss.balanceOf(msg.sender) >= minRebalanceAmount, "You aren't enlightened enough.");
    require(block.timestamp > lastRebalance + rebalanceInterval, "Too Soon.");

    // bookkeep last time this func is called
    lastRebalance = block.timestamp;

    // swappable supply is the bliss-balance of this contract
    uint256 blissFees = bliss.balanceOf(address(this));

    // swap for WBTC
    address[] memory pathETH = new address[](2);
    pathETH[0] = address(bliss);
    pathETH[1] = UNIRouter.WETH();

    // remove tx fees from the call
    bliss.toggleFeeless(address(UNIRouter));
    bliss.toggleFeeless(bliss.UniswapETHPair());

    // avoid stack errors with scoping here
    {
      (uint256 reserveA, uint256 reserveB) = UniswapV2Library.getReserves(UNIFactory, pathETH[0], pathETH[1]);
      uint256 ETHOut = UniswapV2Library.getAmountOut(blissFees, reserveA, reserveB);

      // swap bliss for ETH - apply slippage
      (bool success, ) =
        address(UNIRouter).call(
          abi.encodePacked(
            UNIRouter.swapExactTokensForTokens.selector,
            abi.encode(blissFees, ETHOut.sub(ETHOut.mul(_slippage).div(10000)), pathETH, address(this), block.timestamp + 1 hours)
          )
        );
      require(success, "!eth swap");
    }

    // do wbtc swap
    address[] memory pathWBTC = new address[](2);
    pathWBTC[0] = UNIRouter.WETH();
    pathWBTC[1] = address(wbtc);

    // avoid stack errors with scoping here
    {
      (uint256 reserveC, uint256 reserveD) = UniswapV2Library.getReserves(UNIFactory, pathWBTC[0], pathWBTC[1]);
      uint256 WBTCOut = UniswapV2Library.getAmountOut(IERC20(pathWBTC[0]).balanceOf(address(this)), reserveC, reserveD);

      // get wbtc - apply slippage
      (bool success, ) =
        address(UNIRouter).call(
          abi.encodePacked(
            UNIRouter.swapExactTokensForTokens.selector,
            abi.encode(
              IERC20(UNIRouter.WETH()).balanceOf(address(this)),
              WBTCOut.sub(WBTCOut.mul(_slippage).div(10000)),
              pathWBTC,
              address(this),
              block.timestamp + 1 hours
            )
          )
        );

      require(success, "!wbtc swap");
    }

    // calculate rewards for caller
    uint256 wbtcBal = wbtc.balanceOf(address(this));
    uint256 callerReward = wbtcBal.div(callerRewardDivisor);
    uint256 feeReceiverAmount = wbtcBal.sub(callerReward);

    // transfer the tokens to receiver and reward caller
    wbtc.transfer(_msgSender(), callerReward);
    wbtc.transfer(address(feeReceiver), feeReceiverAmount);

    // start a new calc epoch on the receiver contract if possible
    // if (feeReceiver.epochCalculationStartBlock() + 50000 < block.number) feeReceiver.startNewEpoch();
    // feeReceiver.addPendingRewards();

    // revert fee list toggles
    bliss.toggleFeeless(address(UNIRouter));
    bliss.toggleFeeless(bliss.UniswapETHPair());

    // send out event
    emit Enlightenment(feeReceiverAmount);
  }

  // Rescue any missent tokens to the contract
  function recoverERC20(address tokenAddress, uint256 tokenAmount) external onlyOwner {
    IERC20(tokenAddress).transfer(_msgSender(), tokenAmount);
  }

  modifier onlyOwner() {
    require(hasRole(DEFAULT_ADMIN_ROLE, _msgSender()), "!owner");
    _;
  }
}
