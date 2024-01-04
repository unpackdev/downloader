pragma solidity 0.5.17;
pragma experimental ABIEncoderV2;


interface IUniswap {
  
  function swapExactTokensForETH(uint amountIn, uint amountOutMin, address[] calldata path, address to, uint deadline) external returns (uint[] memory amounts);
  
  function swapExactETHForTokens(uint amountOutMin, address[] calldata path, address to, uint deadline) external payable returns (uint[] memory amounts);
  function getAmountsOut(uint amountIn, address[] calldata path) external view returns (uint[] memory amounts);
}

interface IERC20 {
    function totalSupply() external view returns (uint256);
    function balanceOf(address account) external view returns (uint256);
    function transfer(address recipient, uint256 amount) external returns (bool);
    function allowance(address owner, address spender) external view returns (uint256);
    function approve(address spender, uint256 amount) external returns (bool);
    function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);
    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(address indexed owner, address indexed spender, uint256 value);
}

contract Context {
    constructor () internal { }
    

    function _msgSender() internal view returns (address payable) {
        return msg.sender;
    }

    function _msgData() internal view returns (bytes memory) {
        this; 
        return msg.data;
    }
}

contract Ownable is Context {
    address payable private _owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);
    constructor () internal {
        _owner = _msgSender();
        emit OwnershipTransferred(address(0), _owner);
    }
    function owner() public view returns (address payable) {
        return _owner;
    }
    modifier onlyOwner() {
        require(isOwner(), "Ownable: caller is not the owner");
        _;
    }
    function isOwner() public view returns (bool) {
        return _msgSender() == _owner;
    }
    function renounceOwnership() public onlyOwner {
        emit OwnershipTransferred(_owner, address(0));
        _owner = address(0);
    }
    function transferOwnership(address payable newOwner) public onlyOwner {
        _transferOwnership(newOwner);
    }
    function _transferOwnership(address payable newOwner) internal {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        emit OwnershipTransferred(_owner, newOwner);
        _owner = newOwner;
    }
}

contract ERC20 is Context, IERC20 {
    using SafeMath for uint256;

    mapping (address => uint256) _balances;

    mapping (address => mapping (address => uint256)) private _allowances;

    uint256 _totalSupply;
    function totalSupply() public view returns (uint256) {
        return _totalSupply;
    }
    function balanceOf(address account) public view returns (uint256) {
        return _balances[account];
    }
    function transfer(address recipient, uint256 amount) public returns (bool) {
        _transfer(_msgSender(), recipient, amount);
        return true;
    }
    function allowance(address owner, address spender) public view returns (uint256) {
        return _allowances[owner][spender];
    }
    function approve(address spender, uint256 amount) public returns (bool) {
        _approve(_msgSender(), spender, amount);
        return true;
    }
    function transferFrom(address sender, address recipient, uint256 amount) public returns (bool) {
        _transfer(sender, recipient, amount);
        _approve(sender, _msgSender(), _allowances[sender][_msgSender()].sub(amount, "ERC20: transfer amount exceeds allowance"));
        return true;
    }
    function increaseAllowance(address spender, uint256 addedValue) public returns (bool) {
        _approve(_msgSender(), spender, _allowances[_msgSender()][spender].add(addedValue));
        return true;
    }
    function decreaseAllowance(address spender, uint256 subtractedValue) public returns (bool) {
        _approve(_msgSender(), spender, _allowances[_msgSender()][spender].sub(subtractedValue, "ERC20: decreased allowance below zero"));
        return true;
    }
    function _transfer(address sender, address recipient, uint256 amount) internal {
        require(sender != address(0), "ERC20: transfer from the zero address");
        require(recipient != address(0), "ERC20: transfer to the zero address");

        _balances[sender] = _balances[sender].sub(amount, "ERC20: transfer amount exceeds balance");
        _balances[recipient] = _balances[recipient].add(amount);
        emit Transfer(sender, recipient, amount);
    }
    function _mint(address account, uint256 amount) internal {
        require(account != address(0), "ERC20: mint to the zero address");

        _totalSupply = _totalSupply.add(amount);
        _balances[account] = _balances[account].add(amount);
        emit Transfer(address(0), account, amount);
    }
    function _burn(address account, uint256 amount) internal {
        require(account != address(0), "ERC20: burn from the zero address");

        _balances[account] = _balances[account].sub(amount, "ERC20: burn amount exceeds balance");
        _totalSupply = _totalSupply.sub(amount);
        emit Transfer(account, address(0), amount);
    }
    function _approve(address owner, address spender, uint256 amount) internal {
        require(owner != address(0), "ERC20: approve from the zero address");
        require(spender != address(0), "ERC20: approve to the zero address");

        _allowances[owner][spender] = amount;
        emit Approval(owner, spender, amount);
    }
    function _burnFrom(address account, uint256 amount) internal {
        _burn(account, amount);
        _approve(account, _msgSender(), _allowances[account][_msgSender()].sub(amount, "ERC20: burn amount exceeds allowance"));
    }
}

contract ERC20Detailed is IERC20 {
    string private _name;
    string private _symbol;
    uint8 private _decimals;

    constructor (string memory name, string memory symbol, uint8 decimals) public {
        _name = name;
        _symbol = symbol;
        _decimals = decimals;
    }
    function name() public view returns (string memory) {
        return _name;
    }
    function symbol() public view returns (string memory) {
        return _symbol;
    }
    function decimals() public view returns (uint8) {
        return _decimals;
    }
}

contract ReentrancyGuard {
    uint256 private _guardCounter;

    constructor () internal {
        _guardCounter = 1;
    }

    modifier nonReentrant() {
        _guardCounter += 1;
        uint256 localCounter = _guardCounter;
        _;
        require(localCounter == _guardCounter, "ReentrancyGuard: reentrant call");
    }
}

library SafeMath {
    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a + b;
        require(c >= a, "SafeMath: addition overflow");

        return c;
    }
    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        return sub(a, b, "SafeMath: subtraction overflow");
    }
    function sub(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b <= a, errorMessage);
        uint256 c = a - b;

        return c;
    }
    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        if (a == 0) {
            return 0;
        }

        uint256 c = a * b;
        require(c / a == b, "SafeMath: multiplication overflow");

        return c;
    }
    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        return div(a, b, "SafeMath: division by zero");
    }
    function div(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        
        require(b > 0, errorMessage);
        uint256 c = a / b;

        return c;
    }
    function mod(uint256 a, uint256 b) internal pure returns (uint256) {
        return mod(a, b, "SafeMath: modulo by zero");
    }
    function mod(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b != 0, errorMessage);
        return a % b;
    }
}

library Address {
    function isContract(address account) internal view returns (bool) {
        bytes32 codehash;
        bytes32 accountHash = 0xc5d2460186f7233c927e7db2dcc703c0e500b653ca82273b7bfad8045d85a470;
        
        assembly { codehash := extcodehash(account) }
        return (codehash != 0x0 && codehash != accountHash);
    }
    function toPayable(address account) internal pure returns (address payable) {
        return address(uint160(account));
    }
    function sendValue(address payable recipient, uint256 amount) internal {
        require(address(this).balance >= amount, "Address: insufficient balance");

        
        (bool success, ) = recipient.call.value(amount)("");
        require(success, "Address: unable to send value, recipient may have reverted");
    }
}

library SafeERC20 {
    using SafeMath for uint256;
    using Address for address;

    function safeTransfer(IERC20 token, address to, uint256 value) internal {
        callOptionalReturn(token, abi.encodeWithSelector(token.transfer.selector, to, value));
    }

    function safeTransferFrom(IERC20 token, address from, address to, uint256 value) internal {
        callOptionalReturn(token, abi.encodeWithSelector(token.transferFrom.selector, from, to, value));
    }

    function safeApprove(IERC20 token, address spender, uint256 value) internal {
        require((value == 0) || (token.allowance(address(this), spender) == 0),
            "SafeERC20: approve from non-zero to non-zero allowance"
        );
        callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, value));
    }

    function safeIncreaseAllowance(IERC20 token, address spender, uint256 value) internal {
        uint256 newAllowance = token.allowance(address(this), spender).add(value);
        callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, newAllowance));
    }

    function safeDecreaseAllowance(IERC20 token, address spender, uint256 value) internal {
        uint256 newAllowance = token.allowance(address(this), spender).sub(value, "SafeERC20: decreased allowance below zero");
        callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, newAllowance));
    }
    function callOptionalReturn(IERC20 token, bytes memory data) private {
        require(address(token).isContract(), "SafeERC20: call to non-contract");

        
        (bool success, bytes memory returndata) = address(token).call(data);
        require(success, "SafeERC20: low-level call failed");

        if (returndata.length > 0) { 
            
            require(abi.decode(returndata, (bool)), "SafeERC20: ERC20 operation did not succeed");
        }
    }
}

interface Compound {
    function mint ( uint256 mintAmount ) external returns ( uint256 );
    function redeem(uint256 redeemTokens) external returns (uint256);
    function exchangeRateStored() external view returns (uint);
}

interface Fulcrum {
    function mint(address receiver, uint256 amount) external payable returns (uint256 mintAmount);
    function burn(address receiver, uint256 burnAmount) external returns (uint256 loanAmountPaid);
    function assetBalanceOf(address _owner) external view returns (uint256 balance);
}

interface ILendingPoolAddressesProvider {
    function getLendingPool() external view returns (address);
}

interface Aave {
    function deposit(address _reserve, uint256 _amount, uint16 _referralCode) external;
}

interface AToken {
    function redeem(uint256 amount) external;
}

interface IIEarnManager {
    function recommend(address _token) external view returns (
      string memory choice,
      uint256 capr,
      uint256 iapr,
      uint256 aapr,
      uint256 dapr
    );
}

contract Structs {
    struct Val {
        uint256 value;
    }

    enum ActionType {
        Deposit,   
        Withdraw  
    }

    enum AssetDenomination {
        Wei 
    }

    enum AssetReference {
        Delta 
    }

    struct AssetAmount {
        bool sign; 
        AssetDenomination denomination;
        AssetReference ref;
        uint256 value;
    }

    struct ActionArgs {
        ActionType actionType;
        uint256 accountId;
        AssetAmount amount;
        uint256 primaryMarketId;
        uint256 secondaryMarketId;
        address otherAddress;
        uint256 otherAccountId;
        bytes data;
    }

    struct Info {
        address owner;  
        uint256 number; 
    }

    struct Wei {
        bool sign; 
        uint256 value;
    }
}

contract DyDx is Structs {
    function getAccountWei(Info memory account, uint256 marketId) public view returns (Wei memory);
    function operate(Info[] memory, ActionArgs[] memory) public;
}

interface LendingPoolAddressesProvider {
    function getLendingPool() external view returns (address);
    function getLendingPoolCore() external view returns (address);
}

contract CommonFunctionality is Ownable {
  using SafeMath for uint256;

  uint256 public percentageRetirementYield = 15e17; 
  uint256 public percentageDevTreasury = 25e17; 
  uint256 public percentageBuyBurn = 1e18; 

  function isContract(address account) internal view returns (bool) {
    
    
    

    uint256 size;
    
    assembly { size := extcodesize(account) }
    return size > 0;
  }

  modifier noContract() {
      require(isContract(msg.sender) == false, 'Contracts are not allowed to interact with the farm');
      _;
  }

  function updatePercentages(uint256 a, uint256 b, uint256 c) public onlyOwner {
    percentageRetirementYield = a;
    percentageDevTreasury = b;
    percentageBuyBurn = c;
  }

  function getYeldPriceInDai(address _yeld, address _weth, address _dai, address _uniswap) public view returns(uint256) {
    address[] memory path = new address[](3);
    path[0] = _yeld;
    path[1] = _weth;
    path[2] = _dai;
    uint256[] memory amounts = IUniswap(_uniswap).getAmountsOut(1e18, path);
    return amounts[2];
  }
}

contract yUSDC is ERC20, ERC20Detailed, ReentrancyGuard, Structs, Ownable, CommonFunctionality {
  using SafeERC20 for IERC20;
  using Address for address;
  using SafeMath for uint256;

  uint256 public pool;
  address public token;
  address public compound;
  address public fulcrum;
  address public aave;
  address public aaveToken;
  address public dydx;
  uint256 public dToken;
  address public apr;

  
  mapping(address => uint256) public depositBlockStarts;
  mapping(address => uint256) public depositAmount;
  address public uniswapRouter = 0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D;
  address public usdc = 0xA0b86991c6218b36c1d19D4a2e9Eb0cE3606eB48;
  address public weth = 0xC02aaA39b223FE8D0A0e5C4F27eAD9083C756Cc2;
  address public dai = 0x6B175474E89094C44Da98b954EedeAC495271d0F;
  address payable public retirementYeldTreasury;
  IERC20 public yeldToken;
  uint256 public maximumTokensToBurn = 50000 * 1e18;
  uint256 public constant oneDayInBlocks = 6500;
  uint256 public yeldToRewardPerDay = 50e18; 
  uint256 public constant oneMillion = 1e6;
  uint256 public holdPercentage = 15e18;
  address public devTreasury;
  

  enum Lender {
      NONE,
      DYDX,
      COMPOUND,
      AAVE,
      FULCRUM
  }

  Lender public provider = Lender.NONE;

  constructor (address _yeldToken, address payable _retirementYeldTreasury, address _devTreasury) public ERC20Detailed("yeld USDC", "yUSDC", 6) {
    token = address(0xA0b86991c6218b36c1d19D4a2e9Eb0cE3606eB48);
    apr = address(0xdD6d648C991f7d47454354f4Ef326b04025a48A8);
    dydx = address(0x1E0447b19BB6EcFdAe1e4AE1694b0C3659614e4e);
    aave = address(0x24a42fD28C976A61Df5D00D0599C34c4f90748c8);
    fulcrum = address(0xF013406A0B1d544238083DF0B93ad0d2cBE0f65f);
    aaveToken = address(0x9bA00D6856a4eDF4665BcA2C2309936572473B7E);
    compound = address(0x39AA39c021dfbaE8faC545936693aC917d5E7563);
    dToken = 2;
    yeldToken = IERC20(_yeldToken);
    retirementYeldTreasury = _retirementYeldTreasury;
    devTreasury = _devTreasury;
    approveToken();
  }

  
  
  function () external payable {}
  function setRetirementYeldTreasury(address payable _treasury) public onlyOwner {
    retirementYeldTreasury = _treasury;
  }
  
  function setUniswapRouter(address _uniswapRouter) public onlyOwner {
    uniswapRouter = _uniswapRouter;
  }
  function setYeldToken(address _yeldToken) public onlyOwner {
    yeldToken = IERC20(_yeldToken);
  }
  function extractTokensIfStuck(address _token, uint256 _amount) public onlyOwner {
    IERC20(_token).transfer(msg.sender, _amount);
  }
  function extractETHIfStuck() public onlyOwner {
    owner().transfer(address(this).balance);
  }
  function changeYeldToRewardPerDay(uint256 _amount) public onlyOwner {
    yeldToRewardPerDay = _amount;
  }
  function getGeneratedYelds() public view returns(uint256) {
    uint256 blocksPassed;
    if (depositBlockStarts[msg.sender] > 0) {
      blocksPassed = block.number.sub(depositBlockStarts[msg.sender]);
    } else {
      return 0;
    }
    uint256 generatedYelds = depositAmount[msg.sender].mul(1e12).div(oneMillion).mul(yeldToRewardPerDay).div(1e18).mul(blocksPassed).div(oneDayInBlocks);
    return generatedYelds;
  }
  
  function usdcToETH(uint256 _amount) internal returns(uint256) {
      IERC20(usdc).safeApprove(uniswapRouter, 0);
      IERC20(usdc).safeApprove(uniswapRouter, _amount);
      address[] memory path = new address[](2);
      path[0] = usdc;
      path[1] = weth;
      
      
      
      
      uint[] memory amounts = IUniswap(uniswapRouter).swapExactTokensForETH(_amount, uint(0), path, address(this), now.add(1800));
      return amounts[1];
  }
  function buyNBurn(uint256 _ethToSwap) internal returns(uint256) {
    address[] memory path = new address[](2);
    path[0] = weth;
    path[1] = address(yeldToken);
    
    uint[] memory amounts = IUniswap(uniswapRouter).swapExactETHForTokens.value(_ethToSwap)(uint(0), path, address(0), now.add(1800));
    return amounts[1];
  }
  
  function setHoldPercentage(uint256 _holdPercentage) public onlyOwner {
    holdPercentage = _holdPercentage;
  }

  function yeldHoldingRequirement(uint256 _amount) internal view {
    uint256 yeldHold = yeldToken.balanceOf(msg.sender);
    uint256 yeldPriceInDai = getYeldPriceInDai(address(yeldToken), weth, dai, uniswapRouter);
    uint256 amountPercentage = _amount.mul(holdPercentage).div(1e20);
    uint256 yeldRequirement = amountPercentage.div(yeldPriceInDai);
    require(yeldHold >= yeldRequirement, 'You must hold a % of your deposit in YELD tokens to be able to stake or withdraw');
  }

  
  function deposit(uint256 _amount)
      external
      nonReentrant
      noContract
  {
      require(_amount > 0, "deposit must be greater than 0");
      yeldHoldingRequirement(_amount);

      pool = _calcPoolValueInToken();

      IERC20(token).safeTransferFrom(msg.sender, address(this), _amount);

      
      depositBlockStarts[msg.sender] = block.number;
      depositAmount[msg.sender] = depositAmount[msg.sender].add(_amount);
      
      
      
      uint256 shares = 0;
      if (pool == 0) {
        shares = _amount;
        pool = _amount;
      } else {
        shares = (_amount.mul(_totalSupply)).div(pool);
      }
      pool = _calcPoolValueInToken();
      _mint(msg.sender, shares);
      rebalance();
  }

  
  function withdraw(uint256 _shares)
      external
      nonReentrant
      noContract
  {
      require(_shares > 0, "withdraw must be greater than 0");
      uint256 ibalance = balanceOf(msg.sender);
      require(_shares <= ibalance, "insufficient balance");
      
      pool = _calcPoolValueInToken();
      
      uint256 generatedYelds = getGeneratedYelds();
      
      uint256 stablecoinsToWithdraw = (pool.mul(_shares)).div(_totalSupply);
      yeldHoldingRequirement(stablecoinsToWithdraw);
      _balances[msg.sender] = _balances[msg.sender].sub(_shares, "redeem amount exceeds balance");
      _totalSupply = _totalSupply.sub(_shares);
      emit Transfer(msg.sender, address(0), _shares);
      uint256 b = IERC20(token).balanceOf(address(this));
      if (b < stablecoinsToWithdraw) {
        _withdrawSome(stablecoinsToWithdraw.sub(b));
      }


      
      
      uint256 totalPercentage = percentageRetirementYield.add(percentageDevTreasury).add(percentageBuyBurn);
      uint256 combined = stablecoinsToWithdraw.mul(totalPercentage).div(1e20);
      depositBlockStarts[msg.sender] = block.number;
      depositAmount[msg.sender] = depositAmount[msg.sender].sub(stablecoinsToWithdraw);
      yeldToken.transfer(msg.sender, generatedYelds);
      
      
      uint256 stakingProfits = usdcToETH(combined);
      uint256 tokensAlreadyBurned = yeldToken.balanceOf(address(0));
      uint256 devTreasuryAmount = stakingProfits.mul(uint256(100e18).mul(percentageDevTreasury).div(totalPercentage)).div(100e18);
      if (tokensAlreadyBurned < maximumTokensToBurn) {
        uint256 ethToSwap = stakingProfits.mul(uint256(100e18).mul(percentageBuyBurn).div(totalPercentage)).div(100e18);
        buyNBurn(ethToSwap);
        uint256 retirementYeld = stakingProfits.mul(uint256(100e18).mul(percentageRetirementYield).div(totalPercentage)).div(100e18);
        retirementYeldTreasury.transfer(retirementYeld);
      } else {
        uint256 retirementYeld = stakingProfits.sub(devTreasuryAmount);
        retirementYeldTreasury.transfer(retirementYeld);
      }
      (bool success, ) = devTreasury.call.value(devTreasuryAmount)("");
      require(success, "Dev treasury transfer failed");
      IERC20(token).transfer(msg.sender, stablecoinsToWithdraw.sub(combined));
      

      pool = _calcPoolValueInToken();
      rebalance();
  }

  function recommend() public view returns (Lender) {
    (,uint256 capr,uint256 iapr,uint256 aapr,uint256 dapr) = IIEarnManager(apr).recommend(token);
    uint256 max = 0;
    if (capr > max) {
      max = capr;
    }
    if (iapr > max) {
      max = iapr;
    }
    if (aapr > max) {
      max = aapr;
    }
    if (dapr > max) {
      max = dapr;
    }

    Lender newProvider = Lender.NONE;
    if (max == capr) {
      newProvider = Lender.COMPOUND;
    } else if (max == iapr) {
      newProvider = Lender.FULCRUM;
    } else if (max == aapr) {
      newProvider = Lender.AAVE;
    } else if (max == dapr) {
      newProvider = Lender.DYDX;
    }
    return newProvider;
  }

  function supplyDydx(uint256 amount) public returns(uint) {
      Info[] memory infos = new Info[](1);
      infos[0] = Info(address(this), 0);

      AssetAmount memory amt = AssetAmount(true, AssetDenomination.Wei, AssetReference.Delta, amount);
      ActionArgs memory act;
      act.actionType = ActionType.Deposit;
      act.accountId = 0;
      act.amount = amt;
      act.primaryMarketId = dToken;
      act.otherAddress = address(this);

      ActionArgs[] memory args = new ActionArgs[](1);
      args[0] = act;

      DyDx(dydx).operate(infos, args);
  }

  function _withdrawDydx(uint256 amount) internal {
      Info[] memory infos = new Info[](1);
      infos[0] = Info(address(this), 0);

      AssetAmount memory amt = AssetAmount(false, AssetDenomination.Wei, AssetReference.Delta, amount);
      ActionArgs memory act;
      act.actionType = ActionType.Withdraw;
      act.accountId = 0;
      act.amount = amt;
      act.primaryMarketId = dToken;
      act.otherAddress = address(this);

      ActionArgs[] memory args = new ActionArgs[](1);
      args[0] = act;

      DyDx(dydx).operate(infos, args);
  }

  function getAave() public view returns (address) {
    return LendingPoolAddressesProvider(aave).getLendingPool();
  }
  function getAaveCore() public view returns (address) {
    return LendingPoolAddressesProvider(aave).getLendingPoolCore();
  }

  function approveToken() public {
      IERC20(token).safeApprove(compound, uint(-1)); 
      IERC20(token).safeApprove(dydx, uint(-1));
      IERC20(token).safeApprove(getAaveCore(), uint(-1));
      IERC20(token).safeApprove(fulcrum, uint(-1));
  }

  function balance() public view returns (uint256) {
    return IERC20(token).balanceOf(address(this));
  }

  function balanceDydx() public view returns (uint256) {
      Wei memory bal = DyDx(dydx).getAccountWei(Info(address(this), 0), dToken);
      return bal.value;
  }
  function balanceCompound() public view returns (uint256) {
      return IERC20(compound).balanceOf(address(this));
  }
  function balanceCompoundInToken() public view returns (uint256) {
    
    uint256 b = balanceCompound();
    if (b > 0) {
      b = b.mul(Compound(compound).exchangeRateStored()).div(1e18);
    }
    return b;
  }
  function balanceFulcrumInToken() public view returns (uint256) {
    uint256 b = balanceFulcrum();
    if (b > 0) {
      b = Fulcrum(fulcrum).assetBalanceOf(address(this));
    }
    return b;
  }
  function balanceFulcrum() public view returns (uint256) {
    return IERC20(fulcrum).balanceOf(address(this));
  }
  function balanceAave() public view returns (uint256) {
    return IERC20(aaveToken).balanceOf(address(this));
  }

  function _balance() internal view returns (uint256) {
    return IERC20(token).balanceOf(address(this));
  }

  function _balanceDydx() internal view returns (uint256) {
      Wei memory bal = DyDx(dydx).getAccountWei(Info(address(this), 0), dToken);
      return bal.value;
  }
  function _balanceCompound() internal view returns (uint256) {
      return IERC20(compound).balanceOf(address(this));
  }
  function _balanceCompoundInToken() internal view returns (uint256) {
    
    uint256 b = balanceCompound();
    if (b > 0) {
      b = b.mul(Compound(compound).exchangeRateStored()).div(1e18);
    }
    return b;
  }
  function _balanceFulcrumInToken() internal view returns (uint256) {
    uint256 b = balanceFulcrum();
    if (b > 0) {
      b = Fulcrum(fulcrum).assetBalanceOf(address(this));
    }
    return b;
  }
  function _balanceFulcrum() internal view returns (uint256) {
    return IERC20(fulcrum).balanceOf(address(this));
  }
  function _balanceAave() internal view returns (uint256) {
    return IERC20(aaveToken).balanceOf(address(this));
  }

  function _withdrawAll() internal {
    uint256 amount = _balanceCompound();
    if (amount > 0) {
      _withdrawCompound(amount);
    }
    amount = _balanceDydx();
    if (amount > 0) {
      _withdrawDydx(amount);
    }
    amount = _balanceFulcrum();
    if (amount > 0) {
      _withdrawFulcrum(amount);
    }
    amount = _balanceAave();
    if (amount > 0) {
      _withdrawAave(amount);
    }
  }

  function _withdrawSomeCompound(uint256 _amount) internal {
    uint256 b = balanceCompound();
    uint256 bT = balanceCompoundInToken();
    require(bT >= _amount, "insufficient funds");
    
    uint256 amount = (b.mul(_amount)).div(bT).add(1);
    _withdrawCompound(amount);
  }

  
  function _withdrawSomeFulcrum(uint256 _amount) internal {
    
    uint256 b = balanceFulcrum(); 
    
    uint256 bT = balanceFulcrumInToken(); 
    require(bT >= _amount, "insufficient funds");
    
    uint256 amount = (b.mul(_amount)).div(bT).add(1);
    _withdrawFulcrum(amount);
  }

  function _withdrawSome(uint256 _amount) internal {
    if (provider == Lender.COMPOUND) {
      _withdrawSomeCompound(_amount);
    }
    if (provider == Lender.AAVE) {
      require(balanceAave() >= _amount, "insufficient funds");
      _withdrawAave(_amount);
    }
    if (provider == Lender.DYDX) {
      require(balanceDydx() >= _amount, "insufficient funds");
      _withdrawDydx(_amount);
    }
    if (provider == Lender.FULCRUM) {
      _withdrawSomeFulcrum(_amount);
    }
  }

  function rebalance() public {
    Lender newProvider = recommend();

    if (newProvider != provider) {
      _withdrawAll();
    }

    if (balance() > 0) {
      if (newProvider == Lender.DYDX) {
        supplyDydx(balance());
      } else if (newProvider == Lender.FULCRUM) {
        supplyFulcrum(balance());
      } else if (newProvider == Lender.COMPOUND) {
        supplyCompound(balance());
      } else if (newProvider == Lender.AAVE) {
        supplyAave(balance());
      }
    }

    provider = newProvider;
  }

  
  function _rebalance(Lender newProvider) internal {
    if (_balance() > 0) {
      if (newProvider == Lender.DYDX) {
        supplyDydx(_balance());
      } else if (newProvider == Lender.FULCRUM) {
        supplyFulcrum(_balance());
      } else if (newProvider == Lender.COMPOUND) {
        supplyCompound(_balance());
      } else if (newProvider == Lender.AAVE) {
        supplyAave(_balance());
      }
    }
    provider = newProvider;
  }

  function supplyAave(uint amount) public {
      Aave(getAave()).deposit(token, amount, 0);
  }
  function supplyFulcrum(uint amount) public {
      require(Fulcrum(fulcrum).mint(address(this), amount) > 0, "FULCRUM: supply failed");
  }
  function supplyCompound(uint amount) public {
      require(Compound(compound).mint(amount) == 0, "COMPOUND: supply failed");
  }
  function _withdrawAave(uint amount) internal {
      AToken(aaveToken).redeem(amount);
  }
  function _withdrawFulcrum(uint amount) internal {
      require(Fulcrum(fulcrum).burn(address(this), amount) > 0, "FULCRUM: withdraw failed");
  }
  function _withdrawCompound(uint amount) internal {
      require(Compound(compound).redeem(amount) == 0, "COMPOUND: withdraw failed");
  }

  function invest(uint256 _amount)
      external
      nonReentrant
  {
      require(_amount > 0, "deposit must be greater than 0");
      pool = calcPoolValueInToken();

      IERC20(token).safeTransferFrom(msg.sender, address(this), _amount);

      rebalance();

      
      uint256 shares = 0;
      if (pool == 0) {
        shares = _amount;
        pool = _amount;
      } else {
        shares = (_amount.mul(_totalSupply)).div(pool);
      }
      pool = calcPoolValueInToken();
      _mint(msg.sender, shares);
  }

  function _calcPoolValueInToken() internal view returns (uint) {
    return _balanceCompoundInToken()
      .add(_balanceFulcrumInToken())
      .add(_balanceDydx())
      .add(_balanceAave())
      .add(_balance());
  }

  function calcPoolValueInToken() public view returns (uint) {
    return balanceCompoundInToken()
      .add(balanceFulcrumInToken())
      .add(balanceDydx())
      .add(balanceAave())
      .add(balance());
  }

  function getPricePerFullShare() public view returns (uint) {
    uint _pool = calcPoolValueInToken();
    return _pool.mul(1e18).div(_totalSupply);
  }

  
  function redeem(uint256 _shares)
      external
      nonReentrant
  {
      require(_shares > 0, "withdraw must be greater than 0");

      uint256 ibalance = balanceOf(msg.sender);
      require(_shares <= ibalance, "insufficient balance");

      
      pool = calcPoolValueInToken();
      
      uint256 r = (pool.mul(_shares)).div(_totalSupply);


      _balances[msg.sender] = _balances[msg.sender].sub(_shares, "redeem amount exceeds balance");
      _totalSupply = _totalSupply.sub(_shares);

      emit Transfer(msg.sender, address(0), _shares);

      
      uint256 b = IERC20(token).balanceOf(address(this));
      Lender newProvider = provider;
      if (b < r) {
        newProvider = recommend();
        if (newProvider != provider) {
          _withdrawAll();
        } else {
          _withdrawSome(r.sub(b));
        }
      }

      IERC20(token).safeTransfer(msg.sender, r);

      if (newProvider != provider) {
        _rebalance(newProvider);
      }
      pool = calcPoolValueInToken();
  }
}