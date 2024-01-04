pragma solidity >=0.5.0;

interface IERC20 {
    event Approval(address indexed owner, address indexed spender, uint value);
    event Transfer(address indexed from, address indexed to, uint value);

    function name() external view returns (string memory);
    function symbol() external view returns (string memory);
    function decimals() external view returns (uint8);
    function totalSupply() external view returns (uint);
    function balanceOf(address owner) external view returns (uint);
    function allowance(address owner, address spender) external view returns (uint);

    function approve(address spender, uint value) external returns (bool);
    function transfer(address to, uint value) external returns (bool);
    function transferFrom(address from, address to, uint value) external returns (bool);
}

interface IUniswapV2Factory {
    function getPair(address tokenA, address tokenB) external view returns (address pair);
}

interface IUniswapV2Router {
    function addLiquidity(
        address tokenA,
        address tokenB,
        uint amountADesired,
        uint amountBDesired,
        uint amountAMin,
        uint amountBMin,
        address to,
        uint deadline
    ) external returns (uint amountA, uint amountB, uint liquidity);
    function addLiquidityETH(
        address token,
        uint amountTokenDesired,
        uint amountTokenMin,
        uint amountETHMin,
        address to,
        uint deadline
    ) external payable returns (uint amountToken, uint amountETH, uint liquidity);
    function removeLiquidity(
        address tokenA,
        address tokenB,
        uint liquidity,
        uint amountAMin,
        uint amountBMin,
        address to,
        uint deadline
    ) external returns (uint amountA, uint amountB);
    function removeLiquidityETH(
        address token,
        uint liquidity,
        uint amountTokenMin,
        uint amountETHMin,
        address to,
        uint deadline
    ) external returns (uint amountToken, uint amountETH);
    function swapExactTokensForTokens(
        uint amountIn,
        uint amountOutMin,
        address[] calldata path,
        address to,
        uint deadline
    ) external returns (uint[] memory amounts);
    function swapExactETHForTokens(uint amountOutMin, address[] calldata path, address to, uint deadline)
        external
        payable
        returns (uint[] memory amounts);
    function swapExactTokensForETH(uint amountIn, uint amountOutMin, address[] calldata path, address to, uint deadline)
        external
        returns (uint[] memory amounts);
}

interface IUniswapV2Pair {
    function totalSupply() external view returns (uint);
    function balanceOf(address owner) external view returns (uint);
    function token0() external view returns (address);
    function token1() external view returns (address);

    function approve(address spender, uint value) external returns (bool);

    function getReserves() external view returns (uint112 reserve0, uint112 reserve1, uint32 blockTimestampLast);
}

interface IStakingRewards {
    // Views
    function lastTimeRewardApplicable() external view returns (uint256);

    function rewardPerToken() external view returns (uint256);

    function earned(address account) external view returns (uint256);

    function getRewardForDuration() external view returns (uint256);

    function totalSupply() external view returns (uint256);

    function balanceOf(address account) external view returns (uint256);

    // Mutative
    function stake(uint256 amount) external;

    function withdraw(uint256 amount) external;

    function getReward() external;

    function exit() external;
}

interface ICurve {
    function exchange(int128 i, int128 j, uint256 dx, uint256 min_dy) external;
    function coins(uint256) external view returns (address coin);
}

library SafeMath {
    /**
     * @dev Returns the addition of two unsigned integers, reverting on
     * overflow.
     *
     * Counterpart to Solidity's `+` operator.
     *
     * Requirements:
     *
     * - Addition cannot overflow.
     */
    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a + b;
        require(c >= a, "SafeMath: addition overflow");

        return c;
    }

    /**
     * @dev Returns the subtraction of two unsigned integers, reverting on
     * overflow (when the result is negative).
     *
     * Counterpart to Solidity's `-` operator.
     *
     * Requirements:
     *
     * - Subtraction cannot overflow.
     */
    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        return sub(a, b, "SafeMath: subtraction overflow");
    }

    /**
     * @dev Returns the subtraction of two unsigned integers, reverting with custom message on
     * overflow (when the result is negative).
     *
     * Counterpart to Solidity's `-` operator.
     *
     * Requirements:
     *
     * - Subtraction cannot overflow.
     */
    function sub(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b <= a, errorMessage);
        uint256 c = a - b;

        return c;
    }

    /**
     * @dev Returns the multiplication of two unsigned integers, reverting on
     * overflow.
     *
     * Counterpart to Solidity's `*` operator.
     *
     * Requirements:
     *
     * - Multiplication cannot overflow.
     */
    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        // Gas optimization: this is cheaper than requiring 'a' not being zero, but the
        // benefit is lost if 'b' is also tested.
        // See: https://github.com/OpenZeppelin/openzeppelin-contracts/pull/522
        if (a == 0) {
            return 0;
        }

        uint256 c = a * b;
        require(c / a == b, "SafeMath: multiplication overflow");

        return c;
    }

    /**
     * @dev Returns the integer division of two unsigned integers. Reverts on
     * division by zero. The result is rounded towards zero.
     *
     * Counterpart to Solidity's `/` operator. Note: this function uses a
     * `revert` opcode (which leaves remaining gas untouched) while Solidity
     * uses an invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b > 0, "SafeMath: division by zero");
        uint256 c = a / b;
        // assert(a == b * c + a % b); // There is no case in which this doesn't hold

        return c;
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers. (unsigned integer modulo),
     * Reverts when dividing by zero.
     *
     * Counterpart to Solidity's `%` operator. This function uses a `revert`
     * opcode (which leaves remaining gas untouched) while Solidity uses an
     * invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     * - The divisor cannot be zero.
     */
    function mod(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b != 0, "SafeMath: modulo by zero");
        return a % b;
    }
        
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

/**
 * @title SafeERC20
 * @dev Wrappers around ERC20 operations that throw on failure (when the token
 * contract returns false). Tokens that return no value (and instead revert or
 * throw on failure) are also supported, non-reverting calls are assumed to be
 * successful.
 * To use this library you can add a `using SafeERC20 for ERC20;` statement to your contract,
 * which allows you to call the safe operations as `token.safeTransfer(...)`, etc.
 */
library SafeERC20 {
    using SafeMath for uint256;

    function safeTransfer(IERC20 token, address to, uint256 value) internal {
        callOptionalReturn(token, abi.encodeWithSelector(token.transfer.selector, to, value));
    }

    function safeTransferFrom(IERC20 token, address from, address to, uint256 value) internal {
        callOptionalReturn(token, abi.encodeWithSelector(token.transferFrom.selector, from, to, value));
    }

    function safeApprove(IERC20 token, address spender, uint256 value) internal {
        callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, value));
    }

    /**
     * @dev Imitates a Solidity high-level call (i.e. a regular function call to a contract), relaxing the requirement
     * on the return value: the return value is optional (but if data is returned, it must not be false).
     * @param token The token targeted by the call.
     * @param data The call data (encoded using abi.encode or one of its variants).
     */
    function callOptionalReturn(IERC20 token, bytes memory data) private {
        // We need to perform a low level call here, to bypass Solidity's return data size checking mechanism, since
        // we're implementing it ourselves.

        // A Solidity high level call has two parts:
        //  1. The call itself is made, and success asserted
        //  2. The return value is decoded, which in turn checks the size of the returned data.

        // solhint-disable-next-line avoid-low-level-calls
        (bool success, bytes memory returndata) = address(token).call(data);
        require(success, "SafeERC20: low-level call failed");

        if (returndata.length > 0) { // Return data is optional
            // solhint-disable-next-line max-line-length
            require(abi.decode(returndata, (bool)), "SafeERC20: ERC20 operation did not succeed");
        }
    }
}

contract HotPotFundERC20 {
    using SafeMath for uint;

    string public constant name = 'Hotpot V1';
    string public constant symbol = 'HPT-V1';
    uint8 public constant decimals = 18;
    uint public totalSupply;
    mapping(address => uint) public balanceOf;
    mapping(address => mapping(address => uint)) public allowance;

    event Approval(address indexed owner, address indexed spender, uint value);
    event Transfer(address indexed from, address indexed to, uint value);

    constructor() public {
    }

    function _mint(address to, uint value) internal {
        require(to != address(0), "ERC20: mint to the zero address");

        totalSupply = totalSupply.add(value);
        balanceOf[to] = balanceOf[to].add(value);
        emit Transfer(address(0), to, value);
    }

    function _burn(address from, uint value) internal {
        require(from != address(0), "ERC20: burn from the zero address");

        balanceOf[from] = balanceOf[from].sub(value);
        totalSupply = totalSupply.sub(value);
        emit Transfer(from, address(0), value);
    }

    function _approve(address owner, address spender, uint value) private {
        require(owner != address(0), "ERC20: approve from the zero address");
        require(spender != address(0), "ERC20: approve to the zero address");

        allowance[owner][spender] = value;
        emit Approval(owner, spender, value);
    }

    function _transfer(address from, address to, uint value) private {
        require(from != address(0), "ERC20: transfer from the zero address");
        require(to != address(0), "ERC20: transfer to the zero address");

        balanceOf[from] = balanceOf[from].sub(value);
        balanceOf[to] = balanceOf[to].add(value);
        emit Transfer(from, to, value);
    }

    function approve(address spender, uint value) external returns (bool) {
        _approve(msg.sender, spender, value);
        return true;
    }

    function transfer(address to, uint value) external returns (bool) {
        _transfer(msg.sender, to, value);
        return true;
    }

    function transferFrom(address from, address to, uint value) external returns (bool) {
        allowance[from][msg.sender] = allowance[from][msg.sender].sub(value);
        _transfer(from, to, value);
        return true;
    }
}

contract ReentrancyGuard {
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

    constructor () internal {
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

contract HotPotFund is ReentrancyGuard, HotPotFundERC20 {
    using SafeMath for uint;
    using SafeERC20 for IERC20;

    address constant UNISWAP_FACTORY = 0x5C69bEe701ef814a2B6a3EDD4B1652CB9cc5aA6f;
    address constant UNISWAP_V2_ROUTER = 0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D;
    address constant UNI = 0x1f9840a85d5aF5bf1D1762F925BDADdC4201F984;

    uint constant DIVISOR = 100;
    uint constant FEE = 20;

    address public token;
    address public controller;
    uint public totalInvestment;
    mapping (address => uint) public investmentOf;

    // UNI mining rewards
    uint public totalDebts;
    mapping(address => uint256) public debtOf;
    // UNI mining pool pair->mining pool
    mapping(address => address) public uniPool;

    address[] public pairs;

    //Curve swap pools
    mapping (address => address) public curvePool;
    mapping (address => int128) CURVE_N_COINS;

    modifier onlyController() {
        require(msg.sender == controller, 'Only called by Controller.');
        _;
    }

    event Deposit(address indexed owner, uint amount, uint share);
    event Withdraw(address indexed owner, uint amount, uint share);

    constructor (address _token, address _controller) public {
        //approve for add liquidity and swap. 2**256-1 never used up.
        IERC20(_token).safeApprove(UNISWAP_V2_ROUTER, 2**256-1);

        token = _token;
        controller = _controller;
    }

    function deposit(uint amount) public nonReentrant returns(uint share) {
        require(amount > 0, 'Are you kidding me?');
        uint _total_assets = totalAssets();
        IERC20(token).safeTransferFrom(msg.sender, address(this), amount);

        if(totalSupply == 0){
            share = amount;
        }
        else{
            share = amount.mul(totalSupply).div(_total_assets);
            // user uni debt
            uint debt = share.mul(totalDebts.add(totalUNIRewards())).div(totalSupply);
            if(debt > 0){
                debtOf[msg.sender] = debtOf[msg.sender].add(debt);
                totalDebts = totalDebts.add(debt);
            }
        }

        investmentOf[msg.sender] = investmentOf[msg.sender].add(amount);
        totalInvestment = totalInvestment.add(amount);
        _mint(msg.sender, share);
        emit Deposit(msg.sender, amount, share);
    }


    function invest(uint amount, uint[] calldata proportions) external onlyController {
        uint len = pairs.length;
        require(len>0, 'Pairs is empty.');
        address token0 = token;
        require(amount <= IERC20(token0).balanceOf(address(this)), "Not enough balance.");
        require(proportions.length == pairs.length, 'Proportions index out of range.');

        uint _whole;
        for(uint i=0; i<len; i++){
            if(proportions[i] == 0) continue;
            _whole = _whole.add(proportions[i]);

            uint amount0 = (amount.mul(proportions[i]).div(DIVISOR)) >> 1;
            if(amount0 == 0) continue;

            address token1 = pairs[i];
            uint amount1 = _swap(token0, token1, amount0);

            (,uint amountB,) = IUniswapV2Router(UNISWAP_V2_ROUTER).addLiquidity(
                token0, token1,
                amount0, amount1,
                0, 0,
                address(this), block.timestamp
            );

            if(amount1 > amountB) _swap(token1, token0, amount1.sub(amountB));
        }
        require(_whole == DIVISOR, 'Error proportion.');
    }

    function setUNIPool(address pair, address _uniPool) external onlyController {
        require(pair!= address(0) && _uniPool!= address(0), "Invalid address.");

        if(uniPool[pair] != address(0)){
            _withdrawStaking(IUniswapV2Pair(pair), totalSupply);
        }
        IERC20(pair).approve(_uniPool, 2**256-1);
        uniPool[pair] = _uniPool;
    }

    function mineUNI(address pair) public onlyController {
        address stakingRewardAddr = uniPool[pair];
        if(stakingRewardAddr != address(0)){
            uint liquidity = IUniswapV2Pair(pair).balanceOf(address(this));
            if(liquidity > 0){
                IStakingRewards(stakingRewardAddr).stake(liquidity);
            }
        }
    }

    function mineUNIAll() external onlyController {
        for(uint i = 0; i < pairs.length; i++){
            IUniswapV2Pair pair = IUniswapV2Pair(IUniswapV2Factory(UNISWAP_FACTORY).getPair(token, pairs[i]));
            address stakingRewardAddr = uniPool[address(pair)];
            if(stakingRewardAddr != address(0)){
                uint liquidity = pair.balanceOf(address(this));
                if(liquidity > 0){
                    IStakingRewards(stakingRewardAddr).stake(liquidity);
                }
            }
        }
    }

    function totalUNIRewards() public view returns(uint amount){
        amount = IERC20(UNI).balanceOf(address(this));
        for(uint i = 0; i < pairs.length; i++){
            IUniswapV2Pair pair = IUniswapV2Pair(IUniswapV2Factory(UNISWAP_FACTORY).getPair(token, pairs[i]));
            address stakingRewardAddr = uniPool[address(pair)];
            if(stakingRewardAddr != address(0)){
                amount = amount.add(IStakingRewards(stakingRewardAddr).earned(address(this)));
            }
        }
    }

    function UNIRewardsOf(address account) public view returns(uint reward){
        if(balanceOf[account] > 0){
            uint uniAmount = totalUNIRewards();
            uint totalAmount = totalDebts.add(uniAmount).mul(balanceOf[account]).div(totalSupply);
            reward = totalAmount.sub(debtOf[account]);
        }
    }

    function stakingLPOf(address pair) public view returns(uint liquidity){
        if(uniPool[pair] != address(0)){
            liquidity = IStakingRewards(uniPool[pair]).balanceOf(address(this));
        }
    }

    function _withdrawStaking(IUniswapV2Pair pair, uint share) internal returns(uint liquidity){
        address stakingRewardAddr = uniPool[address(pair)];
        if(stakingRewardAddr != address(0)){
            liquidity = IStakingRewards(stakingRewardAddr).balanceOf(address(this)).mul(share).div(totalSupply);
            if(liquidity > 0){
                IStakingRewards(stakingRewardAddr).withdraw(liquidity);
                IStakingRewards(stakingRewardAddr).getReward();
            }
        }
    }

    function withdraw(uint share) public nonReentrant returns(uint amount) {
        require(share > 0 && share <= balanceOf[msg.sender], 'Not enough balance.');

        uint _investment;
        (amount, _investment) = _withdraw(msg.sender, share);
        investmentOf[msg.sender] = investmentOf[msg.sender].sub(_investment);
        totalInvestment = totalInvestment.sub(_investment);
        _burn(msg.sender, share);
        IERC20(token).safeTransfer(msg.sender, amount);
        emit Withdraw(msg.sender, amount, share);
    }

    function _withdraw(
        address user,
        uint share
    ) internal returns (uint amount, uint investment) {
        address token0 = token;
        amount = IERC20(token0).balanceOf(address(this)).mul(share).div(totalSupply);
        for(uint i = 0; i < pairs.length; i++) {
            address token1 = pairs[i];
            IUniswapV2Pair pair = IUniswapV2Pair(IUniswapV2Factory(UNISWAP_FACTORY).getPair(token0, token1));
            uint liquidity = pair.balanceOf(address(this)).mul(share).div(totalSupply);
            liquidity  = liquidity.add(_withdrawStaking(pair, share));
            if(liquidity == 0) continue;

            (uint amount0, uint amount1) = IUniswapV2Router(UNISWAP_V2_ROUTER).removeLiquidity(
                token0, token1,
                liquidity,
                0, 0,
                address(this), block.timestamp
            );
            amount = amount.add(amount0).add(_swap(token1, token0, amount1));
        }

        //withdraw UNI reward
        uint uniAmount = IERC20(UNI).balanceOf(address(this));
        uint totalAmount = totalDebts.add(uniAmount).mul(share).div(totalSupply);
        if(totalAmount > 0){
            uint debt = debtOf[user].mul(share).div(balanceOf[user]);
            debtOf[user] = debtOf[user].sub(debt);
            totalDebts = totalDebts.sub(debt);
            uint reward = totalAmount.sub(debt);
            if(reward > uniAmount) reward = uniAmount;
            if(reward > 0) IERC20(UNI).transfer(user, reward);
        }

        investment = investmentOf[user].mul(share).div(balanceOf[user]);
        if(amount > investment){
            uint _fee = (amount.sub(investment)).mul(FEE).div(DIVISOR);
            amount = amount.sub(_fee);
            IERC20(token0).safeTransfer(controller, _fee);
        }
        else {
            investment = amount;
        }
    }

    function assets(uint index) public view returns(uint _assets) {
        require(index < pairs.length, 'Pair index out of range.');
        address token0 = token;
        address token1 = pairs[index];
        IUniswapV2Pair pair = IUniswapV2Pair(IUniswapV2Factory(UNISWAP_FACTORY).getPair(token0, token1));
        (uint reserve0, uint reserve1, ) = pair.getReserves();

        uint liquidity = pair.balanceOf(address(this)).add(stakingLPOf(address(pair)));
        if( pair.token0() == token0 )
            _assets = (reserve0 << 1).mul(liquidity).div(pair.totalSupply());
        else // pair.token1() == token0
            _assets = (reserve1 << 1).mul(liquidity).div(pair.totalSupply());
    }

    function totalAssets() public view returns(uint _assets) {
        address token0 = token;
        for(uint i=0; i<pairs.length; i++){
            address token1 = pairs[i];
            IUniswapV2Pair pair = IUniswapV2Pair(IUniswapV2Factory(UNISWAP_FACTORY).getPair(token0, token1));
            (uint reserve0, uint reserve1, ) = pair.getReserves();
            uint liquidity = pair.balanceOf(address(this)).add(stakingLPOf(address(pair)));
            if( pair.token0() == token0 )
                _assets = _assets.add((reserve0 << 1).mul(liquidity).div(pair.totalSupply()));
            else // pair.token1() == token0
                _assets = _assets.add((reserve1 << 1).mul(liquidity).div(pair.totalSupply()));
        }
        _assets = _assets.add(IERC20(token0).balanceOf(address(this)));
    }

    function pairsLength() public view returns(uint) {
        return pairs.length;
    }

    function setCurvePool(address _token, address _curvePool, int128 N_COINS) external onlyController {
        curvePool[_token] = _curvePool;
        if(_curvePool != address(0)) {
            if(IERC20(token).allowance(address(this), _curvePool) == 0){
                IERC20(token).safeApprove(_curvePool, 2**256-1);
            }
            if(IERC20(_token).allowance(address(this), _curvePool) == 0){
                IERC20(_token).safeApprove(_curvePool, 2**256-1);
            }
            CURVE_N_COINS[_curvePool] = N_COINS;
        }
    }

    function addPair(address _token) external onlyController {
        address pair = IUniswapV2Factory(UNISWAP_FACTORY).getPair(token, _token);
        require(pair != address(0), 'Pair not exist.');

        //approve for add liquidity and swap.
        IERC20(_token).safeApprove(UNISWAP_V2_ROUTER, 2**256-1);
        //approve for remove liquidity
        IUniswapV2Pair(pair).approve(UNISWAP_V2_ROUTER, 2**256-1);

        for(uint i = 0; i < pairs.length; i++) {
            require(pairs[i] != _token, 'Pair existed.');
        }
        pairs.push(_token);
    }

    function reBalance(
        uint add_index,
        uint remove_index,
        uint liquidity
    ) external onlyController {
        require(remove_index < pairs.length, 'Pair index out of range.');

        address token0 = token;
        address token1 = pairs[remove_index];
        IUniswapV2Pair pair = IUniswapV2Pair(IUniswapV2Factory(UNISWAP_FACTORY).getPair(token0, token1));

        uint stakingLP = stakingLPOf(address(pair));
        if(stakingLP > 0) IStakingRewards(uniPool[address(pair)]).exit();

        require(liquidity <= pair.balanceOf(address(this)) && liquidity > 0, 'Not enough liquidity.');

        (uint amount0, uint amount1) = IUniswapV2Router(UNISWAP_V2_ROUTER).removeLiquidity(
            token0, token1,
            liquidity,
            0, 0,
            address(this), block.timestamp
        );
        amount0 = amount0.add(_swap(token1, token0, amount1));

        //Only remove liquidity
        if(add_index >= pairs.length || add_index == remove_index) return;

        token1 = pairs[add_index];
        amount0 = amount0 >> 1;
        amount1 = _swap(token0, token1, amount0);

        (,uint amountB,) = IUniswapV2Router(UNISWAP_V2_ROUTER).addLiquidity(
            token0, token1,
            amount0, amount1,
            0, 0,
            address(this), block.timestamp
        );

        if(amount1 > amountB) _swap(token1, token0, amount1.sub(amountB));
    }

    function removePair(uint index) external onlyController {
        require(index < pairs.length, 'Pair index out of range.');

        address token0 = token;
        address token1 = pairs[index];
        IUniswapV2Pair pair = IUniswapV2Pair(IUniswapV2Factory(UNISWAP_FACTORY).getPair(token0, token1));
        _withdrawStaking(pair, totalSupply);
        uint liquidity = pair.balanceOf(address(this));

        if(liquidity > 0){
            (uint amount0, uint amount1) = IUniswapV2Router(UNISWAP_V2_ROUTER).removeLiquidity(
                token0, token1,
                liquidity,
                0, 0,
                address(this), block.timestamp
            );
            amount0 = amount0.add(_swap(token1, token0, amount1));
        }
        IERC20(token1).safeApprove(UNISWAP_V2_ROUTER, 0);

        for (uint i = index; i < pairs.length-1; i++){
            pairs[i] = pairs[i+1];
        }
        pairs.pop();
    }

    function _swap(address tokenIn, address tokenOut, uint amount)  private returns(uint) {
        address pool = tokenIn == token ? curvePool[tokenOut] : curvePool[tokenIn];
        if(pool != address(0)){
            int128 N_COINS = CURVE_N_COINS[pool];
            int128 idxIn = N_COINS;
            int128 idxOut = N_COINS;
            for(int128 i=0; i<N_COINS; i++){
                address coin = ICurve(pool).coins(uint(i));
                if(coin == tokenIn) {idxIn = i; continue;}
                if(coin == tokenOut) idxOut = i;
            }
            if(idxIn != N_COINS && idxOut != N_COINS){
                uint amountBefore = IERC20(tokenOut).balanceOf(address(this));
                ICurve(pool).exchange(idxIn, idxOut, amount, 0);
                return (IERC20(tokenOut).balanceOf(address(this))).sub(amountBefore);
            }
        }
        address[] memory path = new address[](2);
        path[0] = tokenIn;
        path[1] = tokenOut;
        uint[] memory amounts = IUniswapV2Router(UNISWAP_V2_ROUTER).swapExactTokensForTokens(
            amount, 0, path, address(this), block.timestamp);
        return amounts[1];
    }
}