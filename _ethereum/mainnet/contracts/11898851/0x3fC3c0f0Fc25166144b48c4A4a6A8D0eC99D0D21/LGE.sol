// SPDX-License-Identifier: Apache-2.0
pragma solidity >=0.6.12;
import "./Address.sol";
import "./IERC20.sol";
import "./SafeERC20.sol";
import "./Ownable.sol";
import "./Console.sol";
import "./IWETH.sol";
import "./IUniswapV2Pair.sol";
import "./IUniswapV2Factory.sol";
import "./IUniswapV2Router02.sol";

contract LGE is Ownable {
  using SafeMath for uint256;
  using Address for address;
  using SafeERC20 for IERC20;

  event LPTokenClaimed(address dst, uint value);
  event LiquidityAdded(address indexed dst, uint value);

  address public fund;
  uint256 public fundFee;
  uint256 public fundPctLiq = 2000;

  uint256 constant FUND_BASE = 10000;
  uint256 constant MIN_FUND_PCT = 1000;
  uint256 constant MAX_FUND_PCT = 5000;
  uint256 constant MIN_LGE_LENGTH = 2 hours;
  uint256 constant MAX_LGE_LENGTH = 14 days;
  uint256 constant MIN_TOKEN_PER_ETH = 1;
  uint256 constant MIN_MIN_ETH = 1 ether / 10;
  uint256 constant MAX_MIN_ETH = 2 ether;
  uint256 constant MIN_MAX_ETH = 10 ether;
  uint256 constant MAX_MAX_ETH = 2000 ether;
  uint256 constant MIN_CAP = 500 ether;
  uint256 constant MAX_CAP = 50_000 ether;
  uint256 constant PRECISION = 1e18;

  IWETH Iweth;
  IERC20 ITOKEN;
  IUniswapV2Factory uniswapFactory;
  IUniswapV2Router02 uniswapRouterV2;

  uint256 public airdropTotal;
  mapping (address => uint256) public registeredAirdrop;
  mapping (address => uint256) public confirmedAirdrop;

  IUniswapV2Pair public IPAIR;
  uint256 minEth = 1 ether / 2;
  uint256 maxEth = 100 ether;
  uint256 cap = 1000 ether;
  uint256 public tokenPerEth = 2000;
  uint256 public lgeLength = 7 days;
  uint256 public contractStartTimestamp;
  bool public LGEFinished;
  uint256 public LPperETHUnit;
  uint256 public totalLPTokensMinted;
  uint256 public totalETHContributed;
  bool public LPGenerationCompleted;
  mapping (address => uint)  public ethContributed;

  constructor(address token, address owner, address _fund) public Ownable(owner) {
    fund = _fund;
    uniswapFactory = IUniswapV2Factory(0x5C69bEe701ef814a2B6a3EDD4B1652CB9cc5aA6f);
    uniswapRouterV2 = IUniswapV2Router02(0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D);

    ITOKEN = IERC20(token);
    address WETH = uniswapRouterV2.WETH();
    Iweth = IWETH(WETH);
  }

  function registerAirdrop(uint256 total) external {
    uint256 current = registeredAirdrop[msg.sender];
    registeredAirdrop[msg.sender] = total;
    airdropTotal = airdropTotal - current + total;
  }

  function setMinEth(uint256 _minEth) onlyOwner external {
    require(_minEth >= MIN_MIN_ETH && _minEth <= MAX_MIN_ETH);
    minEth = _minEth;
  }

  function setMaxEth(uint256 _maxEth) onlyOwner external {
    require(_maxEth >= MIN_MAX_ETH && _maxEth <= MAX_MAX_ETH);
    maxEth = _maxEth;
  }

  function setCap(uint256 _cap) onlyOwner external {
    require(_cap >= MIN_CAP && _cap <= MAX_CAP);
    cap = _cap;
  }

  function setFund(address _fund) onlyOwner external {
    require(_fund != address(0));
    fund = _fund;
  }

  function setToken(address _token) onlyOwner external {
    require(_token != address(0));
    ITOKEN = IERC20(_token);
  }

  function setFundPctLiq(uint256 _fundPctLiq) onlyOwner external {
    require(_fundPctLiq == 0 || (_fundPctLiq >= MIN_FUND_PCT && _fundPctLiq <= MAX_FUND_PCT));
    fundPctLiq = _fundPctLiq;
  }

  function setTokenPerEth(uint256 _tokenPerEth) onlyOwner external {
    require(_tokenPerEth >= MIN_TOKEN_PER_ETH, '!tokenPerEth');
    tokenPerEth = _tokenPerEth;
  }

  function setLGELength(uint256 _lgeLength) onlyOwner external {
    require(_lgeLength >= MIN_LGE_LENGTH && _lgeLength <= MAX_LGE_LENGTH, '!lgeLength');
    lgeLength = _lgeLength;
  }

  function startLGE() onlyOwner external {
    contractStartTimestamp = block.timestamp;
  }

  function _LGEStarted() internal view returns (bool) {
    return contractStartTimestamp != 0;
  }

  function setLGEFinished() public onlyOwner {
    LGEFinished = true;
  }

  function lgeInProgress() public view returns (bool) {
    if (!_LGEStarted() || LGEFinished) {
        return false;
    }
    return contractStartTimestamp.add(lgeLength) > block.timestamp;
  }

  function emergencyRescueEth(address to) onlyOwner external {
    require(to != address(0), '!to');
    require(block.timestamp >= contractStartTimestamp.add(lgeLength).add(2 days), 'must be 2 days after end of lge');
    (bool success, ) = to.call.value(address(this).balance)("");
    require(success, "Transfer failed.");
  }

  function generateLPTokens() public {
    require(lgeInProgress() == false, "LGE still in progress");
    require(LPGenerationCompleted == false, "LP tokens already generated");
    uint256 total = totalETHContributed; // gas

    // create pair
    address _pair = uniswapFactory.getPair(address(Iweth), address(ITOKEN));
    if (_pair == address(0)) {
      _pair = uniswapFactory.createPair(address(Iweth), address(ITOKEN));
    }
    IPAIR = IUniswapV2Pair(_pair);

    //Wrap eth
    Iweth.deposit{ value: total }();
    require(IERC20(address(Iweth)).balanceOf(address(this)) == total, '!weth');
    Iweth.transfer(address(IPAIR), total);

    uint256 tokenBalance = ITOKEN.balanceOf(address(this));
    ITOKEN.safeTransfer(address(IPAIR), tokenBalance);
    IPAIR.mint(address(this));
    totalLPTokensMinted = IPAIR.balanceOf(address(this));
    require(totalLPTokensMinted != 0 , "LP creation failed");
    if (fund != address(0)) {
      // send remaining ETH to fund
      (bool success, ) = fund.call.value(address(this).balance)("");
      require(success, "Transfer failed.");
    }
    // Calculate LP tokens per eth
    LPperETHUnit = totalLPTokensMinted.mul(PRECISION).div(total);
    require(LPperETHUnit != 0 , "LP creation failed");
    LPGenerationCompleted = true;
  }

  receive() external payable {
    require(lgeInProgress(), "!LGE in progress");
    _addLiquidity();
  }

  function addLiquidity() public payable {
    require(lgeInProgress(), "!LGE in progress");
    _addLiquidity();
  }

  function _addLiquidity() internal {
    require(msg.value >= minEth, '!minEth');
    uint256 fee = msg.value.mul(fundPctLiq).div(FUND_BASE);
    fundFee = fundFee.add(fee);
    uint256 contrib = msg.value.sub(fee, '!fee');
    ethContributed[msg.sender] += contrib;
    require(ethContributed[msg.sender] <= maxEth);
    totalETHContributed = totalETHContributed.add(contrib);
    require(totalETHContributed <= cap, '!cap');
    uint256 amount = contrib * tokenPerEth;
    if (amount > 0) {
      ITOKEN.safeTransferFrom(fund, address(this), amount);
    }
    emit LiquidityAdded(msg.sender, msg.value);
  }

  function claimLPTokens() public {
    require(LPGenerationCompleted, "!LP generated");
    uint256 airdrop = registeredAirdrop[msg.sender]; //gas
    registeredAirdrop[msg.sender] = 0;
    uint256 contributed = ethContributed[msg.sender]; // gas
    ethContributed[msg.sender] = 0;
    require(contributed > 0 , "Nothing to claim, move along");
    uint256 fee = airdrop.mul(fundPctLiq).div(FUND_BASE);
    if (contributed >= airdrop - fee) {
      confirmedAirdrop[msg.sender] = contributed;
    }
    uint256 amountLPToTransfer = contributed.mul(LPperETHUnit).div(PRECISION);
    IPAIR.transfer(msg.sender, amountLPToTransfer);
    emit LPTokenClaimed(msg.sender, amountLPToTransfer);
  }

}
