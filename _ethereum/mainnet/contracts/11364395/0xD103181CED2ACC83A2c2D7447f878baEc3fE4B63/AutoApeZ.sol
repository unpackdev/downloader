pragma solidity ^0.6.12;

import "./IERC20.sol";
import "./SafeMath.sol";
import "./Address.sol";
import "./SafeERC20.sol";
import "./ERC20.sol";
import "./Ownable.sol";
import "./console.sol";

interface IAAVEPoolAddressProvider {
  function getLendingPoolCore() external view returns (address payable);
  function getLendingPool() external view returns (address);
}

interface IAAVE {
  function addressesProvider() external view returns (address);
  function deposit(address _reserve, uint256 _amount, uint16 _referralCode) external payable;
}

interface IAToken {
  function redeem(uint256 amount) external;
}

interface IUniswap {
  function swapExactTokensForTokens(
    uint amountIn,
    uint amountOutMin,
    address[] calldata path,
    address to,
    uint deadline
  ) external returns (uint[] memory amounts);

  function getAmountsOut(
    uint amountIn,
    address[] memory path
  ) external returns (uint[] memory amounts);
}

interface IZGov {
  function exit() external;
  function stake(uint256 amount) external;
  function withdraw(uint256 amount) external;
}

contract AutoApeZ is ERC20, Ownable {
  using SafeERC20 for IERC20;
  using Address for address;
  using SafeMath for uint256;


  address internal constant UNISWAP_ROUTER_ADDRESS = 0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D;
  address internal constant WETH = 0xC02aaA39b223FE8D0A0e5C4F27eAD9083C756Cc2;

  event Caged(address ape);
  event Escaped(address ape);
  event CageReward(uint256 cageReward);
  event BananaSplit(uint256 wantCost, uint256 giveBought);
  event SmashBananas(uint256 wantCost, uint256 giveBought);


  modifier furnace() {
    bool isPowerOff = !hotCage;
    if (isPowerOff) {
      hotCage = true; // lets turn it on then
    }

    _;

    if (isPowerOff) {
      hotCage = false;
    }
  }

  IUniswap public uniswapRouter;

  address public apeCage; //balancer or uniswap pool with apeshares:zHedgic

  address public apeGain;//aave lendingpool provider

  IERC20 public want;  //dai
  IERC20 public gain; //adai
  IERC20 public give; //zlot
  IERC20 public zReward; //zhedgic

  IZGov public zgov; //zGovernance

  uint256 public wantpool; // bananas captured
  uint256 public givepool; // zlot captured

  uint256 public apeRate; //max dai spent per purchase
  uint256 public brainRate; //new shares per brain
  uint256 public apeLock; //how often the cage can be opened
  uint256 public cageSplit; //how much of the reward gets droped into the cagepool

  uint256 public nextBrain; //next time the cage can be opened

  bool private hotCage = false; // if the furnance is turned on you can't touch new shares

  constructor(
    address _want,
    address _gain,
    address _apeGain,
    address _give,
    address _zgov,
    address _zreward
  )
  public
  ERC20(
    string(abi.encodePacked("AutoApeZ ", ERC20(_give).name())),
    string(abi.encodePacked("AutoApeZ", ERC20(_give).symbol()))
  )
  {
    uniswapRouter = IUniswap(UNISWAP_ROUTER_ADDRESS);

    want = IERC20(_want);
    gain = IERC20(_gain);
    give = IERC20(_give);
    zgov = IZGov(_zgov);
    zReward = IERC20(_zreward);

    apeGain = _apeGain;
    apeRate = 100e18; // 100 adai per hour
    brainRate = 20e18; //20 dai composite(as if deposited ~20 dai into the pool at 50 gwei) per brain, not triggered on bigBrain exits
    apeLock = 240;
    wantpool = 0;
    givepool = 0;
    cageSplit = 2; // zreward split cage -> share holders
    nextBrain = block.number;
  }

  function setApeRate(uint256 _newApeRate) onlyOwner public {
    apeRate = _newApeRate;
  }
  function setBrainRate(uint256 _newBrainRate) onlyOwner public {
    apeRate = _newBrainRate;
  }

  function setApeLock(uint256 _newApeLock) onlyOwner public {
    apeLock = _newApeLock;
  }

  function setCageSplit(uint256 _newCageSplit) onlyOwner public {
    cageSplit = _newCageSplit;
  }

  function setApeCage(address _apeCage) onlyOwner public {
    apeCage = _apeCage;
  }

  function balanceWant() public view returns (uint256) {
    return wantpool;
  }

  function balanceGive() public view returns (uint256) {
    return givepool;
  }

  function ape() public {
    uint256 apeIn = want.allowance(msg.sender, address(this));
    uint256 apeWantBalance = want.balanceOf(msg.sender);
    if (apeWantBalance < apeIn) {
      apeIn = apeWantBalance;
    }
    deposit(apeIn);
  }

  function _depositFundsToPool(uint _amount) internal {
    IAAVEPoolAddressProvider provider = IAAVEPoolAddressProvider(apeGain);
    IAAVE lendingPool = IAAVE(provider.getLendingPool());
    want.approve(provider.getLendingPoolCore(), _amount);

    lendingPool.deposit(address(want), _amount, uint16(0)); //can we get a referral code??
  }

  function _removeApeRateFromAAVE() internal {
    IAToken(address(gain)).redeem(apeRate);
  }

  function deposit(uint256 _amount) public {
    uint256 _pool = balanceWant();
    uint256 _before = want.balanceOf(address(this));
    want.safeTransferFrom(msg.sender, address(this), _amount);
    uint256 _after = want.balanceOf(address(this));
    _amount = _after.sub(_before); // Additional check for deflationary tokens
    _depositFundsToPool(_amount); // deposit into aave
    wantpool = wantpool.add(_amount);

    uint256 shares = 0;
    if (totalSupply() == 0) {
      shares = _amount;
    } else {
      shares = (_amount.mul(totalSupply())).div(_pool);
    }
    _mint(msg.sender, shares);
    emit Caged(msg.sender);
  }

  function escape() public {
    _withdraw(balanceOf(msg.sender));
    emit Escaped(msg.sender);
  }

  function isCageHot() internal view returns (bool) {
    return hotCage;
  }

  function _swapBananasForZ() internal {
    _removeApeRateFromAAVE();
    want.approve(address(uniswapRouter), apeRate);
    address[] memory path =  new address[](2);
    path[0] = address(want);
    path[1] = address(give);

    uint256[] memory amounts = uniswapRouter.getAmountsOut(apeRate, path);
    uint256 amountOut = amounts[amounts.length - 1];

    uniswapRouter.swapExactTokensForTokens(apeRate, amountOut, path, address(this), block.timestamp);
    givepool = givepool.add(amountOut);
    emit SmashBananas(apeRate, amountOut);
  }

  function _swapRewardsForZ() internal {
      uint256 amountIn = zReward.balanceOf(address(this)).div(cageSplit);
      zReward.approve(address(uniswapRouter), amountIn);
      address[] memory path = new address[](3);
      path[0] = address(zReward);
      path[1] = address(WETH);
      path[2] = address(give);
      uint256[] memory amounts = uniswapRouter.getAmountsOut(amountIn, path);
      uint256 amountOut = amounts[amounts.length - 1];

      uniswapRouter.swapExactTokensForTokens(amountIn, amountOut, path, address(this), block.timestamp);
      givepool = givepool.add(amountOut);
      emit BananaSplit(amountIn, amountOut);
    }

  function brain() public {
    require(( block.number >= nextBrain), "Slow down chimp, you gotta wait until the lock passes to do that"); // gets called by the bot, or by an ape trying to claim z. You want out you gotta front run the bot, and pay rewards out for everyone.
    nextBrain = block.number.add(apeLock);

    _swapBananasForZ();
    give.approve(address(zgov), give.balanceOf(address(this))); // approve zgov to deposit our newly acquired Z
    zgov.stake(give.balanceOf(address(this)));
    if (!isCageHot()) {
      uint256 newShares = (brainRate.mul(totalSupply())).div(balanceWant());
      _mint(msg.sender, newShares);
    }
  }

  function bigBrain() public {
    exitRewards();
    brain();
  }

  function _withdraw(uint256 _shares) furnace internal {
    uint256 gr = (balanceGive().mul(_shares)).div(totalSupply());
    uint256 wr = (balanceWant().mul(_shares)).div(totalSupply());
    _burn(msg.sender, _shares);
    // Check balance
    require(gr <= balanceGive(), "you have more shares than the balance of the vault: degen u fucked up ");
    givepool = givepool.sub(gr); // we no longer hve this zlot so reduce our internal count
    wantpool = wantpool.sub(wr); // we no longer want to weight their original contribution anymore, so that if they leave offside the weight is better for new players
    zgov.withdraw(gr);
    give.safeTransfer(msg.sender, gr);
    if (isBigBrain(gr)) { //whales can leave anytime but they pay their own ape tax, can only leave with pro rata of give acquired not want deposited.
      bigBrain();
    }
  }

  function isBigBrain(uint256 apeShareRatio) public view returns(bool) {
    return (givepool.div(cageSplit) > apeShareRatio);
  }

  function getPricePerFullShare() public view returns (uint256) {
    return balanceGive().mul(1e18).div(totalSupply());
  }

  function _cageRewards() internal {
    uint256 cageReward = zReward.balanceOf(address(this));
    zReward.safeTransfer(apeCage, cageReward);
    emit CageReward(cageReward);
  }

  function exitRewards() public {
    zgov.exit();
    _swapRewardsForZ();
    _cageRewards();
  }
}