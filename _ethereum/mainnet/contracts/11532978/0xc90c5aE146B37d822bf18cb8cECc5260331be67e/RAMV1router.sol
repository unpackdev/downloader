// SPDX-License-Identifier: MIT
pragma solidity 0.6.12;
pragma experimental ABIEncoderV2;

import "./Ownable.sol";
import "./IERC20.sol";
// import "./VRFConsumerBase.sol";
import "./Math.sol";
import "./UniswapV2Library.sol";
import "./INFT.sol";
import "./VRFConsumerBase.sol";
import "./INFTFactory.sol";
import "./IFeeApprover.sol";
import "./IRAMVault.sol";
import "./NFT.sol";
import "./StorageState.sol";

// This contract is supposed to streamline liquidity additions
// By allowing people to put in any amount of ETH or YGY and get LP tokens back
contract RAMv1Router is StorageState, OwnableUpgradeSafe, VRFConsumerBase {
  // RAM protocol variable
  IFeeApprover public _feeApprover;
  IRAMVault public _RAMVault;
  address public _uniV2Factory;

  // Governance and regenerator tax
  bool governanceSet;
  address public governance;
  address payable public regenerator;
  uint256 public regeneratorTax;

  // RNG
  uint256 public constant MAX = 2**256 - 1;
  uint256 public constant SCALE = 100;
  uint256 public constant SCALIFIER = MAX / SCALE;
  uint256 public constant OFFSET = 1;
  uint256 public rngLinkFee;
  bytes32 internal keyHash;

  address public _YGYRAMPair;
  address public _YGYToken;
  address public _YGYWETHPair;
  address public _RAMToken;
  IWETH public _WETH;
  IERC20 public _dXIOTToken;

  // Lottery tracking
  struct LotteryTicket {
    address owner;
    uint256 roundNumber;
    uint256 levelOneChance;
    uint256 levelTwoChance;
    uint256 levelThreeChance;
    uint256 levelFourChance;
    uint256 levelFiveChance;
  }
  uint256 public ticketCount;
  uint256 public lotteryRoundCounter;
  mapping(uint256 => uint256) public lotteryResults;

  // Mapping of user address => ticket number => ticket
  mapping(address => mapping(uint256 => LotteryTicket)) public userTickets;
  mapping(address => uint256) public userTicketCount;
  mapping(address => uint256) public userTopTicketStack;

  // NFT
  INFTFactory public _NFTFactory;

  constructor(
    address uniV2Factory,
    address feeApprover,
    address RAMVault,
    address nftFactory,
    address payable _regenerator,
    address __storage,
    address linkAddr,
    address vrfAddr
  )
    public
    VRFConsumerBase(
      vrfAddr,
      linkAddr
    )
  {
    __Ownable_init();
    _uniV2Factory = uniV2Factory;
    _feeApprover = IFeeApprover(feeApprover);
    _RAMVault = IRAMVault(RAMVault);
    _NFTFactory = INFTFactory(nftFactory);
    _storage = YGYStorageV1(__storage);

    regenerator = _regenerator;
    keyHash = 0xAA77729D3466CA35AE8D28B3BBAC7CC36A5031EFDC430821C02BC31A238AF445;
    rngLinkFee = 2 * 10**18;
    regeneratorTax = 1;
  }

  function setTokens() external onlyOwner {
    _YGYRAMPair = _storage._YGYRAMPair();
    _YGYToken = _storage._YGYToken();
    _YGYWETHPair = _storage._YGYWETHPair();
    _RAMToken = _storage._RAMToken();
    _WETH = IWETH(_storage._WETH());
    _dXIOTToken = IERC20(_storage._dXIOTToken());
    refreshApproval();
  }

  function setGovernance(address _governance) public {
    require(!governanceSet, "Governance contract has already been set");
    governanceSet = true;
    governance = _governance;
  }

  function setRegenerator(address payable _regeneratoraddr) external onlyOwner {
    regenerator = _regeneratoraddr;
  }

  function setRegeneratorTax(uint256 _regeneratorTax) public {
    require(msg.sender == governance, "Locked to governance");
    regeneratorTax = _regeneratorTax;
  }

  function refreshApproval() public {
    IUniswapV2Pair(_YGYRAMPair).approve(address(_RAMVault), uint256(-1));
  }

  event FeeApproverChanged(address indexed newAddress, address indexed oldAddress);

  fallback() external payable {
    if (msg.sender != address(_WETH)) {
      addLiquidityETHOnly(msg.sender, false);
    }
  }

  // Markets buys YGY with 100% of the ETH deposited, then calls _swapYGYForRAMAndAddLiquidity
  function addLiquidityETHOnly(address payable to, bool autoStake) public payable {
    require(to != address(0), "Invalid address");

    uint256 buyAmount = msg.value;
    require(buyAmount > 0, "Insufficient ETH amount");
    _WETH.deposit{ value: msg.value }();

    (uint256 reserveWeth, uint256 reserveYGY) = getYGYWETHPairReserves();
    uint256 outYGY = UniswapV2Library.getAmountOut(buyAmount, reserveWeth, reserveYGY);

    _WETH.transfer(_YGYWETHPair, buyAmount);

    _storage.setLiquidityContributedEthValue(to, buyAmount, false);

    (address token0, address token1) = UniswapV2Library.sortTokens(address(_WETH), _YGYToken);
    IUniswapV2Pair(_YGYWETHPair).swap(_YGYToken == token0 ? outYGY : 0, _YGYToken == token1 ? outYGY : 0, address(this), "");

    // Calculate tax and send directly to regenerator
    _swapYGYForRAMAndAddLiquidity(outYGY.div(2), to, autoStake);
  }

  // addLiquidityYGYOnly transfers approved YGY tokens to the contract and calls _swapYGYForRAMAndAddLiquidity
  function addLiquidityYGYOnly(uint256 amount, bool autoStake) public payable {
    require(amount > 0, "Insufficient token amount");
    require(IERC20(_YGYToken).transferFrom(msg.sender, address(this), amount), "Approve tokens first");

    // Calculate value of YGY in ETH for liquidity value tracking
    (uint256 reserveWeth, uint256 reserveYGY) = getYGYWETHPairReserves();
    uint256 outETH = UniswapV2Library.getAmountOut(amount, reserveYGY, reserveWeth);

    // Calculate tax and send directly to regenerator
    uint256 taxedAmount = amount.mul(regeneratorTax).div(100);

    _storage.setLiquidityContributedEthValue(msg.sender, outETH, false);

    uint256 outAmount = amount.sub(taxedAmount);
    _swapYGYForRAMAndAddLiquidity(outAmount.div(2), msg.sender, autoStake);
  }

  // With buyAmount*2 amount of YGY tokens on the contract, this function market buys RAM with buyAmount
  // of YGY and then calls _addLiquidity
  function _swapYGYForRAMAndAddLiquidity(
    uint256 buyAmount,
    address payable to,
    bool autoStake
  ) internal {
    (uint256 reserveYGY, uint256 reserveRAM) = getYGYRAMPairReserves();
    uint256 outRAM = UniswapV2Library.getAmountOut(buyAmount, reserveYGY, reserveRAM);

    require(IERC20(_YGYToken).transfer(_YGYRAMPair, buyAmount), "Transfer failed");

    (address token0, address token1) = UniswapV2Library.sortTokens(_YGYToken, _RAMToken);

    IUniswapV2Pair(_YGYRAMPair).swap(_RAMToken == token0 ? outRAM : 0, _RAMToken == token1 ? outRAM : 0, address(this), "");

    uint256 taxedAmount = outRAM.mul(regeneratorTax).div(100);
    IERC20(_RAMToken).transfer(regenerator, taxedAmount);

    _addLiquidity(outRAM.sub(taxedAmount), buyAmount, to, autoStake);
    generateLotteryTickets(to);
    sync();
  }

  // _addLiquidity sends RAM, YGY tokens to the _YGYRAMPair contract and mints _YGYRAMPair LP tokens.
  // It either auto stakes the LP tokens to the pool or sends them to the sender's address
  function _addLiquidity(
    uint256 RAMAmount,
    uint256 YGYAmount,
    address payable to,
    bool autoStake
  ) internal {
    (uint256 YGYReserve, uint256 RAMReserve) = getYGYRAMPairReserves();

    uint256 optimalRAMAmount = UniswapV2Library.quote(YGYAmount, YGYReserve, RAMReserve);

    uint256 optimalYGYAmount;
    if (optimalRAMAmount > RAMAmount) {
      optimalYGYAmount = UniswapV2Library.quote(RAMAmount, RAMReserve, YGYReserve);
      optimalRAMAmount = RAMAmount;
    } else optimalYGYAmount = YGYAmount;

    assert(IERC20(_YGYToken).transfer(_YGYRAMPair, optimalYGYAmount));
    assert(IERC20(_RAMToken).transfer(_YGYRAMPair, optimalRAMAmount));

    if (autoStake) {
      IUniswapV2Pair(_YGYRAMPair).mint(address(this));
      _RAMVault.depositFor(to, 0, IUniswapV2Pair(_YGYRAMPair).balanceOf(address(this)));
    } else IUniswapV2Pair(_YGYRAMPair).mint(to);

    // Refund dust to sender
    if (RAMAmount > optimalRAMAmount) IERC20(_RAMToken).transfer(to, RAMAmount.sub(optimalRAMAmount));

    if (YGYAmount > optimalYGYAmount) IERC20(_YGYToken).transfer(to, YGYAmount.sub(optimalYGYAmount));
  }

  function getLPTokenPerYGYUnit(uint256 ygyAmt) public view returns (uint256 liquidity) {
    (uint256 reserveYGY, uint256 reserveRAM) = getYGYRAMPairReserves();
    uint256 outRAM = UniswapV2Library.getAmountOut(ygyAmt.div(2), reserveYGY, reserveRAM);
    uint256 _totalSupply = IUniswapV2Pair(_YGYRAMPair).totalSupply();

    (address token0, ) = UniswapV2Library.sortTokens(_YGYToken, _RAMToken);
    (uint256 amount0, uint256 amount1) = token0 == _RAMToken ? (outRAM, ygyAmt.div(2)) : (ygyAmt.div(2), outRAM);
    (uint256 _reserve0, uint256 _reserve1) = token0 == _RAMToken ? (reserveRAM, reserveYGY) : (reserveYGY, reserveRAM);
    liquidity = Math.min(amount0.mul(_totalSupply) / _reserve0, amount1.mul(_totalSupply) / _reserve1);
  }

  function getYGYWETHPairReserves() internal view returns (uint256 wethReserves, uint256 YGYReserves) {
    (address token0, ) = UniswapV2Library.sortTokens(address(_WETH), _YGYToken);
    (uint256 reserve0, uint256 reserve1, ) = IUniswapV2Pair(_YGYWETHPair).getReserves();
    (wethReserves, YGYReserves) = token0 == _YGYToken ? (reserve1, reserve0) : (reserve0, reserve1);
  }

  function getYGYRAMPairReserves() internal view returns (uint256 YGYReserves, uint256 RAMReserves) {
    (address token0, ) = UniswapV2Library.sortTokens(_YGYToken, _RAMToken);
    (uint256 reserve0, uint256 reserve1, ) = IUniswapV2Pair(_YGYRAMPair).getReserves();
    (YGYReserves, RAMReserves) = token0 == _RAMToken ? (reserve1, reserve0) : (reserve0, reserve1);
  }

  // Function sync fee approver
  function sync() public {
    _feeApprover.sync();
  }

  // sets fee approver in case fee approver gets chaned.
  function setFeeApprover(address feeApproverAddress) public onlyOwner {
    _feeApprover = IFeeApprover(feeApproverAddress);
  }

  function changeFeeApprover(address feeApprover) external onlyOwner {
    address oldAddress = address(_feeApprover);
    _feeApprover = IFeeApprover(feeApprover);

    emit FeeApproverChanged(feeApprover, oldAddress);
  }

  // -------------------------------------------------
  //              NFT Lottery + Chainlink RNG
  // -------------------------------------------------

  /**
   * Requests randomness from a user-provided seed
   */
  function getRandomNumber(uint256 userProvidedSeed) public returns (bytes32 requestId) {
    require(LINK.balanceOf(address(this)) >= rngLinkFee, "Not enough LINK on contract");
    return requestRandomness(keyHash, rngLinkFee, userProvidedSeed);
  }

  // Bookkeep the NFT claims
  mapping(address => uint256) public linkNFTsToBeClaimed;
  mapping(address => uint256) public robotNFTsToBeClaimed;

  /**
   * Requests randomness from a user-provided seed
   */
  function selfRequestRandomNumber(uint256 userProvidedSeed) public returns (bytes32 requestId) {
    require(LINK.transferFrom(msg.sender, address(this), rngLinkFee), "Not enough LINK approved to contract");
    linkNFTsToBeClaimed[msg.sender] = linkNFTsToBeClaimed[msg.sender].add(1);
    return requestRandomness(keyHash, rngLinkFee, userProvidedSeed);
  }

  /**
   * Callback function used by VRF Coordinator
   */
  function fulfillRandomness(bytes32 requestId, uint256 randomness) internal override {
    uint256 randomResult = rand(randomness);
    lotteryResults[lotteryRoundCounter] = randomResult;
    lotteryRoundCounter = lotteryRoundCounter.add(1);
  }

  function claimLink() external {
    require(linkNFTsToBeClaimed[msg.sender] > 0, "No link provided");
    INFT LinkNFT = INFT(_storage._NFTs(7));
    // Mint a LINK NFT to caller
    _NFTFactory.mint(LinkNFT, msg.sender, lotteryResults[lotteryRoundCounter]);
    linkNFTsToBeClaimed[msg.sender] = linkNFTsToBeClaimed[msg.sender].sub(1);
  }

  function claimRobot() external {
    require(robotNFTsToBeClaimed[msg.sender] > 0, "No ROBOTs for user available");
    INFT RobotNFT = INFT(_storage._NFTs(6));

    // Mint a ROBOT NFT to user.
    if (RobotNFT.totalSupply() < 50) {
      _NFTFactory.mint(RobotNFT, msg.sender, lotteryResults[lotteryRoundCounter]);
      robotNFTsToBeClaimed[msg.sender] = robotNFTsToBeClaimed[msg.sender].sub(1);
    }
  }

  function rand(uint256 randomness) private pure returns (uint256 result) {
    uint256 factor = (randomness * 100) / 100;
    return factor % 100;
  }

  function claimTickets() public {
    require(userTicketCount[msg.sender] > 0, "No tickets to claim");
    applyRandomNumberToTickets(msg.sender);
  }

  function claimTicketsForAddr(address user) public {
    require(userTicketCount[user] > 0, "No tickets to claim");
    applyRandomNumberToTickets(user);
  }

  function applyRandomNumberToTickets(address user) internal {
    uint256 topStackMem = userTopTicketStack[user];
    uint256 ticketCountMem = userTicketCount[user];
    for (uint256 i = topStackMem; i < topStackMem.add(ticketCountMem); i++) {
      LotteryTicket memory ticket = userTickets[user][i];
      uint256 ticketRoundNumber = ticket.roundNumber;

      // Can't process active tickets, we need a round result first
      if (lotteryRoundCounter == ticketRoundNumber) {
        return;
      }

      uint256 roundResult = lotteryResults[ticketRoundNumber];
      if (roundResult <= ticket.levelOneChance) {
        _NFTFactory.mint(INFT(_storage._NFTs(1)), ticket.owner, roundResult);
      }
      if (roundResult <= ticket.levelTwoChance) {
        _NFTFactory.mint(INFT(_storage._NFTs(2)), ticket.owner, roundResult);
      }
      if (roundResult <= ticket.levelThreeChance) {
        _NFTFactory.mint(INFT(_storage._NFTs(3)), ticket.owner, roundResult);
      }
      if (roundResult <= ticket.levelFourChance) {
        _NFTFactory.mint(INFT(_storage._NFTs(4)), ticket.owner, roundResult);
      }
      if (roundResult <= ticket.levelFiveChance) {
        _NFTFactory.mint(INFT(_storage._NFTs(5)), ticket.owner, roundResult);
      }
      // Increment top of user's ticket stack
      topStackMem = topStackMem.add(1);
      userTopTicketStack[user] = topStackMem;

      // Decrement size of user's ticket stack
      ticketCountMem = ticketCountMem.sub(1);
      userTicketCount[user] = ticketCountMem;

      // Delete ticket
      delete userTickets[user][i];
    }
  }

  function getUserLotteryLevel(address user) public view returns (uint256) {
    uint256 liquidityEthValue = _storage.liquidityContributedEthValue(user);
    if (liquidityEthValue < 1e18) {
      return 0;
    } else if (liquidityEthValue >= 1e18 && liquidityEthValue < 5e18) {
      return 1;
    } else if (liquidityEthValue >= 5e18 && liquidityEthValue < 10e18) {
      return 2;
    } else if (liquidityEthValue >= 10e18 && liquidityEthValue < 20e18) {
      return 3;
    } else if (liquidityEthValue >= 20e18 && liquidityEthValue < 30e18) {
      return 4;
    } else if (liquidityEthValue >= 30e18 && liquidityEthValue < 40e18) {
      return 5;
    } else if (liquidityEthValue >= 40e18 && liquidityEthValue < 50e18) {
      return 6;
    } else if (liquidityEthValue >= 50e18) {
      return 7;
    }
  }

  // Generates lottery tickets for users based on their current level and new level
  function generateLotteryTickets(address user) internal {
    uint256 currentLevel = _storage.lastTicketLevel(user);
    uint256 newLevel = getUserLotteryLevel(user);
    uint256 endStack = userTopTicketStack[user];
    for (uint256 i = currentLevel; i < newLevel; i++) {
      LotteryTicket memory ticket;
      if (i == 0) {
        ticket = LotteryTicket({
          owner: user,
          roundNumber: lotteryRoundCounter,
          levelOneChance: 50,
          levelTwoChance: 0,
          levelThreeChance: 0,
          levelFourChance: 0,
          levelFiveChance: 0
        });
      } else if (i == 1) {
        ticket = LotteryTicket({
          owner: user,
          roundNumber: lotteryRoundCounter,
          levelOneChance: 75,
          levelTwoChance: 50,
          levelThreeChance: 0,
          levelFourChance: 0,
          levelFiveChance: 0
        });
      } else if (i == 2) {
        ticket = LotteryTicket({
          owner: user,
          roundNumber: lotteryRoundCounter,
          levelOneChance: 100,
          levelTwoChance: 75,
          levelThreeChance: 50,
          levelFourChance: 0,
          levelFiveChance: 0
        });
      } else if (i == 3) {
        ticket = LotteryTicket({
          owner: user,
          roundNumber: lotteryRoundCounter,
          levelOneChance: 100,
          levelTwoChance: 100,
          levelThreeChance: 75,
          levelFourChance: 50,
          levelFiveChance: 0
        });
      } else if (i == 4) {
        ticket = LotteryTicket({
          owner: user,
          roundNumber: lotteryRoundCounter,
          levelOneChance: 100,
          levelTwoChance: 100,
          levelThreeChance: 100,
          levelFourChance: 75,
          levelFiveChance: 50
        });
        // Level 6 is an automatic winning ticket at every level except level 5, which is 50%
      } else if (i == 5) {
        ticket = LotteryTicket({
          owner: user,
          roundNumber: lotteryRoundCounter,
          levelOneChance: 100,
          levelTwoChance: 100,
          levelThreeChance: 100,
          levelFourChance: 100,
          levelFiveChance: 50
        });
        // Level 7 is a winning ticket for each level + another winning ticket for levels 1-4
      } else if (i == 6) {
        // Winning ticket (levels 1-5)
        uint256 currUserTicketCount = userTicketCount[user];
        uint256 insertAt = endStack.add(currUserTicketCount);
        userTickets[user][insertAt] = LotteryTicket({
          owner: user,
          roundNumber: lotteryRoundCounter,
          levelOneChance: 100,
          levelTwoChance: 100,
          levelThreeChance: 100,
          levelFourChance: 100,
          levelFiveChance: 100
        });
        userTicketCount[user] = currUserTicketCount.add(1);

        // Winning ticket (levels 1-4)
        ticket = LotteryTicket({
          owner: user,
          roundNumber: lotteryRoundCounter,
          levelOneChance: 100,
          levelTwoChance: 100,
          levelThreeChance: 100,
          levelFourChance: 100,
          levelFiveChance: 0
        });
      }

      // Add the ticket to the lottery
      if (ticket.owner != address(0)) {
        uint256 currUserTicketCount = userTicketCount[user];
        uint256 insertAt = endStack.add(currUserTicketCount);
        userTickets[user][insertAt] = ticket;
        userTicketCount[user] = currUserTicketCount.add(1);
      }
    }

    if (newLevel >= 3 && _dXIOTToken.balanceOf(user) >= 20 * 1e18) {
      robotNFTsToBeClaimed[user] = robotNFTsToBeClaimed[user].add(1);
    }
    _storage.setLastTicketLevel(user, newLevel);
  }

  // Chainlink VRF mainnet functionality will change in the future: dynamic pricing
  function updateRngLinkFee(uint256 _rngLinkFee) public onlyOwner {
    rngLinkFee = _rngLinkFee;
  }

  function updateKeyHash(bytes32 _keyHash) public onlyOwner {
    keyHash = _keyHash;
  }
}
