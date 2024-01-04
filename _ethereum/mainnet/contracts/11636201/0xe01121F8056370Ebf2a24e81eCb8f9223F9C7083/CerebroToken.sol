//SPDX-License-Identifier: UNLICENSED

pragma solidity ^0.6.2;

import "./Ownable.sol";
import "./SafeMath.sol";
import "./IERC20.sol";
import "./Address.sol";
import "./IWETH.sol";
import "./IUniswapV2Router02.sol";
import "./IUniswapV2Pair.sol";
import "./IUniswapV2Factory.sol";



contract Cerebro is IERC20, OwnableUpgradeSafe {
  using SafeMath for uint256;
  using Address for address;

  mapping(address => uint256) private _rOwned;
  mapping(address => uint256) private _tOwned;
  mapping(address => mapping(address => uint256)) private _allowances;

  mapping(address => bool) private _isExcluded;
  address[] private _excluded;

  uint256 private constant MAX = ~uint256(0);
  uint256 private _tTotal;
  uint256 private _rTotal;
  uint256 private _tFeeTotal;
  uint256 private _tBurnTotal;
  uint256 public lastTotalSupplyOfLPTokens;

  string private constant _name = "Cerebro";
  string private constant _symbol = "CRB";
  uint256 immutable _decimals = 9;

  uint256 private _taxFee;
  uint256 private _burnFee;
  uint256 private _treasuryFee;

  // Liquidity Generation Event
  IUniswapV2Factory public uniswapFactory;
  IUniswapV2Router02 public uniswapRouterV2;

  address public tokenUniswapPairDEFLCTCRB;
  address public tokenUniswapPairDEFLCTYMEN;
  address public tokenUniswapPairYMENCRB;

  mapping(address => uint256) public ethContributedForLPTokens;
  mapping(address => uint256) public DEFLCTcontributedForLPTokens;
  mapping(address => uint256) public YMENcontributedForLPTokens;

  uint256 public ETHLPperETHUnit;

  uint256 public DEFLCTCRBLPperETHUnit;
  uint256 public DEFLCTYMENLPperETHUnit;
  uint256 public YMENCRBLPperETHUnit;

  uint256 public totalETHContributed;
  uint256 public totalDEFLCTContributed;
  uint256 public totalYMENContributed;

  uint256 public DEF_YMEN_TOTAL_LP_TOKENS_MINTED;
  uint256 public DEF_CRB_TOTAL_LP_TOKENS_MINTED;
  uint256 public YMEN_CRB_TOTAL_LP_TOKENS_MINTED;

  address public totalDEFLCTCRBLPTokensMinted;
  address public totalDEFLCTYMENLPTokensMinted;
  address public totalYMENCRBLPTokensMinted;

  bool public paused;
  bool public LPGenerationCompleted;
  uint256 public lgeEndTime;
  uint256 public lpUnlockTime;

  mapping(address => uint256) public ethContributedForTokens;
  uint256 public DEFLCTContributedForTokens;
  uint256 public YMENContributedForTokens;

  uint256 public TotalDEFLCTContributedPersonalPercentage;
  uint256 public TotalYMENContributedPersonalPercentage;

  address public crbTreasury;
  address public DEFLCT;
  address public WETH;
  address public YMEN;

  event LiquidityAddition(address indexed dst, uint256 value);
  event totalLPTokenClaimed(address dst, uint256 ethLP, uint256 defLP);
  event TokenClaimed(address dst, uint256 value);

  event LPTokenClaimed(address dst, uint256 value);

  function initialize(
    address _uniRouter,
    address _uniFactory,
    address _deflectAddr,
    address _ymenAddr,
    address _crbTreasury,
    address _defYmenAddr
  ) external initializer {
    __Ownable_init();

    // Token supplies and dist
    _tTotal = 10 * 10**5 * 10**9;
    _rTotal = (MAX - (MAX % _tTotal));

    // DFLECT DEPLOYER ( 65% )
    _rOwned[_msgSender()] = _rTotal.div(100).mul(65);
    _tOwned[_msgSender()] = _tTotal.div(100).mul(65);
    emit Transfer(address(0), _msgSender(), _tTotal.div(100).mul(65));

    // CRB treausry ( 5% )
    _rOwned[_crbTreasury] = _rTotal.div(100).mul(5);
    _tOwned[_crbTreasury] = _tTotal.div(100).mul(5);
    emit Transfer(address(0), _crbTreasury, _tTotal.div(100).mul(5));

    // LGE ( 30 % )
    _rOwned[address(this)] = _rTotal.div(100).mul(30);
    _tOwned[address(this)] = _tTotal.div(100).mul(30);
    emit Transfer(address(0), address(this), _tTotal.div(100).mul(30));

    // Set fees low - reverted after LGE.
    _taxFee = 1;
    _burnFee = 1;
    _treasuryFee = 1;

    // UNISWAP
    uniswapRouterV2 = IUniswapV2Router02(_uniRouter);
    uniswapFactory = IUniswapV2Factory(_uniFactory);

    // External tokens used in LGE
    DEFLCT = _deflectAddr;
    YMEN = _ymenAddr;
    WETH = uniswapRouterV2.WETH();

    // Duration of a week - dev grace 2 hours.
    lgeEndTime = now.add(7 days);
    lpUnlockTime = now.add(7 days).add(2 hours);

    crbTreasury = _crbTreasury;

    tokenUniswapPairDEFLCTYMEN = _defYmenAddr;

    paused = false;

    excludeAccount(address(this));
  }

  function name() public pure returns (string memory) {
    return _name;
  }

  function symbol() public pure returns (string memory) {
    return _symbol;
  }

  function decimals() public view returns (uint256) {
    return _decimals;
  }

  function totalSupply() public view override returns (uint256) {
    return _tTotal;
  }

  function balanceOf(address account) public view override returns (uint256) {
    if (_isExcluded[account]) return _tOwned[account];
    return tokenFromReflection(_rOwned[account]);
  }

  function transfer(address recipient, uint256 amount) public override returns (bool) {
    _transfer(_msgSender(), recipient, amount);
    return true;
  }

  function allowance(address owner, address spender) public view override returns (uint256) {
    return _allowances[owner][spender];
  }

  function approve(address spender, uint256 amount) public override returns (bool) {
    _approve(_msgSender(), spender, amount);
    return true;
  }

  function transferFrom(
    address sender,
    address recipient,
    uint256 amount
  ) public override returns (bool) {
    _transfer(sender, recipient, amount);
    _approve(sender, _msgSender(), _allowances[sender][_msgSender()].sub(amount, "ERC20: transfer amount exceeds allowance"));
    return true;
  }

  function increaseAllowance(address spender, uint256 addedValue) public virtual returns (bool) {
    _approve(_msgSender(), spender, _allowances[_msgSender()][spender].add(addedValue));
    return true;
  }

  function decreaseAllowance(address spender, uint256 subtractedValue) public virtual returns (bool) {
    _approve(_msgSender(), spender, _allowances[_msgSender()][spender].sub(subtractedValue, "ERC20: decreased allowance below zero"));
    return true;
  }

  function isExcluded(address account) public view returns (bool) {
    return _isExcluded[account];
  }

  function totalFees() public view returns (uint256) {
    return _tFeeTotal;
  }

  function totalBurn() public view returns (uint256) {
    return _tBurnTotal;
  }

  function reflectionFromToken(uint256 tAmount, bool deductTransferFee) public view returns (uint256) {
    require(tAmount <= _tTotal, "Amount must be less than supply");
    if (!deductTransferFee) {
      (uint256 rAmount, , , , , ) = _getValues(tAmount);
      return rAmount;
    } else {
      (, uint256 rTransferAmount, , , , ) = _getValues(tAmount);
      return rTransferAmount;
    }
  }

  function tokenFromReflection(uint256 rAmount) public view returns (uint256) {
    require(rAmount <= _rTotal, "Amount must be less than total reflections");
    uint256 currentRate = _getRate();
    return rAmount.div(currentRate);
  }

  function excludeAccount(address account) public onlyOwner() {
    require(account != address(uniswapRouterV2), "We can not exclude Uniswap router.");
    require(!_isExcluded[account], "Account is already excluded");
    if (_rOwned[account] > 0) {
      _tOwned[account] = tokenFromReflection(_rOwned[account]);
    }
    _isExcluded[account] = true;
    _excluded.push(account);
  }

  function includeAccount(address account) external onlyOwner() {
    require(_isExcluded[account], "Account is already included");
    for (uint256 i = 0; i < _excluded.length; i++) {
      if (_excluded[i] == account) {
        _excluded[i] = _excluded[_excluded.length - 1];
        _tOwned[account] = 0;
        _isExcluded[account] = false;
        _excluded.pop();
        break;
      }
    }
  }

  function _approve(
    address owner,
    address spender,
    uint256 amount
  ) private {
    require(owner != address(0), "ERC20: approve from the zero address");
    require(spender != address(0), "ERC20: approve to the zero address");
    uint256 oldAllowance = _allowances[owner][spender];
    if (oldAllowance > 0) _allowances[owner][spender] = 0;

    _allowances[owner][spender] = amount;
    emit Approval(owner, spender, amount);
  }

  function _transfer(
    address sender,
    address recipient,
    uint256 amount
  ) private {
    require(sender != address(0), "ERC20: transfer from the zero address");
    require(recipient != address(0), "ERC20: transfer to the zero address");
    require(amount > 0, "Transfer amount must be greater than zero");

    if (sender != address(this)) {
      require(!paused, "Transfers are paused");
    }

    if (_isExcluded[sender] && !_isExcluded[recipient]) {
      _transferFromExcluded(sender, recipient, amount);
    } else if (!_isExcluded[sender] && _isExcluded[recipient]) {
      _transferToExcluded(sender, recipient, amount);
    } else if (!_isExcluded[sender] && !_isExcluded[recipient]) {
      _transferStandard(sender, recipient, amount);
    } else {
      _transferBothExcluded(sender, recipient, amount);
    }
  }

  function _transferStandard(
    address sender,
    address recipient,
    uint256 tAmount
  ) private {
    uint256 currentRate = _getRate();
    (uint256 rAmount, uint256 rTransferAmount, uint256 rFee, uint256 tTransferAmount, uint256 tFee, uint256 tBurn) = _getValues(tAmount);
    uint256 rBurn = tBurn.mul(currentRate);
    _rOwned[sender] = _rOwned[sender].sub(rAmount);
    _rOwned[recipient] = _rOwned[recipient].add(rTransferAmount);
    _reflectFee(rFee, rBurn, tFee, tBurn);
    emit Transfer(sender, recipient, tTransferAmount);
  }

  function _transferToExcluded(
    address sender,
    address recipient,
    uint256 tAmount
  ) private {
    uint256 currentRate = _getRate();
    (uint256 rAmount, uint256 rTransferAmount, uint256 rFee, uint256 tTransferAmount, uint256 tFee, uint256 tBurn) = _getValues(tAmount);
    uint256 rBurn = tBurn.mul(currentRate);
    _rOwned[sender] = _rOwned[sender].sub(rAmount);
    _tOwned[recipient] = _tOwned[recipient].add(tTransferAmount);
    _rOwned[recipient] = _rOwned[recipient].add(rTransferAmount);
    _reflectFee(rFee, rBurn, tFee, tBurn);
    emit Transfer(sender, recipient, tTransferAmount);
  }

  function _transferFromExcluded(
    address sender,
    address recipient,
    uint256 tAmount
  ) private {
    uint256 currentRate = _getRate();
    (uint256 rAmount, uint256 rTransferAmount, uint256 rFee, uint256 tTransferAmount, uint256 tFee, uint256 tBurn) = _getValues(tAmount);
    uint256 rBurn = tBurn.mul(currentRate);
    _tOwned[sender] = _tOwned[sender].sub(tAmount);
    _rOwned[sender] = _rOwned[sender].sub(rAmount);
    _rOwned[recipient] = _rOwned[recipient].add(rTransferAmount);
    _reflectFee(rFee, rBurn, tFee, tBurn);
    emit Transfer(sender, recipient, tTransferAmount);
  }

  function _transferBothExcluded(
    address sender,
    address recipient,
    uint256 tAmount
  ) private {
    uint256 currentRate = _getRate();
    (uint256 rAmount, uint256 rTransferAmount, uint256 rFee, uint256 tTransferAmount, uint256 tFee, uint256 tBurn) = _getValues(tAmount);
    uint256 rBurn = tBurn.mul(currentRate);
    _tOwned[sender] = _tOwned[sender].sub(tAmount);
    _rOwned[sender] = _rOwned[sender].sub(rAmount);
    _tOwned[recipient] = _tOwned[recipient].add(tTransferAmount);
    _rOwned[recipient] = _rOwned[recipient].add(rTransferAmount);
    _reflectFee(rFee, rBurn, tFee, tBurn);
    emit Transfer(sender, recipient, tTransferAmount);
  }

  function _reflectFee(
    uint256 rFee,
    uint256 rBurn,
    uint256 tFee,
    uint256 tBurn
  ) private {
    uint256 rDev = rFee.mul(_treasuryFee).div(_taxFee);
    uint256 tDev = tFee.mul(_treasuryFee).div(_taxFee);
    _rOwned[crbTreasury] = _rOwned[crbTreasury].add(rDev);
    _rTotal = _rTotal.sub(rFee).sub(rBurn).add(rDev);
    _tFeeTotal = _tFeeTotal.add(tFee).sub(tDev);
    _tBurnTotal = _tBurnTotal.add(tBurn);
    _tTotal = _tTotal.sub(tBurn);
  }

  function _getValues(uint256 tAmount)
    private
    view
    returns (
      uint256,
      uint256,
      uint256,
      uint256,
      uint256,
      uint256
    )
  {
    (uint256 tTransferAmount, uint256 tFee, uint256 tBurn) = _getTValues(tAmount, _taxFee, _burnFee);
    uint256 currentRate = _getRate();
    (uint256 rAmount, uint256 rTransferAmount, uint256 rFee) = _getRValues(tAmount, tFee, tBurn, currentRate);
    return (rAmount, rTransferAmount, rFee, tTransferAmount, tFee, tBurn);
  }

  function _getTValues(
    uint256 tAmount,
    uint256 taxFee,
    uint256 burnFee
  )
    private
    pure
    returns (
      uint256,
      uint256,
      uint256
    )
  {
    uint256 tFee = tAmount.mul(taxFee).div(10000);
    uint256 tBurn = tAmount.mul(burnFee).div(10000);
    uint256 tTransferAmount = tAmount.sub(tFee).sub(tBurn);
    return (tTransferAmount, tFee, tBurn);
  }

  function _getRValues(
    uint256 tAmount,
    uint256 tFee,
    uint256 tBurn,
    uint256 currentRate
  )
    private
    pure
    returns (
      uint256,
      uint256,
      uint256
    )
  {
    uint256 rAmount = tAmount.mul(currentRate);
    uint256 rFee = tFee.mul(currentRate);
    uint256 rBurn = tBurn.mul(currentRate);
    uint256 rTransferAmount = rAmount.sub(rFee).sub(rBurn);
    return (rAmount, rTransferAmount, rFee);
  }

  function _getRate() private view returns (uint256) {
    (uint256 rSupply, uint256 tSupply) = _getCurrentSupply();
    return rSupply.div(tSupply);
  }

  function _getCurrentSupply() private view returns (uint256, uint256) {
    uint256 rSupply = _rTotal;
    uint256 tSupply = _tTotal;
    for (uint256 i = 0; i < _excluded.length; i++) {
      if (_rOwned[_excluded[i]] > rSupply || _tOwned[_excluded[i]] > tSupply) return (_rTotal, _tTotal);
      rSupply = rSupply.sub(_rOwned[_excluded[i]]);
      tSupply = tSupply.sub(_tOwned[_excluded[i]]);
    }
    if (rSupply < _rTotal.div(_tTotal)) return (_rTotal, _tTotal);
    return (rSupply, tSupply);
  }

  function _getTaxFee() private view returns (uint256) {
    return _taxFee;
  }

  function _setTaxFee(uint256 taxFee) external onlyOwner() {
    require(taxFee >= 1 && taxFee <= 1000, "taxFee should be in 0.01% - 10%");
    _taxFee = taxFee;
  }

  function _getBurnFee() private view returns (uint256) {
    return _burnFee;
  }

  function _setBurnFee(uint256 burnFee) external onlyOwner() {
    require(burnFee < _taxFee, "burnFee should be less than taxFee");
    _burnFee = burnFee;
  }

  function _setTreasuryFee(uint256 treasuryFee) external onlyOwner() {
    require(treasuryFee < _taxFee, "treasuryFee should be less than taxFee");
    _treasuryFee = treasuryFee;
  }

  // Pausing transfers of the token
  function setPaused(bool _pause) public onlyOwner {
    paused = _pause;
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
    require(tokenUniswapPairDEFLCTCRB == address(0), "CBR/DEF pair already created");
    tokenUniswapPairDEFLCTCRB = uniswapFactory.createPair(address(DEFLCT), address(this));

    require(tokenUniswapPairYMENCRB == address(0), "DEF/YMEN pair already created");
    tokenUniswapPairYMENCRB = uniswapFactory.createPair(address(YMEN), address(this));

    return (tokenUniswapPairDEFLCTCRB, tokenUniswapPairDEFLCTYMEN, tokenUniswapPairYMENCRB);
  }

  function getEstimatedToken1forToken2(
    uint256 token1input,
    address tokenSelling,
    address tokenBuying
  ) public view returns (uint256) {
    address pair = uniswapFactory.getPair(tokenSelling, tokenBuying);

    (uint256 token0Reserves, uint256 token1Reserves, ) = IUniswapV2Pair(pair).getReserves();
    uint256 token2output = uniswapRouterV2.getAmountOut(token1input, token0Reserves, token1Reserves);

    return token2output;
  }

  function addLiquidity() public payable {
    require(now < lgeEndTime, "Liquidity Generation Event over");

    uint256 ethForBuyingDeflect = msg.value.div(100).mul(50);
    uint256 ethForBuyingYmen = msg.value.div(100).mul(50);

    // 50% of ETH is used to market purchase DEFLCT
    uint256 deadline = block.timestamp + 15;
    address[] memory path = new address[](2);
    path[0] = WETH;
    path[1] = DEFLCT;

    // 50% of ETH is used to market purchase YMEN
    uint256 deadline2 = block.timestamp + 15;
    address[] memory path2 = new address[](2);
    path2[0] = WETH;
    path2[1] = YMEN;

    require(IERC20(DEFLCT).approve(address(uniswapRouterV2), uint256(-1)), "Approval issue");
    require(IERC20(YMEN).approve(address(uniswapRouterV2), uint256(-1)), "Approval issue");

    uint256 deflctPurchased = getEstimatedToken1forToken2(ethForBuyingDeflect, WETH, DEFLCT);
    uint256 ymenPurchased = getEstimatedToken1forToken2(ethForBuyingDeflect, WETH, YMEN);

    uniswapRouterV2.swapExactETHForTokensSupportingFeeOnTransferTokens{ value: ethForBuyingDeflect }(0, path, address(this), deadline);
    uniswapRouterV2.swapExactETHForTokensSupportingFeeOnTransferTokens{ value: ethForBuyingYmen }(0, path2, address(this), deadline2);

    DEFLCTcontributedForLPTokens[msg.sender] += deflctPurchased;
    YMENcontributedForLPTokens[msg.sender] += ymenPurchased;
    ethContributedForLPTokens[msg.sender] += msg.value;

    totalDEFLCTContributed += deflctPurchased;
    totalYMENContributed += ymenPurchased;
    totalETHContributed += msg.value;

    emit LiquidityAddition(msg.sender, msg.value);
  }

  function addLiquidityLPToUniswapPair() external onlyOwner {
    require(now >= lgeEndTime, "Liquidity generation ongoing");
    require(LPGenerationCompleted == false, "Liquidity generation already finished");
    require(now > (lgeEndTime + 2 hours) || _msgSender() == owner(), "Please wait for dev grace period");

    // YMEN / CRB
    uint256 HALF_OF_YMEN_BALANCE = IERC20(YMEN).balanceOf(address(this)).div(2);

    // DEF / YMEN
    uint256 HALF_OF_DEFLECT_BALANCE = IERC20(DEFLCT).balanceOf(address(this)).div(2);

    IUniswapV2Pair ymenDefPair = IUniswapV2Pair(tokenUniswapPairDEFLCTYMEN);
    IUniswapV2Pair crbDefPair = IUniswapV2Pair(tokenUniswapPairDEFLCTCRB);
    IUniswapV2Pair ymenCrbPair = IUniswapV2Pair(tokenUniswapPairYMENCRB);

    // Create YMEN/DEFLCT LP
    IERC20(YMEN).transfer(address(ymenDefPair), HALF_OF_YMEN_BALANCE);
    IERC20(DEFLCT).transfer(address(ymenDefPair), HALF_OF_DEFLECT_BALANCE);
    ymenDefPair.mint(address(this));

    DEF_YMEN_TOTAL_LP_TOKENS_MINTED = ymenDefPair.balanceOf(address(this));
    require(DEF_YMEN_TOTAL_LP_TOKENS_MINTED != 0, "DEF/YMEN LP creation failed");


    DEFLCTYMENLPperETHUnit = DEF_YMEN_TOTAL_LP_TOKENS_MINTED.mul(1e18).div(totalETHContributed);

    require(DEFLCTYMENLPperETHUnit != 0, "DEF / YMEN LP creation failed");

    // Create CRB/DEFLCT LP
    // Transfer remainder of Deflect
    IERC20(DEFLCT).transfer(address(crbDefPair), IERC20(DEFLCT).balanceOf(address(this)));
    // Transfer 150k CRB into LP
    _transfer(address(this), address(crbDefPair), 150000 * 10**9);
    crbDefPair.mint(address(this));

    // Check that tokens were minted
    DEF_CRB_TOTAL_LP_TOKENS_MINTED = crbDefPair.balanceOf(address(this));
    require(DEF_CRB_TOTAL_LP_TOKENS_MINTED != 0, "DEF CRB LP creation failed");

    // Did we get an LP per ETH value?
    DEFLCTCRBLPperETHUnit = DEF_CRB_TOTAL_LP_TOKENS_MINTED.mul(1e18).div(totalETHContributed);
    require(DEFLCTCRBLPperETHUnit != 0, "DEF CRB LP creation failed");

    // Create YMEN/CRB LP
    // Transfer remainder of YMEN
    IERC20(YMEN).transfer(address(ymenCrbPair), IERC20(YMEN).balanceOf(address(this)));
    // Transfer 150k CRB into LP
    _transfer(address(this), address(ymenCrbPair), 150000 * 10**9);
    ymenCrbPair.mint(address(this));

    // Check that tokens were minted
    YMEN_CRB_TOTAL_LP_TOKENS_MINTED = ymenCrbPair.balanceOf(address(this));
    require(YMEN_CRB_TOTAL_LP_TOKENS_MINTED != 0, "YMEN CRB LP creation failed");

    // Did we get an LP per ETH value?
    YMENCRBLPperETHUnit = YMEN_CRB_TOTAL_LP_TOKENS_MINTED.mul(1e18).div(totalETHContributed);
    require(DEFLCTCRBLPperETHUnit != 0, "YMEN CRB LP creation failed");
    LPGenerationCompleted = true;

    _taxFee = 125;
    _burnFee = 75;
    _treasuryFee = 25;
  }

  function claimLPTokens() public {
    require(LPGenerationCompleted, "LGE not completed");
    require(ethContributedForLPTokens[msg.sender] > 0, "Nothing to claim");
    require(DEFLCTcontributedForLPTokens[msg.sender] > 0, "Nothing to claim");
    require(YMENcontributedForLPTokens[msg.sender] > 0, "Nothing to claim");

    IUniswapV2Pair DEFLCTYMENpair = IUniswapV2Pair(tokenUniswapPairDEFLCTYMEN);
    IUniswapV2Pair DEFLCTCRBpair = IUniswapV2Pair(tokenUniswapPairDEFLCTCRB);
    IUniswapV2Pair YMENCRBpair = IUniswapV2Pair(tokenUniswapPairYMENCRB);

    uint256 DEF_YMEN_TO_TRANSFER = ethContributedForLPTokens[msg.sender].mul(DEFLCTYMENLPperETHUnit).div(1e18);
    uint256 DEF_CRB_TO_TRANSFER = ethContributedForLPTokens[msg.sender].mul(DEFLCTCRBLPperETHUnit).div(1e18);
    uint256 YMEN_CRB_TO_TRANSFER = ethContributedForLPTokens[msg.sender].mul(YMENCRBLPperETHUnit).div(1e18);

    DEFLCTcontributedForLPTokens[msg.sender] = 0;
    YMENcontributedForLPTokens[msg.sender] = 0;

    DEFLCTYMENpair.transfer(msg.sender, DEF_YMEN_TO_TRANSFER);
    DEFLCTCRBpair.transfer(msg.sender, DEF_CRB_TO_TRANSFER);
    YMENCRBpair.transfer(msg.sender, YMEN_CRB_TO_TRANSFER);

    emit LPTokenClaimed(msg.sender, DEF_YMEN_TO_TRANSFER);
    emit LPTokenClaimed(msg.sender, DEF_CRB_TO_TRANSFER);
    emit LPTokenClaimed(msg.sender, YMEN_CRB_TO_TRANSFER);
  }

  function emergencyRecoveryIfLiquidityGenerationEventFails() external onlyOwner {
    require(lgeEndTime.add(1 days) < now, "Liquidity generation grace period still ongoing");
    IERC20(DEFLCT).transfer(msg.sender, IERC20(DEFLCT).balanceOf(address(this)));
    IERC20(YMEN).transfer(msg.sender, IERC20(YMEN).balanceOf(address(this)));
    this.transfer(msg.sender, balanceOf(address(this)));
  }

  // Emergency drain in case of a bug
  function emergencyDrain48hAfterLiquidityGenerationEventIsDone() public {
    require(lgeEndTime.add(2 days) < block.timestamp, "LGE grace period still ongoing"); // About 48h after liquidity generation happens

    uint256 deflectClaim = DEFLCTcontributedForLPTokens[msg.sender];
    uint256 ymenClaim = YMENcontributedForLPTokens[msg.sender];

    DEFLCTcontributedForLPTokens[msg.sender] = 0;
    YMENcontributedForLPTokens[msg.sender] = 0;

    require(IERC20(DEFLCT).transfer(msg.sender, deflectClaim), "DEFLCT Transfer Failed");
    require(IERC20(YMEN).transfer(msg.sender, ymenClaim), "YMEN Transfer failed.");
  }
}
