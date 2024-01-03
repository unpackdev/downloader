// File: @openzeppelin/contracts/token/ERC20/IERC20.sol


pragma solidity ^0.6.0;

/**
 * @dev Interface of the ERC20 standard as defined in the EIP.
 */
interface IERC20 {
    /**
     * @dev Returns the amount of tokens in existence.
     */
    function totalSupply() external view returns (uint256);

    /**
     * @dev Returns the amount of tokens owned by `account`.
     */
    function balanceOf(address account) external view returns (uint256);

    /**
     * @dev Moves `amount` tokens from the caller's account to `recipient`.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transfer(address recipient, uint256 amount) external returns (bool);

    /**
     * @dev Returns the remaining number of tokens that `spender` will be
     * allowed to spend on behalf of `owner` through {transferFrom}. This is
     * zero by default.
     *
     * This value changes when {approve} or {transferFrom} are called.
     */
    function allowance(address owner, address spender) external view returns (uint256);

    /**
     * @dev Sets `amount` as the allowance of `spender` over the caller's tokens.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * IMPORTANT: Beware that changing an allowance with this method brings the risk
     * that someone may use both the old and the new allowance by unfortunate
     * transaction ordering. One possible solution to mitigate this race
     * condition is to first reduce the spender's allowance to 0 and set the
     * desired value afterwards:
     * https://github.com/ethereum/EIPs/issues/20#issuecomment-263524729
     *
     * Emits an {Approval} event.
     */
    function approve(address spender, uint256 amount) external returns (bool);

    /**
     * @dev Moves `amount` tokens from `sender` to `recipient` using the
     * allowance mechanism. `amount` is then deducted from the caller's
     * allowance.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);

    /**
     * @dev Emitted when `value` tokens are moved from one account (`from`) to
     * another (`to`).
     *
     * Note that `value` may be zero.
     */
    event Transfer(address indexed from, address indexed to, uint256 value);

    /**
     * @dev Emitted when the allowance of a `spender` for an `owner` is set by
     * a call to {approve}. `value` is the new allowance.
     */
    event Approval(address indexed owner, address indexed spender, uint256 value);
}

// File: @openzeppelin/contracts/GSN/Context.sol



pragma solidity ^0.6.0;

/*
 * @dev Provides information about the current execution context, including the
 * sender of the transaction and its data. While these are generally available
 * via msg.sender and msg.data, they should not be accessed in such a direct
 * manner, since when dealing with GSN meta-transactions the account sending and
 * paying for execution may not be the actual sender (as far as an application
 * is concerned).
 *
 * This contract is only required for intermediate, library-like contracts.
 */
abstract contract Context {
    function _msgSender() internal view virtual returns (address payable) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes memory) {
        this; // silence state mutability warning without generating bytecode - see https://github.com/ethereum/solidity/issues/2691
        return msg.data;
    }
}

// File: @openzeppelin/contracts/access/Ownable.sol



pragma solidity ^0.6.0;

/**
 * @dev Contract module which provides a basic access control mechanism, where
 * there is an account (an owner) that can be granted exclusive access to
 * specific functions.
 *
 * By default, the owner account will be the one that deploys the contract. This
 * can later be changed with {transferOwnership}.
 *
 * This module is used through inheritance. It will make available the modifier
 * `onlyOwner`, which can be applied to your functions to restrict their use to
 * the owner.
 */
contract Ownable is Context {
    address private _owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    /**
     * @dev Initializes the contract setting the deployer as the initial owner.
     */
    constructor () internal {
        address msgSender = _msgSender();
        _owner = msgSender;
        emit OwnershipTransferred(address(0), msgSender);
    }

    /**
     * @dev Returns the address of the current owner.
     */
    function owner() public view returns (address) {
        return _owner;
    }

    /**
     * @dev Throws if called by any account other than the owner.
     */
    modifier onlyOwner() {
        require(_owner == _msgSender(), "Ownable: caller is not the owner");
        _;
    }

    /**
     * @dev Leaves the contract without owner. It will not be possible to call
     * `onlyOwner` functions anymore. Can only be called by the current owner.
     *
     * NOTE: Renouncing ownership will leave the contract without an owner,
     * thereby removing any functionality that is only available to the owner.
     */
    function renounceOwnership() public virtual onlyOwner {
        emit OwnershipTransferred(_owner, address(0));
        _owner = address(0);
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Can only be called by the current owner.
     */
    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        emit OwnershipTransferred(_owner, newOwner);
        _owner = newOwner;
    }
}

// File: contracts/navtracker/interfaces/IC8LPStaking.sol

pragma solidity ^0.6.12;

interface IC8LPStaking {
  function announceReward(uint256 _reward) external returns (bool);
}

// File: contracts/navtracker/interfaces/IC8PNAVTracker.sol

pragma solidity ^0.6.12;

interface IC8PNAVTracker {
  function updateReward() external returns (bool);

  function getStakingRewardNow() external view returns (uint256);
}

// File: contracts/navtracker/interfaces/IUniswapV2Pair.sol

pragma solidity >=0.5.0;

interface IUniswapV2Pair {
  function balanceOf(address owner) external view returns (uint);

  function getReserves() external view returns (uint112 reserve0, uint112 reserve1, uint32 blockTimestampLast);

  function totalSupply() external view returns (uint);
}

// File: contracts/navtracker/libraries/SafeMath.sol

pragma solidity >=0.5.16;

// a library for performing overflow-safe math, courtesy of DappHub (https://github.com/dapphub/ds-math)

library SafeMath {
  function add(uint x, uint y) internal pure returns (uint z) {
    require((z = x + y) >= x, 'ds-math-add-overflow');
  }

  function sub(uint x, uint y) internal pure returns (uint z) {
    require((z = x - y) <= x, 'ds-math-sub-underflow');
  }

  function mul(uint x, uint y) internal pure returns (uint z) {
    require(y == 0 || (z = x * y) / y == x, 'ds-math-mul-overflow');
  }
}

// File: contracts/navtracker/libraries/UniswapV2Library.sol

pragma solidity >=0.5.0;



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

// File: contracts/navtracker/libraries/Math.sol

pragma solidity >=0.5.16;

// a library for performing various math operations

library Math {
  function min(uint x, uint y) internal pure returns (uint z) {
    z = x < y ? x : y;
  }

  // babylonian method (https://en.wikipedia.org/wiki/Methods_of_computing_square_roots#Babylonian_method)
  function sqrt(uint y) internal pure returns (uint z) {
    if (y > 3) {
      z = y;
      uint x = y / 2 + 1;
      while (x < z) {
        z = x;
        x = (y / x + x) / 2;
      }
    } else if (y != 0) {
      z = 1;
    }
  }
}

// File: contracts/navtracker/C8PNAVTracker.sol

// SPDX-License-Identifier: UNLICENSED

pragma solidity ^0.6.12;









contract C8PNAVTracker is Ownable, IC8PNAVTracker {
  using SafeMath for uint;

  address public UNISWAP_POOL;
  address public CUSTODIAN;
  address public C8P_TOKEN;
  address public USDC_TOKEN;
  address public USDT_TOKEN;
  address public STAKING_CONTRACT;

  uint private FEE_ACCUMULATED_TOKEN0;
  uint private FEE_ACCUMULATED_TOKEN1;
  uint private PREV_RESERVE_TOKEN0;
  uint private PREV_RESERVE_TOKEN1;
  uint private constant CONVERTER = 10 ** 6;
  uint32 PREV_BLOCK_TIMESTAMP;

  event UpdateReward(
    uint prev_reserve_token0,
    uint prev_reserve_token1,
    uint now_reserve_token0,
    uint now_reserve_token1,
    uint fee_for_stake_token0,
    uint fee_for_stake_token1,
    uint reward_total,
    uint32 blockTimestampLast
  );

  event UpdateKValue(
    uint prev_reserve_token0,
    uint prev_reserve_token1,
    uint now_reserve_token0,
    uint now_reserve_token1,
    uint32 blockTimestampLast
  );

  event ResetFeeAccumulated(
    uint current_fee_accumulated_token0,
    uint current_fee_accumulated_token1
  );

  bool private _stakingEnabled;

  modifier onlyStakingContract() {
    require(msg.sender == address(STAKING_CONTRACT), "NAV Tracker: caller is not the staking contract");
    _;
  }

  constructor (address _pool, address _custodian, address _c8p_token, address _usdc_token, address _usdt_token, uint _reserve0, uint _reserve1) public {
    UNISWAP_POOL = _pool;
    CUSTODIAN = _custodian;
    C8P_TOKEN = _c8p_token;
    USDC_TOKEN = _usdc_token;
    USDT_TOKEN = _usdt_token;
    FEE_ACCUMULATED_TOKEN0 = 0;
    FEE_ACCUMULATED_TOKEN1 = 0;
    PREV_RESERVE_TOKEN0 = _reserve0;
    PREV_RESERVE_TOKEN1 = _reserve1;
    PREV_BLOCK_TIMESTAMP = uint32(block.timestamp % 2 ** 32);
    emit UpdateKValue(0, 0, PREV_RESERVE_TOKEN0, PREV_RESERVE_TOKEN1, PREV_BLOCK_TIMESTAMP);

    STAKING_CONTRACT = address(0);
    _stakingEnabled = false;
  }

  function updateStakingContract(address stakingContract) external onlyOwner {
    STAKING_CONTRACT = stakingContract;
    _stakingEnabled = true;
  }

  function convertToUSDT(uint _usdcTokenIn) public view returns (uint usdtTokenOut) {
    IUniswapV2Pair pool = IUniswapV2Pair(UNISWAP_POOL);
    (uint usdcReserved, uint usdtReserved,) = pool.getReserves();
    if (usdcReserved == 0 || usdtReserved == 0 || _usdcTokenIn == 0) {
      return 0;
    }
    return UniswapV2Library.getAmountOut(_usdcTokenIn, usdcReserved, usdtReserved);
  }

  function reserve_token_previous() public view returns (uint token0, uint token1, uint32 blockTimestamp) {
    token0 = PREV_RESERVE_TOKEN0;
    token1 = PREV_RESERVE_TOKEN1;
    blockTimestamp = PREV_BLOCK_TIMESTAMP;
  }

  function reserve_token_now() public view returns (uint token0, uint token1, uint32 blockTimestamp) {
    (uint reserve0, uint reserve1, uint32 blockTimestampLast) = tokenInPool(CUSTODIAN, UNISWAP_POOL);
    token0 = reserve0;
    token1 = reserve1;
    blockTimestamp = blockTimestampLast;
  }

  function fee_accumulated() public view returns (uint token0, uint token1) {
    token0 = FEE_ACCUMULATED_TOKEN0;
    token1 = FEE_ACCUMULATED_TOKEN1;
  }

  function feeAccrued(
    uint _prev_reserve0,
    uint _prev_reserve1,
    uint _now_reserve0,
    uint _now_reserve1) public pure returns (
    uint feePortion
  ) {
    feePortion = 0;
    if (_prev_reserve0 * _prev_reserve1 < _now_reserve0 * _now_reserve1) {
      feePortion = (1 * CONVERTER) - (Math.sqrt(_prev_reserve0.mul(_prev_reserve1)) * CONVERTER / Math.sqrt(_now_reserve0.mul(_now_reserve1)));
    }
  }

  function _adjustReserve(
    uint _reserve,
    uint _fee_accumulated
  ) private pure returns (
    uint reserveAdjusted
  ){
    reserveAdjusted = _reserve;
    if (_reserve > _fee_accumulated) {
      reserveAdjusted = _reserve.sub(_fee_accumulated);
    }
  }

  function tokenInPool(
    address _custodian,
    address _uniswap_pool
  ) public view returns (
    uint balance_token0,
    uint balance_token1,
    uint32 blockTimestampLast
  ) {
    IUniswapV2Pair pool = IUniswapV2Pair(_uniswap_pool);
    uint share = pool.balanceOf(_custodian);
    uint totalShares = pool.totalSupply();
    if (share == 0) {
      return (0, 0, uint32(block.timestamp % 2 ** 32));
    }
    (uint reserve0, uint reserve1, uint32 _blockTimestampLast) = pool.getReserves();
    balance_token0 = share.mul(reserve0) / totalShares;
    balance_token1 = share.mul(reserve1) / totalShares;
    blockTimestampLast = _blockTimestampLast;
  }

  function NAV() public view returns (
    uint navAdjusted,
    uint feeForStake,
    uint32 blockTimestampLast
  ) {
    (uint reserve0, uint reserve1, uint32 _blockTimestampLast) = tokenInPool(CUSTODIAN, UNISWAP_POOL);
    (navAdjusted, feeForStake) = calculateNAV(
      PREV_RESERVE_TOKEN0,
      PREV_RESERVE_TOKEN1,
      FEE_ACCUMULATED_TOKEN0,
      FEE_ACCUMULATED_TOKEN1,
      IERC20(C8P_TOKEN).totalSupply(),
      reserve0,
      reserve1
    );
    blockTimestampLast = _blockTimestampLast;
  }

  function calculateNAV(
    uint _prev_reserve0,
    uint _prev_reserve1,
    uint _fee_accumulated_token0,
    uint _fee_accumulated_token1,
    uint _units,
    uint _reserve0,
    uint _reserve1
  ) public view returns (
    uint navAdjusted,
    uint feeForStake_USDT
  ) {
    if (_reserve0 == 0 && _reserve1 == 0) {
      return (0, 0);
    }

    _prev_reserve0 = _adjustReserve(_prev_reserve0, _fee_accumulated_token0);
    _prev_reserve1 = _adjustReserve(_prev_reserve1, _fee_accumulated_token1);
    _reserve0 = _adjustReserve(_reserve0, _fee_accumulated_token0);
    _reserve1 = _adjustReserve(_reserve1, _fee_accumulated_token1);

    uint feePortion = feeAccrued(_prev_reserve0, _prev_reserve1, _reserve0, _reserve1);
    uint feePortionForStake = feePortion / 2;
    uint totalReserve = _reserve1.add(_reserve0);
    uint totalReserve_USDT = _reserve1.add(convertToUSDT(_reserve0));
    navAdjusted = (CONVERTER - feePortionForStake).mul(totalReserve) / _units;
    feeForStake_USDT = feePortionForStake.mul(totalReserve_USDT) / CONVERTER;
  }

  function getStakingRewardNow() public virtual override view returns (uint USDT) {
    //    (uint _navAdjusted, uint _feeForStake, uint32 _blockTimestampLast) = NAV();
    (, uint _feeForStake,) = NAV();
    USDT = _feeForStake;
  }

  function updateReward() external virtual override onlyStakingContract returns (bool updated){
    updated = false;
    (uint reserve0, uint reserve1, uint32 blockTimestampLast) = tokenInPool(CUSTODIAN, UNISWAP_POOL);
    uint feePortion = feeAccrued(
      _adjustReserve(PREV_RESERVE_TOKEN0, FEE_ACCUMULATED_TOKEN0),
      _adjustReserve(PREV_RESERVE_TOKEN1, FEE_ACCUMULATED_TOKEN1),
      _adjustReserve(reserve0, FEE_ACCUMULATED_TOKEN0),
      _adjustReserve(reserve1, FEE_ACCUMULATED_TOKEN1)
    );
    uint feePortionForStake = feePortion / 2;
    uint feeForStakeToken0 = feePortionForStake.mul(_adjustReserve(reserve0, FEE_ACCUMULATED_TOKEN0)) / CONVERTER;
    uint feeForStakeToken1 = feePortionForStake.mul(_adjustReserve(reserve1, FEE_ACCUMULATED_TOKEN1)) / CONVERTER;
    uint feeForStake_USDT = feeForStakeToken1.add(convertToUSDT(feeForStakeToken0));

    require(feeForStakeToken0 > 0 && feeForStakeToken1 > 0, 'NAV Tracker: no reward');

    IC8LPStaking stakeContract = IC8LPStaking(STAKING_CONTRACT);
    if (stakeContract.announceReward(feeForStake_USDT)) {
      FEE_ACCUMULATED_TOKEN0 = FEE_ACCUMULATED_TOKEN0.add(feeForStakeToken0);
      FEE_ACCUMULATED_TOKEN1 = FEE_ACCUMULATED_TOKEN1.add(feeForStakeToken1);
      PREV_BLOCK_TIMESTAMP = blockTimestampLast;
      updated = true;
      emit UpdateReward(
        PREV_RESERVE_TOKEN0,
        PREV_RESERVE_TOKEN1,
        reserve0,
        reserve1,
        feeForStakeToken0,
        feeForStakeToken1,
        feeForStake_USDT,
        blockTimestampLast
      );
      PREV_RESERVE_TOKEN0 = reserve0;
      PREV_RESERVE_TOKEN1 = reserve1;
    }
  }

  function updateLatestK() external onlyOwner returns (bool updated){
    updated = false;
    (uint reserve0, uint reserve1, uint32 blockTimestampLast) = tokenInPool(CUSTODIAN, UNISWAP_POOL);
    require(PREV_RESERVE_TOKEN0 != reserve0 && PREV_RESERVE_TOKEN1 != reserve1, 'NAV Tracker: K is not changed');
    PREV_BLOCK_TIMESTAMP = blockTimestampLast;
    updated = true;
    emit UpdateKValue(
      PREV_RESERVE_TOKEN0,
      PREV_RESERVE_TOKEN1,
      reserve0,
      reserve1,
      blockTimestampLast
    );
    PREV_RESERVE_TOKEN0 = reserve0;
    PREV_RESERVE_TOKEN1 = reserve1;
  }

  function resetFeeAccumulated() external onlyOwner {
    require(FEE_ACCUMULATED_TOKEN0 > 0 && FEE_ACCUMULATED_TOKEN1 > 0, "NAV Tracker: Fee accumulated not enough");
    emit ResetFeeAccumulated(FEE_ACCUMULATED_TOKEN0, FEE_ACCUMULATED_TOKEN1);
    FEE_ACCUMULATED_TOKEN0 = 0;
    FEE_ACCUMULATED_TOKEN1 = 0;
  }
}