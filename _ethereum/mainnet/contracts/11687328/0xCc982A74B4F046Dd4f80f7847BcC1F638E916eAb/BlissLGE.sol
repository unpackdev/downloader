pragma solidity ^0.6.2;

import "./Ownable.sol";
import "./IERC20.sol";
import "./SafeMath.sol";
import "./Address.sol";
import "./IUniswapV2Router02.sol";
import "./IUniswapV2Factory.sol";
import "./IUniswapV2Pair.sol";


pragma solidity >=0.5.0;

interface INFT {
  function mint(address to) external;
}

interface IWETH {
  function deposit() external payable;

  function transfer(address to, uint256 value) external returns (bool);

  function withdraw(uint256) external;
}

contract BlissLGE is Ownable {
  using SafeMath for uint256;
  using Address for address;

  // Uniswap addresses
  IUniswapV2Factory public uniswapFactory;
  IUniswapV2Router02 public uniswapRouterV2;
  address public tokenUniswapPairETH;
  address public tokenUniswapPairDEFLCT;
  address public tokenUniswapPairVANA;

  // LGE value book-keeping
  mapping(address => uint256) public ethContributedForLPTokens;

  // Bonus token book-keepings
  mapping(address => uint256) public ETHContributedForBonusTokens;
  mapping(address => uint256) public ETHContributedForWhitelistTokens;
  uint256 public bonusTokenPerETHUnit;

  // Distribution amount
  uint256 public ETHLPperETHUnit;
  uint256 public DEFLCTLPperETHUnit;
  uint256 public VANALPperETHUnit;
  uint256 public totalETHContributed;

  // Token mint book-keeping
  uint256 public totalETHLPTokensMinted;
  uint256 public totalDEFLCTLPTokensMinted;
  uint256 public totalVANALPTokensMinted;

  // Event book-keeping
  bool public lgeStarted;
  bool public LPGenerationCompleted;
  uint256 public lgeEndTime;
  uint256 public lpUnlockTime;

  /** TOKEN AMOUNTS, breakdown:
   * 50,000 FOR BLISS/ETH
   * 25,000 FOR BLISS/VANA
   * 25,000 FOR DEF/BLISS
   * 25,000 AS BONUS.
   * = 150,000
   */
  uint256 public basePairInitialLiq = 50000 * 1e18;
  uint256 public sidePairInitialLiq = 25000 * 1e18;
  uint256 public bonusTokens = 25000 * 1e18;
  uint256 public ethUsedForDeflectPair;
  uint256 public ethUsedForVanaPair;

  // Addresses
  address public blissDevAddr;
  address public deflctDevAddr;
  address public DEFLCT;
  address public VANA;
  address public WETH;

  // Tokens
  IERC20 public blissToken;
  IERC20 public vanaToken;

  // NFT bonuses
  INFT public Loyalty;
  INFT public Trust;

  // Whitelist for NFT minting and bonus tokens
  mapping(address => bool) public whitelist;

  event LiquidityAddition(address indexed dst, uint256 value);
  event totalLPTokenClaimed(address dst, uint256 ethLP, uint256 defLP, uint256 vanaLP);
  event TokenClaimed(address dst, uint256 value);
  event LPTokenClaimed(address dst, uint256 value);

  constructor(
    address _blissTokenAddr,
    address _uniswapRouterAddr,
    address _uniswapFactoryAddr,
    address _blissDevAddr,
    address _deflectDevAddr,
    address _deflectTokenAddr,
    address _vanaTokenAddr,
    address _loyaltyAddr,
    address _trustAddr
  ) public {
    uniswapRouterV2 = IUniswapV2Router02(_uniswapRouterAddr);
    uniswapFactory = IUniswapV2Factory(_uniswapFactoryAddr);

    blissToken = IERC20(_blissTokenAddr);
    vanaToken = IERC20(_vanaTokenAddr);

    blissDevAddr = _blissDevAddr;
    deflctDevAddr = _deflectDevAddr;

    DEFLCT = _deflectTokenAddr;
    VANA = _vanaTokenAddr;
    WETH = uniswapRouterV2.WETH();

    Loyalty = INFT(_loyaltyAddr);
    Trust = INFT(_trustAddr);

    lgeEndTime = now.add(5 days);
    lpUnlockTime = now.add(5 days).add(2 hours);
    lgeStarted = true;
  }

  // Liquidity Generation Event
  function createUniswapPairs()
    external
    onlyOwner
    returns (
      address,
      address,
      address
    )
  {
    require(tokenUniswapPairETH == address(0), "BLISS/ETH pair already created");
    tokenUniswapPairETH = uniswapFactory.createPair(address(uniswapRouterV2.WETH()), address(blissToken));

    require(tokenUniswapPairDEFLCT == address(0), "BLISS/DEFLCT pair already created");
    tokenUniswapPairDEFLCT = uniswapFactory.createPair(address(DEFLCT), address(blissToken));

    require(tokenUniswapPairVANA == address(0), "BLISS/VANA pair already created");
    tokenUniswapPairVANA = uniswapFactory.createPair(address(VANA), address(blissToken));

    return (tokenUniswapPairETH, tokenUniswapPairDEFLCT, tokenUniswapPairVANA);
  }

  function addLiquidity() public payable {
    require(now < lgeEndTime && lgeStarted, "Liquidity Generation Event over or not started yet");
    ethContributedForLPTokens[msg.sender] += msg.value; // Overflow protection from safemath is not neded here
    ETHContributedForBonusTokens[msg.sender] = ethContributedForLPTokens[msg.sender];

    // 25% of ETH is used to market purchase DEFLCT
    uint256 ethForBuyingDeflect = msg.value.div(100).mul(25);
    ethUsedForDeflectPair = ethUsedForDeflectPair.add(ethForBuyingDeflect);

    uint256 ethForBuyingVana = msg.value.div(100).mul(25);
    ethUsedForVanaPair = ethUsedForVanaPair.add(ethForBuyingVana);

    uint256 deadline = block.timestamp + 30;
    address[] memory path = new address[](2);
    path[0] = WETH;
    path[1] = DEFLCT;

    require(IERC20(DEFLCT).approve(address(uniswapRouterV2), uint256(-1)), "Approval issue");
    uniswapRouterV2.swapExactETHForTokensSupportingFeeOnTransferTokens{ value: ethForBuyingDeflect }(0, path, address(this), deadline);

    uint256 deadline2 = block.timestamp + 30;
    address[] memory path2 = new address[](2);
    path2[0] = WETH;
    path2[1] = VANA;

    require(IERC20(VANA).approve(address(uniswapRouterV2), uint256(-1)), "Approval issue");
    uniswapRouterV2.swapExactETHForTokensSupportingFeeOnTransferTokens{ value: ethForBuyingVana }(0, path2, address(this), deadline2);

    totalETHContributed = totalETHContributed.add(msg.value);
    emit LiquidityAddition(msg.sender, msg.value);
  }

  function addLiquidityETHToUniswapPair() internal {
    require(now >= lgeEndTime, "Liquidity generation ongoing");
    require(LPGenerationCompleted == false, "Liquidity generation already finished");
    if (_msgSender() != owner()) {
      require(now > (lgeEndTime + 2 hours), "Please wait for dev grace period");
    }

    uint256 blissDevETHFee = totalETHContributed.div(100).mul(5);
    uint256 deflctDevETHFee = totalETHContributed.div(100).mul(5);
    uint256 ETHRemaining = address(this).balance.sub(blissDevETHFee).sub(deflctDevETHFee);

    IWETH(WETH).deposit{ value: ETHRemaining }();

    // Transfer the team fees here.
    (bool blissDevETHTransferSuccess, ) = blissDevAddr.call{ value: blissDevETHFee }("");
    (bool deflectDevETHTransferSuccess, ) = deflctDevAddr.call{ value: deflctDevETHFee }("");
    require(blissDevETHTransferSuccess && deflectDevETHTransferSuccess, "Dev eth transfer failed");

    IUniswapV2Pair blissETHPair = IUniswapV2Pair(tokenUniswapPairETH);

    // Transfer remaining eth liquidity to the pair
    IWETH(WETH).transfer(address(blissETHPair), ETHRemaining);
    // Transfer the bliss liquidity to the pair
    blissToken.transfer(address(blissETHPair), basePairInitialLiq);

    // Mint tokens here.
    blissETHPair.mint(address(this));

    // Book-keep the total
    totalETHLPTokensMinted = blissETHPair.balanceOf(address(this));
    require(totalETHLPTokensMinted != 0, "LP creation failed");

    // For user distribution
    ETHLPperETHUnit = totalETHLPTokensMinted.mul(1e18).div(totalETHContributed);
    require(ETHLPperETHUnit != 0, "LP creation failed");
  }

  function addLiquidityToDEFLCTUniswapPair() internal {
    require(now >= lgeEndTime, "Liquidity generation ongoing");
    require(LPGenerationCompleted == false, "Liquidity generation already finished");

    IUniswapV2Pair DEF_BLISS_PAIR = IUniswapV2Pair(tokenUniswapPairDEFLCT);

    // Create BLISS/DEFLCT LP

    // Send deflect tokens to pair
    IERC20(DEFLCT).transfer(address(DEF_BLISS_PAIR), IERC20(DEFLCT).balanceOf(address(this)));

    // Send bliss tokens to pair
    blissToken.transfer(address(DEF_BLISS_PAIR), sidePairInitialLiq);

    // Mint LP's here.
    DEF_BLISS_PAIR.mint(address(this));

    // Book-keep
    totalDEFLCTLPTokensMinted = DEF_BLISS_PAIR.balanceOf(address(this));
    require(totalDEFLCTLPTokensMinted != 0, "DEFLCT LP creation failed");

    // What's being shared per user contributed.
    DEFLCTLPperETHUnit = totalDEFLCTLPTokensMinted.mul(1e18).div(totalETHContributed); // 1e9x for change
    require(DEFLCTLPperETHUnit != 0, "DEFLCT LP creation failed");
  }

  function addLiquidityToVANAUniswapPair() internal {
    //require(now >= lgeEndTime, "Liquidity generation ongoing");
    //require(LPGenerationCompleted == false, "Liquidity generation already finished");

    IUniswapV2Pair VANA_BLISS_PAIR = IUniswapV2Pair(tokenUniswapPairVANA);

    // Create BLISS/VANA LP
    // Send deflect tokens to pair
    IERC20(VANA).transfer(address(VANA_BLISS_PAIR), IERC20(VANA).balanceOf(address(this)));

    // Send bliss tokens to pair
    blissToken.transfer(address(VANA_BLISS_PAIR), sidePairInitialLiq);

    // Mint LP's here.
    VANA_BLISS_PAIR.mint(address(this));

    // Book-keep
    totalVANALPTokensMinted = VANA_BLISS_PAIR.balanceOf(address(this));
    require(totalVANALPTokensMinted != 0, "VANA LP creation failed");

    // What's being shared per user contributed.
    VANALPperETHUnit = totalVANALPTokensMinted.mul(1e18).div(totalETHContributed); // 1e9x for change
    require(VANALPperETHUnit != 0, "VANA LP creation failed");
  }

  function addLiquidityToUniswap() public onlyOwner {
    addLiquidityETHToUniswapPair();
    addLiquidityToDEFLCTUniswapPair();
    addLiquidityToVANAUniswapPair();

    // Bonus tokens being distributed per wei.
    bonusTokenPerETHUnit = bonusTokens.mul(1e18).div(totalETHContributed);

    require(bonusTokenPerETHUnit != 0, "Token calculation failed");

    LPGenerationCompleted = true;
  }

  function claimLPTokens() public {
    require(now >= lpUnlockTime, "LP not unlocked yet");
    require(LPGenerationCompleted, "Event not over yet");
    require(ethContributedForLPTokens[msg.sender] > 0, "Nothing to claim, move along");

    IUniswapV2Pair ethpair = IUniswapV2Pair(tokenUniswapPairETH);
    uint256 amountETHLPToTransfer = ethContributedForLPTokens[msg.sender].mul(ETHLPperETHUnit).div(1e18);
    ethpair.transfer(msg.sender, amountETHLPToTransfer); // stored as 1e18x value for change

    IUniswapV2Pair defpair = IUniswapV2Pair(tokenUniswapPairDEFLCT);
    uint256 amountDEFLCTLPToTransfer = ethContributedForLPTokens[msg.sender].mul(DEFLCTLPperETHUnit).div(1e18);
    defpair.transfer(msg.sender, amountDEFLCTLPToTransfer); // stored as 1e18x value for change

    IUniswapV2Pair vanapair = IUniswapV2Pair(tokenUniswapPairVANA);
    uint256 amountVANALPToTransfer = ethContributedForLPTokens[msg.sender].mul(VANALPperETHUnit).div(1e18);
    vanapair.transfer(msg.sender, amountVANALPToTransfer); // stored as 1e18x value for change

    ethContributedForLPTokens[msg.sender] = 0;
    emit totalLPTokenClaimed(msg.sender, amountETHLPToTransfer, amountDEFLCTLPToTransfer, amountVANALPToTransfer);
  }

  /**
   * @dev Adds multiple addresses for whitelist
   * @param _addresses array of address is the addresses to be compensated
   */
  function addWhitelistAddresses(address[] memory _addresses) external onlyOwner {
    for (uint8 i; i < _addresses.length; i++) {
      whitelist[_addresses[i]] = true;
    }
  }

  // Rescue any missent tokens to the contract
  function recoverERC20(address tokenAddress, uint256 tokenAmount) external onlyOwner {
    require(lgeEndTime.add(1 days) < now, "Liquidity generation grace period still ongoing");
    IERC20(tokenAddress).transfer(owner(), tokenAmount);
  }

  function claimTokens() public {
    require(now >= lpUnlockTime, "LP not unlocked yet");
    require(LPGenerationCompleted, "Event not over yet");
    require(ETHContributedForBonusTokens[msg.sender] > 0, "Nothing to claim, move along");
    uint256 amountTokenToTransfer = ETHContributedForBonusTokens[msg.sender].mul(bonusTokenPerETHUnit).div(1e18);

    bool mintNFT = ETHContributedForBonusTokens[msg.sender] >= 2 * 1e18;
    bool isWhitelisted = whitelist[msg.sender];
    ETHContributedForBonusTokens[msg.sender] = 0;

    // Mint the user NFT 1 incase deposits amount to more than 2ETH
    // if user is in the compensation whitelist as well mint NFT 2.
    if (mintNFT) {
      if (isWhitelisted) {
        Trust.mint(msg.sender);
      } else {
        Loyalty.mint(msg.sender);
      }
    }

    blissToken.transfer(msg.sender, amountTokenToTransfer); // stored as 1e18x value for change
    emit TokenClaimed(msg.sender, amountTokenToTransfer);
  }

  function emergencyRecoveryIfLiquidityGenerationEventFails() public onlyOwner {
    require(lgeEndTime.add(1 days) < now, "Liquidity generation grace period still ongoing");
    (bool success, ) = msg.sender.call{ value: address(this).balance }("");
    IERC20(VANA).transfer(msg.sender, IERC20(VANA).balanceOf(address(this)));
    IERC20(DEFLCT).transfer(msg.sender, IERC20(DEFLCT).balanceOf(address(this)));
    require(success, "Transfer failed.");
  }

  function setBlissDev(address _blissDevAddr) public {
    require(_msgSender() == blissDevAddr, "!bliss dev");
    blissDevAddr = _blissDevAddr;
  }

  function setDeflctDev(address _deflctDevAddr) public {
    require(_msgSender() == deflctDevAddr, "!deflect dev");
    deflctDevAddr = _deflctDevAddr;
  }
}
