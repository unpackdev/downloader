// SPDX-License-Identifier: MIT

// SpacePort v.1

pragma solidity 0.6.12;

import "./TransferHelper.sol";
import "./EnumerableSet.sol";
import "./SafeMath.sol";
import "./ReentrancyGuard.sol";
import "./IERC20.sol";

interface IPlasmaswapFactory {
    function getPair(address tokenA, address tokenB) external view returns (address pair);
    function createPair(address tokenA, address tokenB) external returns (address pair);
}

interface ISpaceportLockForwarder {
    function lockLiquidity (IERC20 _baseToken, IERC20 _saleToken, uint256 _baseAmount, uint256 _saleAmount, uint256 _unlock_date, address payable _withdrawer) external;
    function plasmaswapPairIsInitialised (address _token0, address _token1) external view returns (bool);
}

interface IWETH {
    function deposit() external payable;
    function transfer(address to, uint value) external returns (bool);
    function withdraw(uint) external;
}

interface ISpaceportSettings {
    function getMaxSpaceportLength () external view returns (uint256);
    function getRound1Length () external view returns (uint256);
    function userHoldsSufficientRound1Token (address _user) external view returns (bool);
    function getBaseFee () external view returns (uint256);
    function getTokenFee () external view returns (uint256);
    function getEthAddress () external view returns (address payable);
    function getTokenAddress () external view returns (address payable);
    function getEthCreationFee () external view returns (uint256);
}

contract Spaceportv1 is ReentrancyGuard {
  using SafeMath for uint256;
  using EnumerableSet for EnumerableSet.AddressSet;
  
  event spaceportUserDeposit(uint256 value);
  event spaceportUserWithdrawTokens(uint256 value);
  event spaceportUserWithdrawBaseTokens(uint256 value);
  event spaceportOwnerWithdrawTokens();
  event spaceportAddLiquidity();
  event spaceportForceFailIfPairExists();
  event spaceportForceFailByPlfi();
  event spaceportUpdateBlocks(uint256 start, uint256 end);

  /// @notice Spaceport Contract Version, used to choose the correct ABI to decode the contract
  uint256 public CONTRACT_VERSION = 1;
  
  struct SpaceportInfo {
    address payable SPACEPORT_OWNER;
    IERC20 S_TOKEN; // sale token
    IERC20 B_TOKEN; // base token // usually WETH (ETH)
    uint256 TOKEN_PRICE; // 1 base token = ? s_tokens, fixed price
    uint256 MAX_SPEND_PER_BUYER; // maximum base token BUY amount per account
    uint256 AMOUNT; // the amount of spaceport tokens up for presale
    uint256 HARDCAP;
    uint256 SOFTCAP;
    uint256 LIQUIDITY_PERCENT; // divided by 1000 - to be locked !
    uint256 LISTING_RATE; // fixed rate at which the token will list on plasmaswap - start rate
    uint256 START_BLOCK;
    uint256 END_BLOCK;
    uint256 LOCK_PERIOD; // unix timestamp -> e.g. 2 weeks
    bool SPACEPORT_IN_ETH; // if this flag is true the Spaceport is raising ETH, otherwise an ERC20 token such as DAI
  }

  struct SpaceportVesting {
    uint256 vestingCliff;
    uint256 vestingEnd;
  }

  struct SpaceportFeeInfo {
    uint256 PLFI_BASE_FEE; // divided by 1000
    uint256 PLFI_TOKEN_FEE; // divided by 1000
    address payable BASE_FEE_ADDRESS;
    address payable TOKEN_FEE_ADDRESS;
  }
  
  struct SpaceportStatus {
    bool WHITELIST_ONLY; // if set to true only whitelisted members may participate
    bool LP_GENERATION_COMPLETE; // final flag required to end a Spaceport and enable withdrawls
    bool FORCE_FAILED; // set this flag to force fail the Spaceport
    uint256 TOTAL_BASE_COLLECTED; // total base currency raised (usually ETH)
    uint256 TOTAL_TOKENS_SOLD; // total Spaceport tokens sold
    uint256 TOTAL_TOKENS_WITHDRAWN; // total tokens withdrawn post successful Spaceport
    uint256 TOTAL_BASE_WITHDRAWN; // total base tokens withdrawn on Spaceport failure
    uint256 ROUND1_LENGTH; // in blocks
    uint256 NUM_BUYERS; // number of unique participants
    uint256 LP_GENERATION_COMPLETE_TIME;  //  the date when LP is done
  }

  struct BuyerInfo {
    uint256 baseDeposited; // total base token (usually ETH) deposited by user, can be withdrawn on presale failure
    uint256 tokensOwed; // num Spaceport tokens a user is owed, can be withdrawn on presale success
    uint256 tokensClaimed;
    uint256 lastUpdate;
  }
  
  SpaceportVesting public SPACEPORT_VESTING;
  SpaceportInfo public SPACEPORT_INFO;
  SpaceportFeeInfo public SPACEPORT_FEE_INFO;
  SpaceportStatus public STATUS;
  address public SPACEPORT_GENERATOR;
  ISpaceportLockForwarder public SPACEPORT_LOCK_FORWARDER;
  ISpaceportSettings public SPACEPORT_SETTINGS;
  address PLFI_DEV_ADDRESS;
  IPlasmaswapFactory public PLASMASWAP_FACTORY;
  IWETH public WETH;
  mapping(address => BuyerInfo) public BUYERS;
  EnumerableSet.AddressSet private WHITELIST;

  constructor(address _spaceportGenerator) public {
    SPACEPORT_GENERATOR = _spaceportGenerator;
    PLASMASWAP_FACTORY = IPlasmaswapFactory(0xd87Ad19db2c4cCbf897106dE034D52e3DD90ea60);
    WETH = IWETH(0xC02aaA39b223FE8D0A0e5C4F27eAD9083C756Cc2);
    SPACEPORT_SETTINGS = ISpaceportSettings(0x90De443BDC372f9aA944cF18fb6c82980807Cb0a);
    SPACEPORT_LOCK_FORWARDER = ISpaceportLockForwarder(0x5AD2A6181B1bc6aCAbd7bad268102d68DE54A4eE);
    PLFI_DEV_ADDRESS = 0x37CB8941348f04E783f67E19AD937f48DD7355D9;
  }
  
  function init1 (
    address payable _spaceportOwner, 
    uint256 _amount,
    uint256 _tokenPrice, 
    uint256 _maxEthPerBuyer, 
    uint256 _hardcap, 
    uint256 _softcap,
    uint256 _liquidityPercent,
    uint256 _listingRate,
    uint256 _startblock,
    uint256 _endblock,
    uint256 _lockPeriod
    ) external {
          
      require(msg.sender == SPACEPORT_GENERATOR, 'FORBIDDEN');
      SPACEPORT_INFO.SPACEPORT_OWNER = _spaceportOwner;
      SPACEPORT_INFO.AMOUNT = _amount;
      SPACEPORT_INFO.TOKEN_PRICE = _tokenPrice;
      SPACEPORT_INFO.MAX_SPEND_PER_BUYER = _maxEthPerBuyer;
      SPACEPORT_INFO.HARDCAP = _hardcap;
      SPACEPORT_INFO.SOFTCAP = _softcap;
      SPACEPORT_INFO.LIQUIDITY_PERCENT = _liquidityPercent;
      SPACEPORT_INFO.LISTING_RATE = _listingRate;
      SPACEPORT_INFO.START_BLOCK = _startblock;
      SPACEPORT_INFO.END_BLOCK = _endblock;
      SPACEPORT_INFO.LOCK_PERIOD = _lockPeriod;
  }
  
  function init2 (
    IERC20 _baseToken,
    IERC20 _spaceportToken,
    uint256 _plfiBaseFee,
    uint256 _plfiTokenFee,
    address payable _baseFeeAddress,
    address payable _tokenFeeAddress,
    uint256 _vestingCliff,
    uint256 _vestingEnd
    ) external {
          
      require(msg.sender == SPACEPORT_GENERATOR, 'FORBIDDEN');
      // require(!SPACEPORT_LOCK_FORWARDER.plasmaswapPairIsInitialised(address(_spaceportToken), address(_baseToken)), 'PAIR INITIALISED');
      
      SPACEPORT_INFO.SPACEPORT_IN_ETH = address(_baseToken) == address(WETH);
      SPACEPORT_INFO.S_TOKEN = _spaceportToken;
      SPACEPORT_INFO.B_TOKEN = _baseToken;
      SPACEPORT_FEE_INFO.PLFI_BASE_FEE = _plfiBaseFee;
      SPACEPORT_FEE_INFO.PLFI_TOKEN_FEE = _plfiTokenFee;
      
      SPACEPORT_FEE_INFO.BASE_FEE_ADDRESS = _baseFeeAddress;
      SPACEPORT_FEE_INFO.TOKEN_FEE_ADDRESS = _tokenFeeAddress;
      STATUS.ROUND1_LENGTH = SPACEPORT_SETTINGS.getRound1Length();

      SPACEPORT_VESTING.vestingCliff = _vestingCliff;
      SPACEPORT_VESTING.vestingEnd = _vestingEnd;
  }
  
  modifier onlySpaceportOwner() {
    require(SPACEPORT_INFO.SPACEPORT_OWNER == msg.sender, "NOT SPACEPORT OWNER");
    _;
  }
  
  function spaceportStatus () public view returns (uint256) {
    if (STATUS.FORCE_FAILED) {
      return 3; // FAILED - force fail
    }
    if ((block.number > SPACEPORT_INFO.END_BLOCK) && (STATUS.TOTAL_BASE_COLLECTED < SPACEPORT_INFO.SOFTCAP)) {
      return 3; // FAILED - softcap not met by end block
    }
    if (STATUS.TOTAL_BASE_COLLECTED >= SPACEPORT_INFO.HARDCAP) {
      return 2; // SUCCESS - hardcap met
    }
    if ((block.number > SPACEPORT_INFO.END_BLOCK) && (STATUS.TOTAL_BASE_COLLECTED >= SPACEPORT_INFO.SOFTCAP)) {
      return 2; // SUCCESS - endblock and soft cap reached
    }
    if ((block.number >= SPACEPORT_INFO.START_BLOCK) && (block.number <= SPACEPORT_INFO.END_BLOCK)) {
      return 1; // ACTIVE - deposits enabled
    }
    return 0; // QUED - awaiting start block
  }
  
  // accepts msg.value for eth or _amount for ERC20 tokens
  function userDeposit (uint256 _amount) external payable nonReentrant {
    require(spaceportStatus() == 1, 'NOT ACTIVE'); // ACTIVE
    if (STATUS.WHITELIST_ONLY) {
      require(WHITELIST.contains(msg.sender), 'NOT WHITELISTED');
    }
    // Spaceport Round 1 - require participant to hold a certain token and balance
    if (block.number < SPACEPORT_INFO.START_BLOCK + STATUS.ROUND1_LENGTH) { // 276 blocks = 1 hour
        require(SPACEPORT_SETTINGS.userHoldsSufficientRound1Token(msg.sender), 'INSUFFICENT ROUND 1 TOKEN BALANCE');
    }
    BuyerInfo storage buyer = BUYERS[msg.sender];
    uint256 amount_in = SPACEPORT_INFO.SPACEPORT_IN_ETH ? msg.value : _amount;
    uint256 allowance = SPACEPORT_INFO.MAX_SPEND_PER_BUYER.sub(buyer.baseDeposited);
    uint256 remaining = SPACEPORT_INFO.HARDCAP - STATUS.TOTAL_BASE_COLLECTED;
    allowance = allowance > remaining ? remaining : allowance;
    if (amount_in > allowance) {
      amount_in = allowance;
    }
    uint256 tokensSold = amount_in.mul(SPACEPORT_INFO.TOKEN_PRICE).div(10 ** uint256(SPACEPORT_INFO.B_TOKEN.decimals()));
    require(tokensSold > 0, 'ZERO TOKENS');
    if (buyer.baseDeposited == 0) {
        STATUS.NUM_BUYERS++;
    }

    buyer.baseDeposited = buyer.baseDeposited.add(amount_in);
    buyer.tokensOwed = buyer.tokensOwed.add(tokensSold);
    buyer.lastUpdate = block.timestamp;

    STATUS.TOTAL_BASE_COLLECTED = STATUS.TOTAL_BASE_COLLECTED.add(amount_in);
    STATUS.TOTAL_TOKENS_SOLD = STATUS.TOTAL_TOKENS_SOLD.add(tokensSold);
    
    // return unused ETH
    if (SPACEPORT_INFO.SPACEPORT_IN_ETH && amount_in < msg.value) {
      msg.sender.transfer(msg.value.sub(amount_in));
    }
    // deduct non ETH token from user
    if (!SPACEPORT_INFO.SPACEPORT_IN_ETH) {
      TransferHelper.safeTransferFrom(address(SPACEPORT_INFO.B_TOKEN), msg.sender, address(this), amount_in);
    }
    emit spaceportUserDeposit(amount_in);
  }
  
  // withdraw spaceport tokens
  // percentile withdrawls allows fee on transfer or rebasing tokens to still work
  function userWithdrawTokens () external nonReentrant {
    require(STATUS.LP_GENERATION_COMPLETE, 'AWAITING LP GENERATION');
    BuyerInfo storage buyer = BUYERS[msg.sender];
    require(STATUS.LP_GENERATION_COMPLETE_TIME + SPACEPORT_VESTING.vestingCliff < block.timestamp, "vesting cliff : not time yet");

    if (buyer.lastUpdate < STATUS.LP_GENERATION_COMPLETE_TIME ) {
        buyer.lastUpdate = STATUS.LP_GENERATION_COMPLETE_TIME;
    }
    
    uint256 tokensOwed = 0;
    if(STATUS.LP_GENERATION_COMPLETE_TIME + SPACEPORT_VESTING.vestingEnd < block.timestamp) {
      tokensOwed = buyer.tokensOwed.sub(buyer.tokensClaimed);
    }
    else {
      tokensOwed = buyer.tokensOwed.mul(block.timestamp - buyer.lastUpdate).div(SPACEPORT_VESTING.vestingEnd);
    }

    buyer.lastUpdate = block.timestamp;
    buyer.tokensClaimed = buyer.tokensClaimed.add(tokensOwed);
    
    require(tokensOwed > 0, 'NOTHING TO CLAIM');
    require(buyer.tokensClaimed <= buyer.tokensOwed, 'CLAIM TOKENS ERROR');

    STATUS.TOTAL_TOKENS_WITHDRAWN = STATUS.TOTAL_TOKENS_WITHDRAWN.add(tokensOwed);
    TransferHelper.safeTransfer(address(SPACEPORT_INFO.S_TOKEN), msg.sender, tokensOwed);

    emit spaceportUserWithdrawTokens(tokensOwed);
  }
  
  // on spaceport failure
  // percentile withdrawls allows fee on transfer or rebasing tokens to still work
  function userWithdrawBaseTokens () external nonReentrant {
    require(spaceportStatus() == 3, 'NOT FAILED'); // FAILED
    BuyerInfo storage buyer = BUYERS[msg.sender];
    uint256 baseRemainingDenominator = STATUS.TOTAL_BASE_COLLECTED.sub(STATUS.TOTAL_BASE_WITHDRAWN);
    uint256 remainingBaseBalance = SPACEPORT_INFO.SPACEPORT_IN_ETH ? address(this).balance : SPACEPORT_INFO.B_TOKEN.balanceOf(address(this));
    uint256 tokensOwed = remainingBaseBalance.mul(buyer.baseDeposited).div(baseRemainingDenominator);
    require(tokensOwed > 0, 'NOTHING TO WITHDRAW');
    STATUS.TOTAL_BASE_WITHDRAWN = STATUS.TOTAL_BASE_WITHDRAWN.add(buyer.baseDeposited);
    buyer.baseDeposited = 0;
    TransferHelper.safeTransferBaseToken(address(SPACEPORT_INFO.B_TOKEN), msg.sender, tokensOwed, !SPACEPORT_INFO.SPACEPORT_IN_ETH);
    emit spaceportUserWithdrawBaseTokens(tokensOwed);
  }
  
  // failure
  // allows the owner to withdraw the tokens they sent for presale & initial liquidity
  function ownerWithdrawTokens () external onlySpaceportOwner {
    require(spaceportStatus() == 3); // FAILED
    TransferHelper.safeTransfer(address(SPACEPORT_INFO.S_TOKEN), SPACEPORT_INFO.SPACEPORT_OWNER, SPACEPORT_INFO.S_TOKEN.balanceOf(address(this)));
    emit spaceportOwnerWithdrawTokens();
  }
  

  // Can be called at any stage before or during the presale to cancel it before it ends.
  // If the pair already exists on plasmaswap and it contains the presale token as liquidity 
  // the final stage of the presale 'addLiquidity()' will fail. This function 
  // allows anyone to end the presale prematurely to release funds in such a case.
  function forceFailIfPairExists () external {
    require(!STATUS.LP_GENERATION_COMPLETE && !STATUS.FORCE_FAILED);
    if (SPACEPORT_LOCK_FORWARDER.plasmaswapPairIsInitialised(address(SPACEPORT_INFO.S_TOKEN), address(SPACEPORT_INFO.B_TOKEN))) {
        STATUS.FORCE_FAILED = true;
        emit spaceportForceFailIfPairExists();
    }
  }
  
  // if something goes wrong in LP generation
  function forceFailByPlfi () external {
      require(msg.sender == PLFI_DEV_ADDRESS);
      STATUS.FORCE_FAILED = true;
      emit spaceportForceFailByPlfi();
  }
  
  // on spaceport success, this is the final step to end the spaceport, lock liquidity and enable withdrawls of the sale token.
  // This function does not use percentile distribution. Rebasing mechanisms, fee on transfers, or any deflationary logic
  // are not taken into account at this stage to ensure stated liquidity is locked and the pool is initialised according to 
  // the spaceport parameters and fixed prices.
  function addLiquidity() external nonReentrant {
    require(!STATUS.LP_GENERATION_COMPLETE, 'GENERATION COMPLETE');
    require(spaceportStatus() == 2, 'NOT SUCCESS'); // SUCCESS
    // Fail the spaceport if the pair exists and contains spaceport token liquidity
    if (SPACEPORT_LOCK_FORWARDER.plasmaswapPairIsInitialised(address(SPACEPORT_INFO.S_TOKEN), address(SPACEPORT_INFO.B_TOKEN))) {
        STATUS.FORCE_FAILED = true;
        return;
    }
    
    uint256 plfiBaseFee = STATUS.TOTAL_BASE_COLLECTED.mul(SPACEPORT_FEE_INFO.PLFI_BASE_FEE).div(1000);
    
    // base token liquidity
    uint256 baseLiquidity = STATUS.TOTAL_BASE_COLLECTED.sub(plfiBaseFee).mul(SPACEPORT_INFO.LIQUIDITY_PERCENT).div(1000);
    if (SPACEPORT_INFO.SPACEPORT_IN_ETH) {
        WETH.deposit{value : baseLiquidity}();
    }
    TransferHelper.safeApprove(address(SPACEPORT_INFO.B_TOKEN), address(SPACEPORT_LOCK_FORWARDER), baseLiquidity);
    
    // sale token liquidity
    uint256 tokenLiquidity = baseLiquidity.mul(SPACEPORT_INFO.LISTING_RATE).div(10 ** uint256(SPACEPORT_INFO.B_TOKEN.decimals()));
    TransferHelper.safeApprove(address(SPACEPORT_INFO.S_TOKEN), address(SPACEPORT_LOCK_FORWARDER), tokenLiquidity);
    
    SPACEPORT_LOCK_FORWARDER.lockLiquidity(SPACEPORT_INFO.B_TOKEN, SPACEPORT_INFO.S_TOKEN, baseLiquidity, tokenLiquidity, block.timestamp + SPACEPORT_INFO.LOCK_PERIOD, SPACEPORT_INFO.SPACEPORT_OWNER);
    
    // transfer fees
    uint256 plfiTokenFee = STATUS.TOTAL_TOKENS_SOLD.mul(SPACEPORT_FEE_INFO.PLFI_TOKEN_FEE).div(1000);
    TransferHelper.safeTransferBaseToken(address(SPACEPORT_INFO.B_TOKEN), SPACEPORT_FEE_INFO.BASE_FEE_ADDRESS, plfiBaseFee, !SPACEPORT_INFO.SPACEPORT_IN_ETH);
    TransferHelper.safeTransfer(address(SPACEPORT_INFO.S_TOKEN), SPACEPORT_FEE_INFO.TOKEN_FEE_ADDRESS, plfiTokenFee);
    
    // burn unsold tokens
    uint256 remainingSBalance = SPACEPORT_INFO.S_TOKEN.balanceOf(address(this));
    if (remainingSBalance > STATUS.TOTAL_TOKENS_SOLD) {
        uint256 burnAmount = remainingSBalance.sub(STATUS.TOTAL_TOKENS_SOLD);
        TransferHelper.safeTransfer(address(SPACEPORT_INFO.S_TOKEN), 0x6Ad6fd6282cCe6eBB65Ab8aBCBD1ae5057D4B1DB, burnAmount);
    }
    
    // send remaining base tokens to spaceport owner
    uint256 remainingBaseBalance = SPACEPORT_INFO.SPACEPORT_IN_ETH ? address(this).balance : SPACEPORT_INFO.B_TOKEN.balanceOf(address(this));
    TransferHelper.safeTransferBaseToken(address(SPACEPORT_INFO.B_TOKEN), SPACEPORT_INFO.SPACEPORT_OWNER, remainingBaseBalance, !SPACEPORT_INFO.SPACEPORT_IN_ETH);
    
    STATUS.LP_GENERATION_COMPLETE = true;
    STATUS.LP_GENERATION_COMPLETE_TIME = block.timestamp;
    
    emit spaceportAddLiquidity();
  }
  
  function updateMaxSpendLimit(uint256 _maxSpend) external onlySpaceportOwner {
    SPACEPORT_INFO.MAX_SPEND_PER_BUYER = _maxSpend;
  }
  
  // postpone or bring a spaceport forward, this will only work when a presale is inactive.
  function updateBlocks(uint256 _startBlock, uint256 _endBlock) external onlySpaceportOwner {
    require(SPACEPORT_INFO.START_BLOCK > block.number);
    require(_endBlock.sub(_startBlock) <= SPACEPORT_SETTINGS.getMaxSpaceportLength());
    SPACEPORT_INFO.START_BLOCK = _startBlock;
    SPACEPORT_INFO.END_BLOCK = _endBlock;
    emit spaceportUpdateBlocks(_startBlock, _endBlock);
  }

  // editable at any stage of the presale
  function setWhitelistFlag(bool _flag) external onlySpaceportOwner {
    STATUS.WHITELIST_ONLY = _flag;
  }

  // editable at any stage of the presale
  function editWhitelist(address[] memory _users, bool _add) external onlySpaceportOwner {
    if (_add) {
        for (uint i = 0; i < _users.length; i++) {
          WHITELIST.add(_users[i]);
        }
    } else {
        for (uint i = 0; i < _users.length; i++) {
          WHITELIST.remove(_users[i]);
        }
    }
  }

  // whitelist getters
  function getWhitelistedUsersLength () external view returns (uint256) {
    return WHITELIST.length();
  }
  
  function getWhitelistedUserAtIndex (uint256 _index) external view returns (address) {
    return WHITELIST.at(_index);
  }
  
  function getUserWhitelistStatus (address _user) external view returns (bool) {
    return WHITELIST.contains(_user);
  }
}