// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface IERC20 {
    function totalSupply() external view returns (uint256);
    function decimals() external view returns (uint256);
    function balanceOf(address account) external view returns (uint256);
    function transfer(address recipient, uint256 amount) external returns (bool);
    function allowance(address owner, address spender) external view returns (uint256);
    function approve(address spender, uint256 amount) external returns (bool);
    function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);
    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(address indexed owner, address indexed spender, uint256 value);
}

library Address {
    function isContract(address account) internal view returns (bool) {
        bytes32 codehash;
        bytes32 accountHash = 0xc5d2460186f7233c927e7db2dcc703c0e500b653ca82273b7bfad8045d85a470;
        // solhint-disable-next-line no-inline-assembly
        assembly { codehash := extcodehash(account) }
        return (codehash != 0x0 && codehash != accountHash);
    }
}

library SafeERC20 {
    using Address for address;

    function safeTransfer(IERC20 token, address to, uint value) internal {
        callOptionalReturn(token, abi.encodeWithSelector(token.transfer.selector, to, value));
    }

    function safeTransferFrom(IERC20 token, address from, address to, uint value) internal {
        callOptionalReturn(token, abi.encodeWithSelector(token.transferFrom.selector, from, to, value));
    }

    function safeApprove(IERC20 token, address spender, uint value) internal {
        require((value == 0) || (token.allowance(address(this), spender) == 0),
            "SafeERC20: approve from non-zero to non-zero allowance"
        );
        callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, value));
    }
    function callOptionalReturn(IERC20 token, bytes memory data) private {
        require(address(token).isContract(), "SafeERC20: call to non-contract");

        // solhint-disable-next-line avoid-low-level-calls
        (bool success, bytes memory returndata) = address(token).call(data);
        require(success, "SafeERC20: low-level call failed");

        if (returndata.length > 0) { // Return data is optional
            // solhint-disable-next-line max-line-length
            require(abi.decode(returndata, (bool)), "SafeERC20: ERC20 operation did not succeed");
        }
    }
}

interface Oracle {
    function getPriceUSD(address reserve) external view returns (uint);
}

interface ISushiswapV2Factory {
    event PairCreated(address indexed token0, address indexed token1, address pair, uint);

    function feeTo() external view returns (address);
    function feeToSetter() external view returns (address);

    function getPair(address tokenA, address tokenB) external view returns (address pair);
    function allPairs(uint) external view returns (address pair);
    function allPairsLength() external view returns (uint);

    function createPair(address tokenA, address tokenB) external returns (address pair);

    function setFeeTo(address) external;
    function setFeeToSetter(address) external;
}

interface ISushiswapV2Pair {
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

/**
 * @dev Contract module that helps prevent reentrant calls to a function.
 *
 * Inheriting from `ReentrancyGuard` will make the {nonReentrant} modifier
 * available, which can be applied to functions to make sure there are no nested
 * (reentrant) calls to them.
 *
 * Note that because there is a single `nonReentrant` guard, functions marked as
 * `nonReentrant` may not call one another. This can be worked around by making
 * those functions `private`, and then adding `external` `nonReentrant` entry
 * points to them.
 *
 * TIP: If you would like to learn more about reentrancy and alternative ways
 * to protect against it, check out our blog post
 * https://blog.openzeppelin.com/reentrancy-after-istanbul/[Reentrancy After Istanbul].
 */
abstract contract ReentrancyGuard {
    // Booleans are more expensive than uint256 or any type that takes up a full
    // word because each write operation emits an extra SLOAD to first read the
    // slot's contents, replace the bits taken up by the boolean, and then write
    // back. This is the compiler's defense against contract upgrades and
    // pointer aliasing, and it cannot be disabled.

    // The values being non-zero value makes deployment a bit more expensive,
    // but in exchange the refund on every call to nonReentrant will be lower in
    // amount. Since refunds are capped to a percentage of the total
    // transaction's gas, it is best to keep them low in cases like this one, to
    // increase the likelihood of the full refund coming into effect.
    uint256 private constant _NOT_ENTERED = 1;
    uint256 private constant _ENTERED = 2;

    uint256 private _status;

    constructor () {
        _status = _NOT_ENTERED;
    }

    /**
     * @dev Prevents a contract from calling itself, directly or indirectly.
     * Calling a `nonReentrant` function from another `nonReentrant`
     * function is not supported. It is possible to prevent this from happening
     * by making the `nonReentrant` function external, and make it call a
     * `private` function that does the actual work.
     */
    modifier nonReentrant() {
        // On the first call to nonReentrant, _notEntered will be true
        require(_status != _ENTERED, "ReentrancyGuard: reentrant call");

        // Any calls to nonReentrant after this point will fail
        _status = _ENTERED;

        _;

        // By storing the original value once again, a refund is triggered (see
        // https://eips.ethereum.org/EIPS/eip-2200)
        _status = _NOT_ENTERED;
    }
}



library SushiswapV2Library {
    // returns sorted token addresses, used to handle return values from pairs sorted in this order
    function sortTokens(address tokenA, address tokenB) internal pure returns (address token0, address token1) {
        require(tokenA != tokenB, 'SushiswapV2Library: IDENTICAL_ADDRESSES');
        (token0, token1) = tokenA < tokenB ? (tokenA, tokenB) : (tokenB, tokenA);
        require(token0 != address(0), 'SushiswapV2Library: ZERO_ADDRESS');
    }

    // calculates the CREATE2 address for a pair without making any external calls
    function pairFor(address factory, address tokenA, address tokenB) internal pure returns (address pair) {
        (address token0, address token1) = sortTokens(tokenA, tokenB);
        pair = address(uint160(uint(keccak256(abi.encodePacked(
                hex'ff',
                factory,
                keccak256(abi.encodePacked(token0, token1)),
                hex'e18a34eb0e04b04f7a0ac29a6e80748dca96319b42c54d679cb821dca90c6303' // init code hash
            )))));
    }

    // fetches and sorts the reserves for a pair
    function getReserves(address factory, address tokenA, address tokenB) internal view returns (uint reserveA, uint reserveB) {
        (address token0,) = sortTokens(tokenA, tokenB);
        (uint reserve0, uint reserve1,) = ISushiswapV2Pair(pairFor(factory, tokenA, tokenB)).getReserves();
        (reserveA, reserveB) = tokenA == token0 ? (reserve0, reserve1) : (reserve1, reserve0);
    }

    // given some amount of an asset and pair reserves, returns an equivalent amount of the other asset
    function quote(uint amountA, uint reserveA, uint reserveB) internal pure returns (uint amountB) {
        require(amountA > 0, 'SushiswapV2Library: INSUFFICIENT_AMOUNT');
        require(reserveA > 0 && reserveB > 0, 'SushiswapV2Library: INSUFFICIENT_LIQUIDITY');
        amountB = amountA * reserveB / reserveA;
    }
}

/**
 * @dev Standard math utilities missing in the Solidity language.
 */
library Math {
    /**
     * @dev Returns the largest of two numbers.
     */
    function max(uint256 a, uint256 b) internal pure returns (uint256) {
        return a >= b ? a : b;
    }

    /**
     * @dev Returns the smallest of two numbers.
     */
    function min(uint256 a, uint256 b) internal pure returns (uint256) {
        return a < b ? a : b;
    }

    /**
     * @dev Returns the average of two numbers. The result is rounded towards
     * zero.
     */
    function average(uint256 a, uint256 b) internal pure returns (uint256) {
        // (a + b) / 2 can overflow, so we distribute
        return (a / 2) + (b / 2) + ((a % 2 + b % 2) / 2);
    }
}

contract StableYieldCredit is ReentrancyGuard {
    using SafeERC20 for IERC20;

    /// @notice EIP-20 token name for this token
    string public constant name = "Stable Yield Credit";

    /// @notice EIP-20 token symbol for this token
    string public constant symbol = "xiii";

    /// @notice EIP-20 token decimals for this token
    uint8 public constant decimals = 8;

    /// @notice Total number of tokens in circulation
    uint public totalSupply = 0;
    
    /// @notice Total number of tokens staked for yield
    uint public stakedSupply = 0;

    mapping(address => mapping (address => uint)) internal allowances;
    mapping(address => uint) internal balances;
    mapping(address => uint) public stakes;

    /// @notice The EIP-712 typehash for the contract's domain
    bytes32 public constant DOMAIN_TYPEHASH = keccak256("EIP712Domain(string name,uint chainId,address verifyingContract)");
    bytes32 public immutable DOMAINSEPARATOR;

    /// @notice The EIP-712 typehash for the permit struct used by the contract
    bytes32 public constant PERMIT_TYPEHASH = keccak256("Permit(address owner,address spender,uint value,uint nonce,uint deadline)");

    /// @notice A record of states for signing / validating signatures
    mapping (address => uint) public nonces;

    function safe32(uint n, string memory errorMessage) internal pure returns (uint32) {
        require(n < 2**32, errorMessage);
        return uint32(n);
    }

    /// @notice The standard EIP-20 transfer event
    event Transfer(address indexed from, address indexed to, uint amount);
    
    /// @notice Stake event for claiming rewards
    event Staked(address indexed from, uint amount);
    
    // @notice Unstake event
    event Unstaked(address indexed from, uint amount);
    
    event Earned(address indexed from, uint amount);
    event Fees(uint amount);

    /// @notice The standard EIP-20 approval event
    event Approval(address indexed owner, address indexed spender, uint amount);

    // Oracle used for price debt data (external to the AMM balance to avoid internal manipulation)
    Oracle public constant LINK = Oracle(0x271bf4568fb737cc2e6277e9B1EE0034098cDA2a);
    ISushiswapV2Factory public constant FACTORY = ISushiswapV2Factory(0xC0AEe478e3658e2610c5F7A4A2E1777cE9e4f2Ac);
    
    
    
    // user => token => borrowed
    mapping (address => mapping(address => uint)) public borrowed;
    // user => token => collateral
    mapping (address => mapping(address => uint)) public collateral;
    // user => token => credit
    mapping (address => mapping(address => uint)) public collateralCredit;
    
    address[] private _markets;
    mapping (address => bool) pairs;
    
    uint public rewardRate = 0;
    uint public periodFinish = 0;
    uint public DURATION = 7 days;
    uint public lastUpdateTime;
    uint public rewardPerTokenStored;
    
    mapping(address => uint) public userRewardPerTokenPaid;
    mapping(address => uint) public rewards;
    
    event Deposit(address indexed creditor, address indexed collateral, uint creditOut, uint amountIn, uint creditMinted);
    event Withdraw(address indexed creditor, address indexed collateral, uint creditIn, uint creditOut, uint amountOut);
    
    constructor () {
        DOMAINSEPARATOR = keccak256(abi.encode(DOMAIN_TYPEHASH, keccak256(bytes(name)), _getChainId(), address(this)));
    }
    
    uint public FEE = 200;
    
    function lastTimeRewardApplicable() public view returns (uint) {
        return Math.min(block.timestamp, periodFinish);
    }
    
    function rewardPerToken() public view returns (uint) {
        if (stakedSupply == 0) {
            return rewardPerTokenStored;
        }
        return
            rewardPerTokenStored +
                ((lastTimeRewardApplicable() - 
                lastUpdateTime) * 
                rewardRate * 1e18 / stakedSupply);
    }
    
    function earned(address account) public view returns (uint) {
        return (stakes[account] * (rewardPerToken() - userRewardPerTokenPaid[account]) / 1e18) + rewards[account];
    }

    function getRewardForDuration() external view returns (uint) {
        return rewardRate * DURATION;
    }
    
    modifier updateReward(address account) {
        rewardPerTokenStored = rewardPerToken();
        lastUpdateTime = lastTimeRewardApplicable();
        if (account != address(0)) {
            rewards[account] = earned(account);
            userRewardPerTokenPaid[account] = rewardPerTokenStored;
        }
        _;
    }
    
    function stake(uint256 amount) external nonReentrant updateReward(msg.sender) {
        require(amount > 0, "Cannot stake 0");
        stakedSupply += amount;
        stakes[msg.sender] += amount;
        _transferTokens(msg.sender, address(this), amount);
        emit Staked(msg.sender, amount);
    }

    function unstake(uint amount) public nonReentrant updateReward(msg.sender) {
        require(amount > 0, "Cannot withdraw 0");
        stakedSupply -= amount;
        stakes[msg.sender] -= amount;
        _transferTokens(address(this), msg.sender, amount);
        emit Unstaked(msg.sender, amount);
    }

    function getReward() public nonReentrant updateReward(msg.sender) {
        uint256 reward = rewards[msg.sender];
        if (reward > 0) {
            rewards[msg.sender] = 0;
            _transferTokens(address(this), msg.sender, reward);
            emit Earned(msg.sender, reward);
        }
    }

    function exit() external {
        unstake(stakes[msg.sender]);
        getReward();
    }
    
    function notifyFeeAmount(uint reward) internal updateReward(address(0)) {
        if (block.timestamp >= periodFinish) {
            rewardRate = reward / DURATION;
        } else {
            uint remaining = periodFinish - block.timestamp;
            uint leftover = remaining * rewardRate;
            rewardRate = (reward + leftover) / DURATION;
        }

        // Ensure the provided reward amount is not more than the balance in the contract.
        // This keeps the reward rate in the right range, preventing overflows due to
        // very high values of rewardRate in the earned and rewardsPerToken functions;
        // Reward + leftover must be less than 2^256 / 10^18 to avoid overflow.
        uint balance = balances[address(this)];
        require(rewardRate <= balance / DURATION, "Provided reward too high");

        lastUpdateTime = block.timestamp;
        periodFinish = block.timestamp + DURATION;
        emit Fees(reward);
    }
    
    function markets() external view returns (address[] memory) {
        return _markets;
    }
    
    function _mint(address dst, uint amount) internal {
        // mint the amount
        totalSupply += amount;
        // transfer the amount to the recipient
        balances[dst] += amount;
        emit Transfer(address(0), dst, amount);
    }
    
    function _burn(address dst, uint amount) internal {
        // burn the amount
        totalSupply -= amount;
        // transfer the amount from the recipient
        balances[dst] -= amount;
        emit Transfer(dst, address(0), amount);
    }
    
    function depositAll(IERC20 token, uint minOut, uint minLiquidity) external {
        _deposit(token, token.balanceOf(msg.sender), minOut, minLiquidity);
    }
    
    function deposit(IERC20 token, uint amount, uint minOut, uint minLiquidity) external {
        _deposit(token, amount, minOut, minLiquidity);
    }
    
    function _calcLiquidity(address tokenA, address tokenB, uint amountADesired, uint amountBDesired) internal view returns (uint amountA, uint amountB) {
        (uint reserveA, uint reserveB) = SushiswapV2Library.getReserves(address(FACTORY), tokenA, tokenB);
        if (reserveA == 0 && reserveB == 0) {
            (amountA, amountB) = (amountADesired, amountBDesired);
        } else {
            uint amountBOptimal = SushiswapV2Library.quote(amountADesired, reserveA, reserveB);
            if (amountBOptimal <= amountBDesired) {
                (amountA, amountB) = (amountADesired, amountBOptimal);
            } else {
                uint amountAOptimal = SushiswapV2Library.quote(amountBDesired, reserveB, reserveA);
                assert(amountAOptimal <= amountADesired);
                (amountA, amountB) = (amountAOptimal, amountBDesired);
            }
        }
    }
    
    function _addLiquidity(address tokenA, address tokenB, uint amountADesired, uint amountBDesired) internal returns (address pair, uint amountA, uint amountB) {
        // create the pair if it doesn't exist yet
        pair = FACTORY.getPair(tokenA, tokenB);
        if (pair == address(0)) {
            pair = FACTORY.createPair(tokenA, tokenB);
            pairs[pair] = true;
            _markets.push(tokenA);
        } else if (!pairs[pair]) {
            pairs[pair] = true;
            _markets.push(tokenA);
        }
        
        (uint reserveA, uint reserveB) = SushiswapV2Library.getReserves(address(FACTORY), tokenA, tokenB);
        if (reserveA == 0 && reserveB == 0) {
            (amountA, amountB) = (amountADesired, amountBDesired);
        } else {
            uint amountBOptimal = SushiswapV2Library.quote(amountADesired, reserveA, reserveB);
            if (amountBOptimal <= amountBDesired) {
                (amountA, amountB) = (amountADesired, amountBOptimal);
            } else {
                uint amountAOptimal = SushiswapV2Library.quote(amountBDesired, reserveB, reserveA);
                assert(amountAOptimal <= amountADesired);
                (amountA, amountB) = (amountAOptimal, amountBDesired);
            }
        }
    }
    
    function pairFor(address token) public view returns (address) {
        return FACTORY.getPair(token, address(this));
    }
    
    function credit(IERC20 token, uint amount) external view returns (uint) {
        return LINK.getPriceUSD(address(token)) * amount / uint(10)**token.decimals();
    }
    
    function calcCollateralValue(address token) public view returns (uint) {
        address _pair = pairFor(token);
        uint _balance = IERC20(token).balanceOf(_pair);
        return LINK.getPriceUSD(token) * _balance / uint(10)**IERC20(token).decimals();
    }
    
    function totalCollateralValue() public view returns (uint) {
        uint _value = 0;
        for (uint i = 0; i < _markets.length; i++) {
            _value += calcCollateralValue(_markets[0]);
        }
        return _value;
    }
    
    function totalValue() public view returns (uint) {
        uint _value = 0;
        for (uint i = 0; i < _markets.length; i++) {
            _value += calcValue(_markets[0]);
        }
        return _value;
    }
    
    function price() external view returns (uint) {
        return 1e8 * totalValue() / totalCollateralValue();
    }
    
    function calcValue(address token) public view returns (uint) {
        address _pair = pairFor(token);
        return balances[_pair];
    }
    
    function calcDiff(address token) external view returns (uint) {
        address _pair = pairFor(token);
        uint _balance = balances[_pair];
        uint _value = IERC20(token).balanceOf(_pair);
        _value =  LINK.getPriceUSD(token) * _value / uint(10)**IERC20(token).decimals();
        if (_balance > _value) {
            return _balance - _value;
        } else {
            return 0;
        }
    }
    
    function collateralBalanceOf(address owner, address token) external view returns (uint) {
        address _pair = pairFor(token);
        uint _balance = IERC20(token).balanceOf(_pair);
        return _balance * collateral[owner][token] / IERC20(_pair).totalSupply();
    }
    
    function getPriceOracle(address token) public view returns (uint) {
        return LINK.getPriceUSD(address(token));
    }
    
    function getPricePair(address token) external view returns (uint) {
        (,uint amountB) = _calcLiquidity(token, address(this), uint(10)**IERC20(token).decimals(), getPriceOracle(token));
        return amountB;
    }
    
    function _deposit(IERC20 token, uint amount, uint minOut, uint minLiquidity) internal {
        uint _price = LINK.getPriceUSD(address(token));
        uint _value = _price * amount / uint(10)**token.decimals();
        require(_value > 0, "!value");
        
        (address _pair, uint amountA, uint amountB) = _addLiquidity(address(token), address(this), amount, _value);
        
        token.safeTransferFrom(msg.sender, _pair, amountA);
        
        _value = _price * amountA / uint(10)**token.decimals();
        require(_value >= minOut, "insufficient credit");
        require(amountB <= _value, "invalid oracle feed");
        
        _mint(_pair, amountB);
        borrowed[msg.sender][address(token)] += amountB;
        
        uint _liquidity = ISushiswapV2Pair(_pair).mint(address(this));
        require(_liquidity >= minLiquidity, "insufficient output liquidity");
        collateral[msg.sender][address(token)] += _liquidity;
        
        collateralCredit[msg.sender][address(token)] += _value;
        _mint(msg.sender, _value);
        
        emit Deposit(msg.sender, address(token), _value, amountA, _value);
    }
    
    function withdrawAll(IERC20 token, uint maxSettle) external {
        _withdraw(token, IERC20(address(this)).balanceOf(msg.sender), maxSettle);
    }
    
    function withdraw(IERC20 token, uint amount, uint maxSettle) external {
        _withdraw(token, amount, maxSettle);
    }
    
    function shortFall(IERC20 token, address owner, uint amount) public view returns (uint) {
        uint _credit = collateralCredit[owner][address(token)];
        uint _collateral = collateral[owner][address(token)];
        uint _borrowed = borrowed[owner][address(token)];
        
        if (_credit < amount) {
            amount = _credit;
        }
        
        uint _burned = _collateral * amount / _credit;
        _borrowed = _borrowed * amount / _credit;
        address _pair = FACTORY.getPair(address(token), address(this));
        
        uint _returned = balances[_pair] * _burned / IERC20(_pair).totalSupply();
        if (_returned < _borrowed) {
            return _borrowed - _returned;
        } else {
            return 0;
        }
    }
    
    function shortFallInToken(IERC20 token, address owner, uint amount) external view returns (uint) {
        uint _shortfall = shortFall(token, owner, amount);
        if (_shortfall > 0) {
            address _pair = FACTORY.getPair(address(token), address(this));
            (uint reserveA, uint reserveB,) = ISushiswapV2Pair(_pair).getReserves();
            (address token0,) = SushiswapV2Library.sortTokens(address(token), address(this));
            (reserveA, reserveB) = address(token) == token0 ? (reserveA, reserveB) : (reserveB, reserveA);
            return _getAmountIn(reserveA, reserveB, _shortfall);
        } else {
            return 0;
        }
        
    }
    
    function profit(IERC20 token, address owner, uint amount) external view returns (uint) {
        uint _credit = collateralCredit[owner][address(token)];
        uint _collateral = collateral[owner][address(token)];
        uint _borrowed = borrowed[owner][address(token)];
        
        if (_credit < amount) {
            amount = _credit;
        }
        
        uint _burned = _collateral * amount / _credit;
        _borrowed = _borrowed * amount / _credit;
        address _pair = FACTORY.getPair(address(token), address(this));
        
        uint _returned = balances[_pair] * _burned / IERC20(_pair).totalSupply();
        if (_returned > _borrowed) {
            return _returned - _borrowed;
        } else {
            return 0;
        }
    }
    
    function _getAmountIn(uint reserveA, uint reserveB, uint amountOut) internal pure returns (uint) {
        uint numerator = reserveA * amountOut * 1000;
        uint denominator = (reserveB - amountOut) * 997;
        return (numerator / denominator) + 1;
    }
    
    function _settle(IERC20 token, address token0, address pair, uint amountA, uint amountB, uint debt, uint maxSettle) internal returns (uint) {
        if (balances[msg.sender]+amountB < debt) {
            uint _shortfall = debt - (balances[msg.sender]+amountB);
            
            (uint reserveA, uint reserveB,) = ISushiswapV2Pair(pair).getReserves();
            (reserveA, reserveB) = address(token) == token0 ? (reserveA, reserveB) : (reserveB, reserveA);
            
            uint amountIn = _getAmountIn(reserveA, reserveB, _shortfall);
            
            require(amountIn <= amountA && amountIn <= maxSettle, 'ADDITIONAL_SETTLEMENT_REQUIRED');
            token.safeTransfer(pair, amountIn);
            (uint amount0Out, uint amount1Out) = address(token) == token0 ? (uint(0), _shortfall) : (_shortfall, uint(0));
            ISushiswapV2Pair(pair).swap(amount0Out, amount1Out, msg.sender, new bytes(0));
            amountA -= amountIn;
        }
        return amountA;
    }
    
    function _unwrap(address pair, IERC20 token, uint burned, uint debt, uint maxSettle) internal returns (uint, uint) {
        IERC20(pair).safeTransfer(pair, burned); // send liquidity to pair
        (uint amountA, uint amountB) = ISushiswapV2Pair(pair).burn(address(this));
        (address token0,) = SushiswapV2Library.sortTokens(address(token), address(this));
        (amountA, amountB) = address(token) == token0 ? (amountA, amountB) : (amountB, amountA);
        return (_settle(token, token0, pair, amountA, amountB, debt, maxSettle), amountB);
    }
    
    function _withdraw(IERC20 token, uint amount, uint maxSettle) internal {
        uint _credit = collateralCredit[msg.sender][address(token)];
        uint _collateral = collateral[msg.sender][address(token)];
        uint _borrowed = borrowed[msg.sender][address(token)];
        
        if (_credit < amount) {
            amount = _credit;
        }
        
        uint _debt = _borrowed+amount;
        // Calculate % of collateral to release
        uint _burned = _collateral * amount / _credit;
        _borrowed = _borrowed * amount / _credit;
        address _pair = FACTORY.getPair(address(token), address(this));
        
        (uint amountA, uint amountB) = _unwrap(_pair, token, _burned, _debt, maxSettle);
        
        collateralCredit[msg.sender][address(token)] -= amount;
        collateral[msg.sender][address(token)] -= _burned;
        borrowed[msg.sender][address(token)] -= _borrowed;
        
        
        token.safeTransfer(msg.sender, amountA);
        _transferTokens(address(this), msg.sender, amountB);
        _burn(msg.sender, _debt);
        
        emit Withdraw(msg.sender, address(token), amount, _borrowed, _burned);
    }

    /**
     * @notice Get the number of tokens `spender` is approved to spend on behalf of `account`
     * @param account The address of the account holding the funds
     * @param spender The address of the account spending the funds
     * @return The number of tokens approved
     */
    function allowance(address account, address spender) external view returns (uint) {
        return allowances[account][spender];
    }

    /**
     * @notice Approve `spender` to transfer up to `amount` from `src`
     * @dev This will overwrite the approval amount for `spender`
     *  and is subject to issues noted [here](https://eips.ethereum.org/EIPS/eip-20#approve)
     * @param spender The address of the account which may transfer tokens
     * @param amount The number of tokens that are approved (2^256-1 means infinite)
     * @return Whether or not the approval succeeded
     */
    function approve(address spender, uint amount) external returns (bool) {
        allowances[msg.sender][spender] = amount;

        emit Approval(msg.sender, spender, amount);
        return true;
    }

    /**
     * @notice Triggers an approval from owner to spends
     * @param owner The address to approve from
     * @param spender The address to be approved
     * @param amount The number of tokens that are approved (2^256-1 means infinite)
     * @param deadline The time at which to expire the signature
     * @param v The recovery byte of the signature
     * @param r Half of the ECDSA signature pair
     * @param s Half of the ECDSA signature pair
     */
    function permit(address owner, address spender, uint amount, uint deadline, uint8 v, bytes32 r, bytes32 s) external {
        bytes32 structHash = keccak256(abi.encode(PERMIT_TYPEHASH, owner, spender, amount, nonces[owner]++, deadline));
        bytes32 digest = keccak256(abi.encodePacked("\x19\x01", DOMAINSEPARATOR, structHash));
        address signatory = ecrecover(digest, v, r, s);
        require(signatory != address(0), "permit: signature");
        require(signatory == owner, "permit: unauthorized");
        require(block.timestamp <= deadline, "permit: expired");

        allowances[owner][spender] = amount;

        emit Approval(owner, spender, amount);
    }

    /**
     * @notice Get the number of tokens held by the `account`
     * @param account The address of the account to get the balance of
     * @return The number of tokens held
     */
    function balanceOf(address account) external view returns (uint) {
        return balances[account];
    }

    /**
     * @notice Transfer `amount` tokens from `msg.sender` to `dst`
     * @param dst The address of the destination account
     * @param amount The number of tokens to transfer
     * @return Whether or not the transfer succeeded
     */
    function transfer(address dst, uint amount) external returns (bool) {
        _transferTokens(msg.sender, dst, amount);
        return true;
    }

    /**
     * @notice Transfer `amount` tokens from `src` to `dst`
     * @param src The address of the source account
     * @param dst The address of the destination account
     * @param amount The number of tokens to transfer
     * @return Whether or not the transfer succeeded
     */
    function transferFrom(address src, address dst, uint amount) external returns (bool) {
        address spender = msg.sender;
        uint spenderAllowance = allowances[src][spender];

        if (spender != src && spenderAllowance != type(uint).max) {
            uint newAllowance = spenderAllowance - amount;
            allowances[src][spender] = newAllowance;

            emit Approval(src, spender, newAllowance);
        }

        _transferTokens(src, dst, amount);
        return true;
    }

    function _transferTokens(address src, address dst, uint amount) internal {
        balances[src] -= amount;
        balances[dst] += amount;
        
        emit Transfer(src, dst, amount);
        
        if (pairs[src] && dst != address(this)) {
            uint _fee = amount / FEE;
            _transferTokens(dst, address(this), _fee);
            notifyFeeAmount(_fee);
        } else if (pairs[dst] && src != address(this)) {
            uint _fee = amount / FEE;
            _transferTokens(dst, address(this), _fee);
            notifyFeeAmount(_fee);
        }
    }

    function _getChainId() internal view returns (uint) {
        uint chainId;
        assembly { chainId := chainid() }
        return chainId;
    }
}