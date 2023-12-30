pragma solidity 0.5.0;

interface IUniswapV2Pair {
    event Approval(address indexed owner, address indexed spender, uint value);
    event Transfer(address indexed from, address indexed to, uint value);

    function name() external pure returns (string memory);
    function symbol() external pure returns (string memory);
    function decimals() external pure returns (uint8);
    function totalSupply() external view returns (uint);
    function balanceOf(address owner) external view returns (uint);
    function allowance(address owner, address spender) external view returns (uint);

    function approve(address spender, uint value) external returns (bool);
    function transfer(address to, uint value) external returns (bool);
    function transferFrom(address from, address to, uint value) external returns (bool);

    function DOMAIN_SEPARATOR() external view returns (bytes32);
    function PERMIT_TYPEHASH() external pure returns (bytes32);
    function nonces(address owner) external view returns (uint);

    function permit(address owner, address spender, uint value, uint deadline, uint8 v, bytes32 r, bytes32 s) external;

    event Mint(address indexed sender, uint amount0, uint amount1);
    event Burn(address indexed sender, uint amount0, uint amount1, address indexed to);
    event Swap(
        address indexed sender,
        uint amount0In,
        uint amount1In,
        uint amount0Out,
        uint amount1Out,
        address indexed to
    );
    event Sync(uint112 reserve0, uint112 reserve1);

    function MINIMUM_LIQUIDITY() external pure returns (uint);
    function factory() external view returns (address);
    function token0() external view returns (address);
    function token1() external view returns (address);
    function getReserves() external view returns (uint112 reserve0, uint112 reserve1, uint32 blockTimestampLast);
    function price0CumulativeLast() external view returns (uint);
    function price1CumulativeLast() external view returns (uint);
    function kLast() external view returns (uint);

    function mint(address to) external returns (uint liquidity);
    function burn(address to) external returns (uint amount0, uint amount1);
    function swap(uint amount0Out, uint amount1Out, address to, bytes calldata data) external;
    function skim(address to) external;
    function sync() external;

    function initialize(address, address) external;
}


library UniswapV2Library {
    using SafeMath for uint;

    // returns sorted token addresses, used to handle return values from pairs sorted in this order
    function sortTokens(address tokenA, address tokenB) internal pure returns (address token0, address token1) {
        require(tokenA != tokenB, 'UniswapV2Library: IDENTICAL_ADDRESSES');
        (token0, token1) = tokenA < tokenB ? (tokenA, tokenB) : (tokenB, tokenA);
        require(token0 != address(0), 'UniswapV2Library: ZERO_ADDRESS');
    }

    // calculates the CREATE2 address for a pair without making any external calls
    function pairFor(address factory, address tokenA, address tokenB) internal pure returns (address pair) {
        (address token0, address token1) = sortTokens(tokenA, tokenB);
        pair = address(uint(keccak256(abi.encodePacked(
                hex'ff',
                factory,
                keccak256(abi.encodePacked(token0, token1)),
                hex'96e8ac4277198ff8b6f785478aa9a39f403cb768dd02cbee326c3e7da348845f' // init code hash
            ))));
    }

    // fetches and sorts the reserves for a pair
    function getReserves(address factory, address tokenA, address tokenB) internal view returns (uint reserveA, uint reserveB) {
        (address token0,) = sortTokens(tokenA, tokenB);
        (uint reserve0, uint reserve1,) = IUniswapV2Pair(pairFor(factory, tokenA, tokenB)).getReserves();
        (reserveA, reserveB) = tokenA == token0 ? (reserve0, reserve1) : (reserve1, reserve0);
    }

    // given some amount of an asset and pair reserves, returns an equivalent amount of the other asset
    function quote(uint amountA, uint reserveA, uint reserveB) internal pure returns (uint amountB) {
        require(amountA > 0, 'UniswapV2Library: INSUFFICIENT_AMOUNT');
        require(reserveA > 0 && reserveB > 0, 'UniswapV2Library: INSUFFICIENT_LIQUIDITY');
        amountB = amountA.mul(reserveB) / reserveA;
    }

    // given an input amount of an asset and pair reserves, returns the maximum output amount of the other asset
    function getAmountOut(uint amountIn, uint reserveIn, uint reserveOut) internal pure returns (uint amountOut) {
        require(amountIn > 0, 'UniswapV2Library: INSUFFICIENT_INPUT_AMOUNT');
        require(reserveIn > 0 && reserveOut > 0, 'UniswapV2Library: INSUFFICIENT_LIQUIDITY');
        uint amountInWithFee = amountIn.mul(997);
        uint numerator = amountInWithFee.mul(reserveOut);
        uint denominator = reserveIn.mul(1000).add(amountInWithFee);
        amountOut = numerator / denominator;
    }

    // given an output amount of an asset and pair reserves, returns a required input amount of the other asset
    function getAmountIn(uint amountOut, uint reserveIn, uint reserveOut) internal pure returns (uint amountIn) {
        require(amountOut > 0, 'UniswapV2Library: INSUFFICIENT_OUTPUT_AMOUNT');
        require(reserveIn > 0 && reserveOut > 0, 'UniswapV2Library: INSUFFICIENT_LIQUIDITY');
        uint numerator = reserveIn.mul(amountOut).mul(1000);
        uint denominator = reserveOut.sub(amountOut).mul(997);
        amountIn = (numerator / denominator).add(1);
    }

    // performs chained getAmountOut calculations on any number of pairs
    function getAmountsOut(address factory, uint amountIn, address[] memory path) internal view returns (uint[] memory amounts) {
        require(path.length >= 2, 'UniswapV2Library: INVALID_PATH');
        amounts = new uint[](path.length);
        amounts[0] = amountIn;
        for (uint i; i < path.length - 1; i++) {
            (uint reserveIn, uint reserveOut) = getReserves(factory, path[i], path[i + 1]);
            amounts[i + 1] = getAmountOut(amounts[i], reserveIn, reserveOut);
        }
    }

    // performs chained getAmountIn calculations on any number of pairs
    function getAmountsIn(address factory, uint amountOut, address[] memory path) internal view returns (uint[] memory amounts) {
        require(path.length >= 2, 'UniswapV2Library: INVALID_PATH');
        amounts = new uint[](path.length);
        amounts[amounts.length - 1] = amountOut;
        for (uint i = path.length - 1; i > 0; i--) {
            (uint reserveIn, uint reserveOut) = getReserves(factory, path[i - 1], path[i]);
            amounts[i - 1] = getAmountIn(amounts[i], reserveIn, reserveOut);
        }
    }
}

contract Initializable {

  bool private initialized;
  bool private initializing;

  modifier initializer() {
    require(initializing || isConstructor() || !initialized, "Contract instance has already been initialized");

    bool wasInitializing = initializing;
    initializing = true;
    initialized = true;

    _;

    initializing = wasInitializing;
  }

  function isConstructor() private view returns (bool) {
    uint256 cs;
    assembly { cs := extcodesize(address) }
    return cs == 0;
  }

  uint256[50] private ______gap;
}

contract Ownable is Initializable {

  address private _owner;
  uint256 private _ownershipLocked;

  event OwnershipLocked(address lockedOwner);
  event OwnershipRenounced(address indexed previousOwner);
  event OwnershipTransferred(
    address indexed previousOwner,
    address indexed newOwner
  );


  function initialize(address sender) internal initializer {
    _owner = sender;
	_ownershipLocked = 0;
  }

  function owner() public view returns(address) {
    return _owner;
  }

  modifier onlyOwner() {
    require(isOwner());
    _;
  }

  function isOwner() public view returns(bool) {
    return msg.sender == _owner;
  }

  function transferOwnership(address newOwner) public onlyOwner {
    _transferOwnership(newOwner);
  }

  function _transferOwnership(address newOwner) internal {
    require(_ownershipLocked == 0);
    require(newOwner != address(0));
    emit OwnershipTransferred(_owner, newOwner);
    _owner = newOwner;
  }
  
  function lockOwnership() public onlyOwner {
	require(_ownershipLocked == 0);
	emit OwnershipLocked(_owner);
    _ownershipLocked = 1;
  }

  uint256[50] private ______gap;
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



library SafeMathInt {

    int256 private constant MIN_INT256 = int256(1) << 255;
    int256 private constant MAX_INT256 = ~(int256(1) << 255);

    function mul(int256 a, int256 b)
        internal
        pure
        returns (int256)
    {
        int256 c = a * b;

        // Detect overflow when multiplying MIN_INT256 with -1
        require(c != MIN_INT256 || (a & MIN_INT256) != (b & MIN_INT256));
        require((b == 0) || (c / b == a));
        return c;
    }

    function div(int256 a, int256 b)
        internal
        pure
        returns (int256)
    {
        // Prevent overflow when dividing MIN_INT256 by -1
        require(b != -1 || a != MIN_INT256);

        // Solidity already throws when dividing by 0.
        return a / b;
    }

    function sub(int256 a, int256 b)
        internal
        pure
        returns (int256)
    {
        int256 c = a - b;
        require((b >= 0 && c <= a) || (b < 0 && c > a));
        return c;
    }

    function add(int256 a, int256 b)
        internal
        pure
        returns (int256)
    {
        int256 c = a + b;
        require((b >= 0 && c >= a) || (b < 0 && c < a));
        return c;
    }

    function abs(int256 a)
        internal
        pure
        returns (int256)
    {
        require(a != MIN_INT256);
        return a < 0 ? -a : a;
    }
}

library UInt256Lib {

    uint256 private constant MAX_INT256 = ~(uint256(1) << 255);

    /**
     * @dev Safely converts a uint256 to an int256.
     */
    function toInt256Safe(uint256 a)
        internal
        pure
        returns (int256)
    {
        require(a <= MAX_INT256);
        return int256(a);
    }
}

interface ITrend {

    event TransactionFailed(address indexed destination, uint index, bytes data);
    event LogRebase(uint256 indexed epoch, uint256 totalSupply);

    function rebase(int256 supplyDelta) external returns (uint256);
    function totalSupply() external view returns (uint256);
    function balanceOf(address who) external returns (uint256);

    function transfer(address to, uint256 value) external returns (bool);
    function allowance(address owner_, address spender) external returns (uint256);
    function transferFrom(address from, address to, uint256 value) external returns (bool);
    function approve(address spender, uint256 value) external returns (bool);
    function increaseAllowance(address spender, uint256 addedValue) external returns (bool);
    function decreaseAllowance(address spender, uint256 subtractedValue) external returns (bool);
    function addTransaction(address destination, bytes calldata data) external;
    function removeTransaction(uint index) external;
    function setTransactionEnabled(uint index, bool enabled) external;
    function transactionsSize() external returns (uint256);
    
    function transferOwnership(address newOwner) external;
    function lockOwnership() external;
    
}
contract Orchestrator is Ownable {
    using SafeMath for uint256;
    using SafeMathInt for int256;
    using UInt256Lib for uint256;

    event LogRebase(
        uint256 indexed epoch,
        uint256  lagFactor,
        uint256 totalSupply,
        uint256 price,
        int256 delta,
        uint256 timestampSec,
        uint rebaseId
    );

    ITrend private _trend;
    // Uniswap V2 Pairs fpr ETH-Trend 
	IUniswapV2Pair private _pairTrend;

    uint256 private _priceTarget;


    // The number of rebase cycles since inception
    uint256 public epoch;

    uint256 private constant DECIMALS = 18;
    uint256 private constant TREND_DECIMALS = 9;
    uint256 private constant ETH_DECIMALS = 18;
    uint256 private constant WEEK_FREQUENCY = 7 days;
    uint256 private constant MONTH_FREQUENCY = 30 days;
        
	uint256 private constant PRICE_PRECISION = 10**8;
    // Due to the expression in computeSupplyDelta(), MAX_RATE * MAX_SUPPLY must fit into an int256.
    // Both are 18 decimals fixed point numbers.
    uint256 private constant MAX_RATE = 10**6 * 10**DECIMALS;
    // MAX_SUPPLY = MAX_INT256 / MAX_RATE
    uint256 private constant MAX_SUPPLY = ~(uint256(1) << 255) / MAX_RATE;
    uint256 private next_monthly_round;
    uint256 private next_weekly_round;
    
    int256 private constant LAG_PRECISION = 10**2;

     struct Rebase {
        uint execution_time;
        bool executed;
        bool isMonthly;
    }

    mapping (uint => Rebase) private rebases;


	constructor() public {
	
		Ownable.initialize(msg.sender);
        epoch = 0;
        _priceTarget = 5 * 10**15;
        next_weekly_round = now + 1 days + WEEK_FREQUENCY;
        next_monthly_round = now + 1 days + MONTH_FREQUENCY;
        _trend = ITrend(address(0x0cC0d75340C0658eC370859252f40Ed92620A807));
        _pairTrend = IUniswapV2Pair(UniswapV2Library.pairFor(address(0x5C69bEe701ef814a2B6a3EDD4B1652CB9cc5aA6f ), address(0x0cC0d75340C0658eC370859252f40Ed92620A807) , address(0xC02aaA39b223FE8D0A0e5C4F27eAD9083C756Cc2)));
       
        rebases[0] = Rebase(getHashRandom(blockhash(block.number  - 1), now + 1 days, next_monthly_round),false,true);
       
        rebases[1] = Rebase(getHashRandom(blockhash(block.number - 2), now + 1 days, next_weekly_round),false,false);
        rebases[2] = Rebase(getHashRandom(blockhash(block.number - 3), now + 1 days, next_weekly_round),false,false);
        rebases[3] = Rebase(getHashRandom(blockhash(block.number - 4), now + 1 days, next_weekly_round),false,false);
        rebases[4] = Rebase(getHashRandom(blockhash(block.number - 5), now + 1 days, next_weekly_round),false,false);
    }



       
	function transferTrendOwner(address newOwner)
        external
        onlyOwner
    {
        require(address(_trend) != address(0));
        _trend.transferOwnership(newOwner);
    }

    function rebase()  external  returns (uint256) {

       
        (bool canRebase ,uint rebaseId) = getRebaseInfo();
        
        require(canRebase , "NO_REBASE_AVAILABLE");
        rebases[rebaseId].executed = true;
        epoch = epoch.add(1);

        bytes32 bhLast = blockhash(block.number - 1);

        require(address(_trend) != address(0));
        require(address(_pairTrend) != address(0));
        
        int256 supplyDelta = 0;
        uint256 totalSupply = _trend.totalSupply();
        uint256 price = getPriceTrend_ETH();

        
        supplyDelta = totalSupply.toInt256Safe().mul(price.toInt256Safe().sub(_priceTarget.toInt256Safe())).div(_priceTarget.toInt256Safe());
        
        if(rebases[rebaseId].isMonthly) supplyDelta = supplyDelta*2;

        uint256 lagFactor = getLagFactor(bhLast, totalSupply);
            		
        // Apply random lag factor
        
        supplyDelta = supplyDelta.mul(LAG_PRECISION).div(lagFactor.toInt256Safe());

        if (supplyDelta > 0 && totalSupply.add(uint256(supplyDelta)) > MAX_SUPPLY) {
            supplyDelta = (MAX_SUPPLY.sub(totalSupply)).toInt256Safe();
        }

        uint256 supplyAfterRebase = _trend.rebase(supplyDelta);
        assert(supplyAfterRebase <= MAX_SUPPLY);
        emit LogRebase(epoch,lagFactor,totalSupply, price, supplyDelta, block.timestamp , rebaseId);
        
        _pairTrend.sync();
        
        tryGenerateNextRebases();

        return supplyAfterRebase;
    }

    function getPriceTrend_ETH() public view returns (uint256) {
	    
	    require(address(_pairTrend) != address(0));
	 
	    (uint256 reserves0, uint256 reserves1,) = _pairTrend.getReserves();
	    
	    uint256 input_amount_with_fee = (1*10**TREND_DECIMALS).mul(997);
        uint256 numerator = input_amount_with_fee.mul(reserves1);
        uint256 denominator = reserves0.mul(1000).add(input_amount_with_fee);

        uint256 price = numerator.div(denominator);
        
        return price;
    }

	function getLagFactor(bytes32 hash, uint256 totalSupply) internal pure returns (uint256) {

	    uint256 supply10M = 10 * 10**6 * 10 ** TREND_DECIMALS;
        uint256 supply90M = 90 * 10**6 * 10 ** TREND_DECIMALS;
        
	    uint256 min = 1000;
	    uint256 max = 1400;
	    
	    if (totalSupply <= (10 * 10**6 * TREND_DECIMALS)) {
	        min = 600;
	    } else {
	        if (totalSupply >= (100 * 10**6 * TREND_DECIMALS)) {
	            min = 800;
	        } else {
                min = uint256(totalSupply.toInt256Safe().sub(supply10M.toInt256Safe()).mul(100).div(supply90M.toInt256Safe())) ** 2;
                min = min.mul(200).div(100 ** 2).add(600);
	        }
	    }

	    if (totalSupply <= (10 * 10**6 * TREND_DECIMALS)) {
	        max = 1000;
	    } else {
	        if (totalSupply >= (100 * 10**6 * TREND_DECIMALS)) {
	            max = 1400;
	        } else {
	            max = uint256(totalSupply.toInt256Safe().sub(supply10M.toInt256Safe()).mul(100).div(supply90M.toInt256Safe())) ** 2;
                max = max.mul(400).div(100 ** 2).add(800);
	        }
	    }
	    
        return getHashRandom(hash, min, max);
    }
        
    function getHashRandom(bytes32 hash, uint256 min, uint256 max) internal pure returns (uint256) {		
        uint256 hashInt = uint256(hash);
        uint256 randMod = hashInt % (max - min);
        return randMod + min;
    }

    function getRebaseInfo() internal view returns (bool,uint) {		
        
        bool canRebase = false;
        uint id = 0;
        
    
       for (uint i = 0; i < 5; i++) { 

           if(rebases[i].execution_time < now && !rebases[i].executed){
                canRebase = true;
                id = i;
                break;
           }
       }

       return (canRebase,id);
    }
    
    function getCurrentSupply() public view returns (uint256){
        return _trend.totalSupply();
    }
    
    function getCurrentRebases() public view returns (uint[] memory,uint256[] memory, bool[] memory){
        
        uint[] memory ids = new uint[](5) ;
        uint256[] memory times = new uint256[](5) ;
        bool[] memory executed = new bool[](5) ;
        
        for (uint i = 0; i < 5; i++) { 
            ids[i] = i;
            times[i] = rebases[i].execution_time;
            executed[i] = rebases[i].executed;
            
        }
        return (ids,times,executed);
    }
    
    function tryGenerateNextRebases() internal {
    
         if(now > next_monthly_round || rebases[0].executed){
       
            rebases[0].execution_time = getHashRandom(blockhash(block.number - 1), next_monthly_round, next_monthly_round + MONTH_FREQUENCY);
            rebases[0].executed = false;
            next_monthly_round = next_monthly_round + MONTH_FREQUENCY;
        }
        
        if(now > next_weekly_round || (rebases[1].executed && rebases[2].executed && rebases[3].executed && rebases[4].executed)){
            
            rebases[1].execution_time = getHashRandom(blockhash(block.number - 2), next_weekly_round, next_weekly_round + WEEK_FREQUENCY);
            rebases[2].execution_time = getHashRandom(blockhash(block.number - 3), next_weekly_round, next_weekly_round + WEEK_FREQUENCY);
            rebases[3].execution_time = getHashRandom(blockhash(block.number - 4), next_weekly_round, next_weekly_round + WEEK_FREQUENCY);
            rebases[4].execution_time = getHashRandom(blockhash(block.number - 5), next_weekly_round, next_weekly_round + WEEK_FREQUENCY);
            rebases[1].executed = false;
            rebases[2].executed = false;
            rebases[3].executed = false;
            rebases[4].executed = false;
            
            next_weekly_round = next_weekly_round + WEEK_FREQUENCY;
        }
        
    }
}