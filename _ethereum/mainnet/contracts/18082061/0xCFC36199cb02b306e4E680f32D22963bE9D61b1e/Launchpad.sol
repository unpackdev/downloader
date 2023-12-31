// SPDX-License-Identifier: MIT
pragma solidity >=0.8.17;

// File: PresaleStaking/IWETH.sol

// @title Safo-Bills LP farm Smart Contract
//
//   /$$$$$$   /$$$$$$  /$$$$$$$$ /$$$$$$
// /$$__  $$ /$$__  $$| $$_____//$$__  $$
// | $$  \__/| $$  \ $$| $$     | $$  \ $$
// |  $$$$$$ | $$$$$$$$| $$$$$  | $$  | $$
//  \____  $$| $$__  $$| $$__/  | $$  | $$
//  /$$  \ $$| $$  | $$| $$     | $$  | $$
// |  $$$$$$/| $$  | $$| $$     |  $$$$$$/
//  \______/ |__/  |__/|__/      \______/

interface IWETH {
    function deposit() external payable;

    function withdraw(uint256 wad) external;

    function approve(address guy, uint256 wad) external returns (bool);

    function transfer(address dst, uint256 wad) external returns (bool);

    function transferFrom(
        address src,
        address dst,
        uint256 wad
    ) external returns (bool);

    function balanceOf(address guy) external view returns (uint256);
}

// File: PresaleStaking/IPancakeRouter01.sol

interface IPancakeRouter01 {
    function factory() external pure returns (address);

    function WETH() external pure returns (address);

    function addLiquidity(
        address tokenA,
        address tokenB,
        uint256 amountADesired,
        uint256 amountBDesired,
        uint256 amountAMin,
        uint256 amountBMin,
        address to,
        uint256 deadline
    ) external returns (uint256 amountA, uint256 amountB, uint256 liquidity);

    function addLiquidityETH(
        address token,
        uint256 amountTokenDesired,
        uint256 amountTokenMin,
        uint256 amountETHMin,
        address to,
        uint256 deadline
    )
        external
        payable
        returns (uint256 amountToken, uint256 amountETH, uint256 liquidity);

    function removeLiquidity(
        address tokenA,
        address tokenB,
        uint256 liquidity,
        uint256 amountAMin,
        uint256 amountBMin,
        address to,
        uint256 deadline
    ) external returns (uint256 amountA, uint256 amountB);

    function removeLiquidityETH(
        address token,
        uint256 liquidity,
        uint256 amountTokenMin,
        uint256 amountETHMin,
        address to,
        uint256 deadline
    ) external returns (uint256 amountToken, uint256 amountETH);

    function removeLiquidityWithPermit(
        address tokenA,
        address tokenB,
        uint256 liquidity,
        uint256 amountAMin,
        uint256 amountBMin,
        address to,
        uint256 deadline,
        bool approveMax,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) external returns (uint256 amountA, uint256 amountB);

    function removeLiquidityETHWithPermit(
        address token,
        uint256 liquidity,
        uint256 amountTokenMin,
        uint256 amountETHMin,
        address to,
        uint256 deadline,
        bool approveMax,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) external returns (uint256 amountToken, uint256 amountETH);

    function swapExactTokensForTokens(
        uint256 amountIn,
        uint256 amountOutMin,
        address[] calldata path,
        address to,
        uint256 deadline
    ) external returns (uint256[] memory amounts);

    function swapTokensForExactTokens(
        uint256 amountOut,
        uint256 amountInMax,
        address[] calldata path,
        address to,
        uint256 deadline
    ) external returns (uint256[] memory amounts);

    function swapExactETHForTokens(
        uint256 amountOutMin,
        address[] calldata path,
        address to,
        uint256 deadline
    ) external payable returns (uint256[] memory amounts);

    function swapTokensForExactETH(
        uint256 amountOut,
        uint256 amountInMax,
        address[] calldata path,
        address to,
        uint256 deadline
    ) external returns (uint256[] memory amounts);

    function swapExactTokensForETH(
        uint256 amountIn,
        uint256 amountOutMin,
        address[] calldata path,
        address to,
        uint256 deadline
    ) external returns (uint256[] memory amounts);

    function swapETHForExactTokens(
        uint256 amountOut,
        address[] calldata path,
        address to,
        uint256 deadline
    ) external payable returns (uint256[] memory amounts);

    function quote(
        uint256 amountA,
        uint256 reserveA,
        uint256 reserveB
    ) external pure returns (uint256 amountB);

    function getAmountOut(
        uint256 amountIn,
        uint256 reserveIn,
        uint256 reserveOut
    ) external pure returns (uint256 amountOut);

    function getAmountIn(
        uint256 amountOut,
        uint256 reserveIn,
        uint256 reserveOut
    ) external pure returns (uint256 amountIn);

    function getAmountsOut(
        uint256 amountIn,
        address[] calldata path
    ) external view returns (uint256[] memory amounts);

    function getAmountsIn(
        uint256 amountOut,
        address[] calldata path
    ) external view returns (uint256[] memory amounts);
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

    constructor() {
        _status = _NOT_ENTERED;
    }

    /**
     * @dev Prevents a contract from calling itself, directly or indirectly.
     * Calling a `nonReentrant` function from another `nonReentrant`
     * function is not supported. It is possible to prevent this from happening
     * by making the `nonReentrant` function external, and making it call a
     * `private` function that does the actual work.
     */
    modifier nonReentrant() {
        _nonReentrantBefore();
        _;
        _nonReentrantAfter();
    }

    function _nonReentrantBefore() private {
        // On the first call to nonReentrant, _status will be _NOT_ENTERED
        require(_status != _ENTERED, "ReentrancyGuard: reentrant call");

        // Any calls to nonReentrant after this point will fail
        _status = _ENTERED;
    }

    function _nonReentrantAfter() private {
        // By storing the original value once again, a refund is triggered (see
        // https://eips.ethereum.org/EIPS/eip-2200)
        _status = _NOT_ENTERED;
    }
}

// File: PresaleStaking/presaleStaking.sol

/* ========== CUSTOM ERRORS ========== */

error InvalidAmount();
error InvalidAddress();
error TokensLocked();

interface IERC20A {
    function totalSupply() external view returns (uint256);

    function balanceOf(address account) external view returns (uint256);

    function transfer(
        address recipient,
        uint256 amount
    ) external returns (bool);

    function allowance(
        address owner,
        address spender
    ) external view returns (uint256);

    function approve(address spender, uint256 amount) external returns (bool);

    function name() external view returns (string memory);

    function symbol() external view returns (string memory);

    function decimals() external view returns (uint8);

    function transferFrom(
        address sender,
        address recipient,
        uint256 amount
    ) external returns (bool);

    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(
        address indexed owner,
        address indexed spender,
        uint256 value
    );
}

interface IUniswapV2Factory {
    event PairCreated(
        address indexed token0,
        address indexed token1,
        address pair,
        uint256
    );

    function feeTo() external view returns (address);

    function feeToSetter() external view returns (address);

    function getPair(
        address tokenA,
        address tokenB
    ) external view returns (address pair);

    function allPairs(uint256) external view returns (address pair);

    function allPairsLength() external view returns (uint256);

    function createPair(
        address tokenA,
        address tokenB
    ) external returns (address pair);

    function setFeeTo(address) external;

    function setFeeToSetter(address) external;
}

//

interface IUniswapV2Pair {
    event Approval(
        address indexed owner,
        address indexed spender,
        uint256 value
    );
    event Transfer(address indexed from, address indexed to, uint256 value);

    function name() external pure returns (string memory);

    function symbol() external pure returns (string memory);

    function decimals() external pure returns (uint8);

    function totalSupply() external view returns (uint256);

    function balanceOf(address owner) external view returns (uint256);

    function allowance(
        address owner,
        address spender
    ) external view returns (uint256);

    function approve(address spender, uint256 value) external returns (bool);

    function transfer(address to, uint256 value) external returns (bool);

    function transferFrom(
        address from,
        address to,
        uint256 value
    ) external returns (bool);

    function DOMAIN_SEPARATOR() external view returns (bytes32);

    function PERMIT_TYPEHASH() external pure returns (bytes32);

    function nonces(address owner) external view returns (uint256);

    function permit(
        address owner,
        address spender,
        uint256 value,
        uint256 deadline,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) external;

    event Mint(address indexed sender, uint256 amount0, uint256 amount1);
    event Burn(
        address indexed sender,
        uint256 amount0,
        uint256 amount1,
        address indexed to
    );
    event Swap(
        address indexed sender,
        uint256 amount0In,
        uint256 amount1In,
        uint256 amount0Out,
        uint256 amount1Out,
        address indexed to
    );
    event Sync(uint112 reserve0, uint112 reserve1);

    function MINIMUM_LIQUIDITY() external pure returns (uint256);

    function factory() external view returns (address);

    function token0() external view returns (address);

    function token1() external view returns (address);

    function getReserves()
        external
        view
        returns (uint112 reserve0, uint112 reserve1, uint32 blockTimestampLast);

    function price0CumulativeLast() external view returns (uint256);

    function price1CumulativeLast() external view returns (uint256);

    function kLast() external view returns (uint256);

    function mint(address to) external returns (uint256 liquidity);

    function burn(
        address to
    ) external returns (uint256 amount0, uint256 amount1);

    function swap(
        uint256 amount0Out,
        uint256 amount1Out,
        address to,
        bytes calldata data
    ) external;

    function skim(address to) external;

    function sync() external;

    function initialize(address, address) external;
}

// pragma solidity >=0.6.2;

interface IUniswapV2Router01 {
    function factory() external pure returns (address);

    function WETH() external pure returns (address);

    function addLiquidity(
        address tokenA,
        address tokenB,
        uint256 amountADesired,
        uint256 amountBDesired,
        uint256 amountAMin,
        uint256 amountBMin,
        address to,
        uint256 deadline
    ) external returns (uint256 amountA, uint256 amountB, uint256 liquidity);

    function addLiquidityETH(
        address token,
        uint256 amountTokenDesired,
        uint256 amountTokenMin,
        uint256 amountETHMin,
        address to,
        uint256 deadline
    )
        external
        payable
        returns (uint256 amountToken, uint256 amountETH, uint256 liquidity);

    function removeLiquidity(
        address tokenA,
        address tokenB,
        uint256 liquidity,
        uint256 amountAMin,
        uint256 amountBMin,
        address to,
        uint256 deadline
    ) external returns (uint256 amountA, uint256 amountB);

    function removeLiquidityETH(
        address token,
        uint256 liquidity,
        uint256 amountTokenMin,
        uint256 amountETHMin,
        address to,
        uint256 deadline
    ) external returns (uint256 amountToken, uint256 amountETH);

    function removeLiquidityWithPermit(
        address tokenA,
        address tokenB,
        uint256 liquidity,
        uint256 amountAMin,
        uint256 amountBMin,
        address to,
        uint256 deadline,
        bool approveMax,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) external returns (uint256 amountA, uint256 amountB);

    function removeLiquidityETHWithPermit(
        address token,
        uint256 liquidity,
        uint256 amountTokenMin,
        uint256 amountETHMin,
        address to,
        uint256 deadline,
        bool approveMax,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) external returns (uint256 amountToken, uint256 amountETH);

    function swapExactTokensForTokens(
        uint256 amountIn,
        uint256 amountOutMin,
        address[] calldata path,
        address to,
        uint256 deadline
    ) external returns (uint256[] memory amounts);

    function swapTokensForExactTokens(
        uint256 amountOut,
        uint256 amountInMax,
        address[] calldata path,
        address to,
        uint256 deadline
    ) external returns (uint256[] memory amounts);

    function swapExactETHForTokens(
        uint256 amountOutMin,
        address[] calldata path,
        address to,
        uint256 deadline
    ) external payable returns (uint256[] memory amounts);

    function swapTokensForExactETH(
        uint256 amountOut,
        uint256 amountInMax,
        address[] calldata path,
        address to,
        uint256 deadline
    ) external returns (uint256[] memory amounts);

    function swapExactTokensForETH(
        uint256 amountIn,
        uint256 amountOutMin,
        address[] calldata path,
        address to,
        uint256 deadline
    ) external returns (uint256[] memory amounts);

    function swapETHForExactTokens(
        uint256 amountOut,
        address[] calldata path,
        address to,
        uint256 deadline
    ) external payable returns (uint256[] memory amounts);

    function quote(
        uint256 amountA,
        uint256 reserveA,
        uint256 reserveB
    ) external pure returns (uint256 amountB);

    function getAmountOut(
        uint256 amountIn,
        uint256 reserveIn,
        uint256 reserveOut
    ) external pure returns (uint256 amountOut);

    function getAmountIn(
        uint256 amountOut,
        uint256 reserveIn,
        uint256 reserveOut
    ) external pure returns (uint256 amountIn);

    function getAmountsOut(
        uint256 amountIn,
        address[] calldata path
    ) external view returns (uint256[] memory amounts);

    function getAmountsIn(
        uint256 amountOut,
        address[] calldata path
    ) external view returns (uint256[] memory amounts);
}

// pragma solidity >=0.6.2;

interface IUniswapV2Router02 is IUniswapV2Router01 {
    function removeLiquidityETHSupportingFeeOnTransferTokens(
        address token,
        uint256 liquidity,
        uint256 amountTokenMin,
        uint256 amountETHMin,
        address to,
        uint256 deadline
    ) external returns (uint256 amountETH);

    function removeLiquidityETHWithPermitSupportingFeeOnTransferTokens(
        address token,
        uint256 liquidity,
        uint256 amountTokenMin,
        uint256 amountETHMin,
        address to,
        uint256 deadline,
        bool approveMax,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) external returns (uint256 amountETH);

    function swapExactTokensForTokensSupportingFeeOnTransferTokens(
        uint256 amountIn,
        uint256 amountOutMin,
        address[] calldata path,
        address to,
        uint256 deadline
    ) external;

    function swapExactETHForTokensSupportingFeeOnTransferTokens(
        uint256 amountOutMin,
        address[] calldata path,
        address to,
        uint256 deadline
    ) external payable;

    function swapExactTokensForETHSupportingFeeOnTransferTokens(
        uint256 amountIn,
        uint256 amountOutMin,
        address[] calldata path,
        address to,
        uint256 deadline
    ) external;
}

contract SafoBillsFarm is ReentrancyGuard {
    address public owner;
    mapping(address => uint256) public userPresaleTBalance;
    mapping(address => uint256) public userPresaleMBalance;
    mapping(address => uint256) public userPresaleLBalance;
    uint256 public beansFromSoldSafo;
    mapping(address => bool) userStakeAgain;
    mapping(address => bool) public userStakeIsRefferred;
    mapping(address => address) public userRefferred;
    mapping(address => uint256) refferralRewardCount;
    uint256 public rewardPerTokenStored;
    uint256 public _totalStaked;
    uint256 public rewardRate;
    uint256 public poolEndTime;
    uint256 public updatedAt;
    mapping(address => uint256) public userRewards;
    mapping(address => uint256) public ReferralIncome;
    mapping(address => uint256) public userStakedBalance;
    mapping(address => uint256) public userRewardPerTokenPaid;
    uint256 public emergencyFee = 2000;
    mapping(address => uint256) public userPaidRewards;
    uint256 public refferralLimit = 5;
    uint256 public refferralPercentage = 20;
    uint256 public poolDuration;
    uint256 public poolStartTime;
    uint256 public TokensForReward;
    address public teamWallet = 0x58490A6eD97F8820D8c120dC102F50c638B3C81E;
    bool public poolCancelled;
    bool public poolFinalized;
    bool public poolShifted;

    IERC20A Token;

    modifier onlyAdmin() {
        require(msg.sender == owner, "you are not authorized");
        _;
    }

    struct presale {
        uint256 softCap; //0
        uint256 presaleAmount; //1
        uint256 price; //2
        address token; //3
        uint256 tokensSold; //4
        uint256 bnbSold; //5
        uint256 endTime; //6
        uint256 startTime; //7
        uint256 min; //8
        uint256 max; //9
        bool[] badges; //10
        uint256 liquidity; //11
        string logo; //12
        string name; //13
        uint256 duration; //14
        string symbol; //15
        string youtube; //16
        string description; //17
        address router; //18
        uint256 LPTokens; //19
        string socials; //20
    }

    presale selfInfo;

    modifier updateReward(address _account) {
        rewardPerTokenStored = rewardPerToken();
        updatedAt = lastTimeRewardApplicable();
        if (_account != address(0)) {
            userRewards[_account] = earned(_account);
            userRewardPerTokenPaid[_account] = rewardPerTokenStored;
        }
        _;
    }

    function setPoolRewards(
        uint256 _amount
    ) public onlyAdmin updateReward(address(0)) {
        if (_amount <= 0) revert InvalidAmount();
        if (block.timestamp >= poolEndTime) {
            rewardRate = _amount / poolDuration;
        } else {
            uint256 remainingRewards = (poolEndTime - block.timestamp) *
                rewardRate;
            rewardRate = (_amount + remainingRewards) / poolDuration;
        }
        if (rewardRate <= 0) revert InvalidAmount();
        poolStartTime = block.timestamp;
        poolEndTime = block.timestamp + poolDuration;
        updatedAt = block.timestamp;
    }

    function setPoolRewardsi(
        uint256 _amount
    ) internal updateReward(address(0)) {
        if (_amount <= 0) revert InvalidAmount();
        if (block.timestamp >= poolEndTime) {
            rewardRate = _amount / poolDuration;
        } else {
            uint256 remainingRewards = (poolEndTime - block.timestamp) *
                rewardRate;
            rewardRate = (_amount + remainingRewards) / poolDuration;
        }
        if (rewardRate <= 0) revert InvalidAmount();
        poolStartTime = block.timestamp;
        poolEndTime = block.timestamp + poolDuration;
        updatedAt = block.timestamp;
    }

    function updateTeamWallet(address payable _teamWallet) external onlyAdmin {
        teamWallet = _teamWallet;
    }

    function transferOwnership(address _newOwner) external onlyAdmin {
        owner = payable(_newOwner);
    }

    function rewardPerToken() public view returns (uint256) {
        if (_totalStaked == 0) {
            return rewardPerTokenStored;
        }

        return
            rewardPerTokenStored +
            (rewardRate * (lastTimeRewardApplicable() - updatedAt) * 1e18) /
            _totalStaked;
    }

    function lastTimeRewardApplicable() public view returns (uint256) {
        return _min(block.timestamp, poolEndTime);
    }

    function _min(uint256 x, uint256 y) internal pure returns (uint256) {
        return x <= y ? x : y;
    }

    function changeEmergencyFee(uint256 x) public onlyAdmin {
        emergencyFee = x;
    }

    function earned(address _account) public view returns (uint256) {
        return
            (userStakedBalance[_account] *
                (rewardPerToken() - userRewardPerTokenPaid[_account])) /
            1e18 +
            userRewards[_account];
    }

    constructor(
        address _owner,
        address[] memory _addresses,
        uint256[] memory _integers,
        string[] memory _strings
    ) {
        owner = _owner;
        selfInfo.softCap = _integers[0];
        selfInfo.price = _integers[1];
        selfInfo.token = _addresses[0];
        Token = IERC20A(_addresses[0]);
        selfInfo.endTime = _integers[2];
        selfInfo.startTime = _integers[3];
        selfInfo.min = _integers[4];
        selfInfo.max = _integers[5];
        selfInfo.liquidity = _integers[6];
        selfInfo.name = _strings[0];
        selfInfo.logo = _strings[1];
        selfInfo.duration = _integers[7];
        poolDuration = _integers[7] * 60 * 60 * 24;
        selfInfo.symbol = _strings[2];
        selfInfo.youtube = _strings[3];
        selfInfo.description = _strings[4];
        selfInfo.router = _addresses[1];
        selfInfo.socials = _strings[5];
        uint256 apr = (_integers[0] * 5 * _integers[7] * 100000) / (100 * 365);
        setPoolRewardsi(apr);
    }

    function purchaseSafoBill(
        address _refferralUserAddress
    ) external payable nonReentrant {
        if (userStakeAgain[msg.sender] == false) {
            userStakeAgain[msg.sender] = true;
            if (
                _refferralUserAddress != address(0) &&
                _refferralUserAddress != msg.sender
            ) {
                userRefferred[msg.sender] = _refferralUserAddress;
                userStakeIsRefferred[msg.sender] = true;
            }
        }

        //   require(selfInfo.bnbSold<selfInfo.softCap,"soft cap breached");
        require(!poolCancelled, "Pool has been cancelled");
        // require(block.timestamp<=selfInfo.endTime ,"presale ended");
        // require(block.timestamp>=selfInfo.startTime,"presale not started");
        uint256 totalBeans = msg.value;
        require(
            totalBeans >= selfInfo.min,
            "Amount is less than minimum user buy limit"
        );
        require(totalBeans >= 0, "insufficient amount");
        require(
            userPresaleMBalance[msg.sender] + totalBeans <= selfInfo.max,
            "Amount is more than max user buy limit"
        );

        uint256 beanForLiqudity = (totalBeans * selfInfo.liquidity) / 100;
        uint256 beanForToken = totalBeans - beanForLiqudity;

        uint256 tokensForLiquidity;
        uint256 tokensForUser;
        if (poolFinalized) {
            tokensForLiquidity = _beanToToken(beanForLiqudity);
            tokensForUser = _beanToToken(beanForToken);
        } else {
            tokensForLiquidity =
                (beanForLiqudity * selfInfo.price) /
                10 ** Token.decimals();
            tokensForUser =
                (beanForToken * selfInfo.price) /
                10 ** Token.decimals();
        }

        uint256 LPTokens = addLiquidity(
            tokensForLiquidity,
            beanForLiqudity,
            selfInfo.token
        );

        selfInfo.tokensSold += tokensForUser;
        selfInfo.bnbSold += totalBeans;
        selfInfo.LPTokens += LPTokens;
        userPresaleTBalance[msg.sender] += tokensForUser;
        userPresaleMBalance[msg.sender] += beanForToken;
        userPresaleLBalance[msg.sender] += LPTokens;

        _stake(LPTokens);

        if (!poolFinalized) {
            if (selfInfo.bnbSold >= selfInfo.softCap) {
                selfInfo.startTime = block.timestamp;
                poolFinalized = true;
            }
        }
    }

    function _beanToToken(uint256 _amount) private view returns (uint256) {
        uint256 tokenJuice;

        IUniswapV2Router02 Router = IUniswapV2Router02(selfInfo.router);
        address _WETH = Router.WETH();
        address _uniswapV2Pair = IUniswapV2Factory(Router.factory()).getPair(
            selfInfo.token,
            _WETH
        );

        uint256 bnbReserves = IERC20A(_WETH).balanceOf(_uniswapV2Pair);
        uint256 tokenReserves = Token.balanceOf(_uniswapV2Pair);

        uint256 tokenPerBnb = (tokenReserves * 10 ** 18) / bnbReserves;

        tokenJuice = (_amount * tokenPerBnb) / 10 ** 18;

        return tokenJuice;
    }

    function _stake(uint256 _amount) internal updateReward(msg.sender) {
        if (_amount <= 0) revert InvalidAmount();
        userStakedBalance[msg.sender] += _amount;
        _totalStaked += _amount;
    }

    function addLiquidity(
        uint256 tokenAmount,
        uint256 ethAmount,
        address token
    ) public returns (uint256) {
        Token.approve(selfInfo.router, tokenAmount);
        IUniswapV2Router02 Router = IUniswapV2Router02(selfInfo.router);
        // add the liquidity
        (, , uint256 liquidity) = Router.addLiquidityETH{value: ethAmount}(
            token,
            tokenAmount,
            0, // slippage is unavoidable
            0, // slippage is unavoidable
            address(this),
            block.timestamp + 500
        );

        return liquidity;
    }

    receive() external payable {}

    function redeemSafoBill(uint256 percentage) external nonReentrant {
        require(block.timestamp <= poolEndTime, "Please duration not ended");
        require(percentage <= 10000, "Invalid percentage");

        uint256 amount = (userStakedBalance[msg.sender] * percentage) / 10000;
        require(amount > 0, "No Tokens to unstake");

        uint256 bnbOwed = (userPresaleMBalance[msg.sender] * percentage) /
            10000;
        uint256 tokenOwed = (userPresaleTBalance[msg.sender] * percentage) /
            10000;
        uint256 tokenBonds = (userPresaleLBalance[msg.sender] * percentage) /
            10000;
        require(tokenBonds > 0, "No Tokens to unstake");
         (
            address _WETH,
            uint amountToken,
            uint amountETH
        ) = removeTokenLiquidity(amount);

        userPresaleTBalance[msg.sender] -= tokenOwed;
        userPresaleMBalance[msg.sender] -= bnbOwed;
        userPresaleLBalance[msg.sender] -= tokenBonds;

        selfInfo.tokensSold -= tokenOwed;
        selfInfo.bnbSold -= (bnbOwed + amountETH);
        selfInfo.LPTokens -= amount;

        IERC20A(_WETH).transfer(msg.sender, amountETH);
        Token.transfer(msg.sender, tokenOwed);
    }

    function cancel() external onlyAdmin {
        poolCancelled = true;
    }

    function finalizePool() external onlyAdmin {
        require(!poolFinalized, "Pool already finalized");
        poolFinalized = true;
        selfInfo.startTime = block.timestamp;
        poolShifted = true;
    }

    function refund(uint256 percentage) external nonReentrant {
        require(poolCancelled, "Pool is not cancelled yet");
        require(percentage <= 10000, "Invalid percentage");

        uint256 amount = (userStakedBalance[msg.sender] * percentage) / 10000;
        require(amount > 0, "No LP Tokens to unstake");

        uint256 bnbOwed = (userPresaleMBalance[msg.sender] * percentage) /
            10000;
        uint256 tokenOwed = (userPresaleTBalance[msg.sender] * percentage) /
            10000;
        uint256 tokenBonds = (userPresaleLBalance[msg.sender] * percentage) /
            10000;
        require(tokenBonds > 0, "No Tokens to unstake");

        (
            address _WETH,
            uint amountToken,
            uint amountETH
        ) = removeTokenLiquidity(amount);

        userPresaleTBalance[msg.sender] -= tokenOwed;
        userPresaleMBalance[msg.sender] -= bnbOwed;
        userPresaleLBalance[msg.sender] -= tokenBonds;

        selfInfo.tokensSold -= tokenOwed;
        selfInfo.bnbSold -= (bnbOwed + amountETH);
        selfInfo.LPTokens -= amount;

        IERC20A(_WETH).transfer(msg.sender, amountETH);
        payable(msg.sender).transfer(bnbOwed);
        // Token.transfer(msg.sender, tokenOwed);
    }

    function cancelInvestment() external nonReentrant {
        require(!poolFinalized, "Pool is Finalized");

        uint256 amount = userStakedBalance[msg.sender];
        require(amount > 0, "No LP Tokens to unstake");

        uint256 bnbOwed = userPresaleMBalance[msg.sender];
        uint256 tokenOwed = userPresaleTBalance[msg.sender];
        uint256 tokenBonds = userPresaleLBalance[msg.sender];

        (
            address _WETH,
            uint amountToken,
            uint amountETH
        ) = removeTokenLiquidity(amount);

        userPresaleTBalance[msg.sender] -= tokenOwed;
        userPresaleMBalance[msg.sender] -= bnbOwed;
        userPresaleLBalance[msg.sender] -= tokenBonds;

        selfInfo.tokensSold -= tokenOwed;
        selfInfo.bnbSold -= (bnbOwed + amountETH);
        selfInfo.LPTokens -= amount;

        uint256 wbnbFee = (amountETH * emergencyFee) / 10000;
        uint256 wbnbAfterFee = amountETH - wbnbFee;
        uint256 bnbFee = (bnbOwed * emergencyFee) / 10000;
        uint256 bnbAfterFee = bnbOwed - bnbFee;

        IERC20A(_WETH).transfer(msg.sender, wbnbAfterFee);
        payable(msg.sender).transfer(bnbAfterFee);
        IERC20A(_WETH).transfer(teamWallet, wbnbFee);
        payable(teamWallet).transfer(bnbFee);
    }

    function emergencySale(uint256 percentage) external nonReentrant {
        require(block.timestamp <= poolEndTime, "Pool Ended");
        require(percentage <= 10000, "Invalid percentage");

        uint256 amount = (userStakedBalance[msg.sender] * percentage) / 10000;
        require(amount > 0, "No LP Tokens to unstake");

        uint256 bnbOwed = (userPresaleMBalance[msg.sender] * percentage) /
            10000;
        uint256 tokenOwed = (userPresaleTBalance[msg.sender] * percentage) /
            10000;
        uint256 tokenBonds = (userPresaleLBalance[msg.sender] * percentage) /
            10000;
        require(tokenBonds > 0, "No Tokens to unstake");

        (
            address _WETH,
            uint amountToken,
            uint amountETH
        ) = removeTokenLiquidity(amount);

        userPresaleTBalance[msg.sender] -= tokenOwed;
        userPresaleMBalance[msg.sender] -= bnbOwed;
        userPresaleLBalance[msg.sender] -= tokenBonds;

        selfInfo.tokensSold -= tokenOwed;
        selfInfo.bnbSold -= (bnbOwed + amountETH);
        selfInfo.LPTokens -= amount;

        uint256 wbnbFee = (amountETH * emergencyFee) / 10000;
        uint256 bnbOwedAfterFee = amountETH - wbnbFee;
        uint256 tokenFee = (tokenOwed * emergencyFee) / 10000;
        uint256 tokenOwedAfterFee = tokenOwed - tokenFee;

        IERC20A(_WETH).transfer(msg.sender, bnbOwedAfterFee);
        IERC20A(selfInfo.token).transfer(msg.sender, tokenOwedAfterFee);
        IERC20A(_WETH).transfer(teamWallet, wbnbFee);
        IERC20A(selfInfo.token).transfer(teamWallet, tokenFee);
    }

    function removeTokenLiquidity(
        uint amount
    ) private returns (address, uint, uint) {
        IUniswapV2Router02 Router = IUniswapV2Router02(selfInfo.router);
        address _WETH = Router.WETH();
        address _uniswapV2Pair = IUniswapV2Factory(Router.factory()).getPair(
            selfInfo.token,
            _WETH
        );
        IUniswapV2Pair(_uniswapV2Pair).approve(selfInfo.router, amount);

        (uint256 amountToken, uint256 amountETH) = IUniswapV2Router01(
            selfInfo.router
        ).removeLiquidity(
                selfInfo.token,
                _WETH,
                amount,
                0,
                0,
                address(this),
                block.timestamp + 500
            );
        _unstake(amount);
        return (_WETH, amountToken, amountETH);
    }

    function claimRewards() public updateReward(msg.sender) {
        uint256 rewards = userRewards[msg.sender];
        require(rewards > 0, "No Claim Rewards Yet!");

        require(
            rewards <= TokensForReward,
            "insufficient tokens for reward, please contact admin"
        );
        TokensForReward -= rewards;

        userRewards[msg.sender] = 0;
        userPaidRewards[msg.sender] += rewards;

        if (userStakeIsRefferred[msg.sender] == true) {
            if (refferralRewardCount[msg.sender] < refferralLimit) {
                uint256 refferalReward = (rewards * refferralPercentage) / 100;
                refferralRewardCount[msg.sender] =
                    refferralRewardCount[msg.sender] +
                    1;
                ReferralIncome[userRefferred[msg.sender]] += refferalReward;
                Token.transfer(userRefferred[msg.sender], refferalReward);
                Token.transfer(msg.sender, rewards - refferalReward);
            } else {
                Token.transfer(msg.sender, rewards);
            }
        } else {
            Token.transfer(msg.sender, rewards);
        }
    }

    function withdrawFund() external payable onlyAdmin {
        payable(msg.sender).transfer(address(this).balance);
    }

    function withdrawTokens() external payable onlyAdmin {
        Token.transfer(msg.sender, Token.balanceOf(address(this)));
    }

    function withdrawCustomTokens(
        address _tokenAddress
    ) external payable onlyAdmin {
        IERC20A(_tokenAddress).transfer(
            msg.sender,
            IERC20A(_tokenAddress).balanceOf(address(this))
        );
    }

    function withdrawLPTokens() external payable onlyAdmin {
        IUniswapV2Router02 _uniswapV2Router = IUniswapV2Router02(
            selfInfo.router
        ); // pancake test old 0xD99D1c33F9fC3444f8101754aBC46c52416550D1 // pancake  test 0x9Ac64Cc6e4415144C455BD8E4837Fea55603e5c3  // uniswap 0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D  // pancake original 0x10ED43C718714eb63d5aA57B78B54704E256024E

        // Create a uniswap pair for this new token
        address _uniswapV2Pair = IUniswapV2Factory(_uniswapV2Router.factory())
            .getPair(selfInfo.token, _uniswapV2Router.WETH());
        IUniswapV2Pair pair = IUniswapV2Pair(_uniswapV2Pair);
        pair.transfer(msg.sender, pair.balanceOf(address(this)));
    }

    function _unstake(uint256 _amount) internal updateReward(msg.sender) {
        // if (block.timestamp < poolEndTime) revert TokensLocked();
        if (_amount <= 0) revert InvalidAmount();
        if (_amount > userStakedBalance[msg.sender]) revert InvalidAmount();
        userStakedBalance[msg.sender] -= _amount;
        _totalStaked -= _amount;
    }

    function topUpPoolRewards(
        uint256 _amount
    ) external onlyAdmin updateReward(address(0)) {
        uint256 remainingRewards = (poolEndTime - block.timestamp) * rewardRate;
        rewardRate = (_amount + remainingRewards) / poolDuration;
        require(rewardRate > 0, "reward rate = 0");
        updatedAt = block.timestamp;
    }

    function getSelfInfo() public view returns (presale memory) {
        return selfInfo;
    }

    function setBadges(bool[] memory _badges) public {
        require(msg.sender == owner, "you are not authorised");
        selfInfo.badges = _badges;
    }

    function setRefferralPercentage(
        uint256 _newRefferralPercentage
    ) external onlyAdmin {
        require(_newRefferralPercentage >= 0, "Invalid Refferral Percentage");
        refferralPercentage = _newRefferralPercentage;
    }

    function setRefferralLimit(uint256 _newRefferralLimit) external onlyAdmin {
        require(_newRefferralLimit >= 0, "Invalid Refferral Limit");
        refferralLimit = _newRefferralLimit;
    }

    function depositToken(uint256 _amount) public {
        require(
            Token.allowance(msg.sender, address(this)) >= _amount,
            "insufficient allowance"
        );
        Token.transferFrom(msg.sender, address(this), _amount);
        TokensForReward += _amount;
    }

    function depositTokenForSale(uint256 _amount) public {
        require(
            Token.allowance(msg.sender, address(this)) >= _amount,
            "insufficient allowance"
        );
        Token.transferFrom(msg.sender, address(this), _amount);
    }
}

contract launchPad {
    address public admin;
    address[] public farmArray;

    constructor() {
        admin = 0x58490A6eD97F8820D8c120dC102F50c638B3C81E;
    }

    modifier onlyAdmin() {
        require(msg.sender == admin, "you are not allowed");
        _;
    }

    function changeAdmin(address _add) public onlyAdmin {
        admin = _add;
    }

    function launch(
        address[] memory _addresses,
        uint256[] memory _integers,
        string[] memory _strings
    ) public onlyAdmin {
        IERC20A Token = IERC20A(_addresses[0]);
        uint256 tokenAmount = (_integers[0] * _integers[1]) /
            10 ** Token.decimals();
        require(
            Token.allowance(msg.sender, address(this)) >= tokenAmount,
            "insufficient allowance"
        );
        SafoBillsFarm tx1 = new SafoBillsFarm(
            msg.sender,
            _addresses,
            _integers,
            _strings
        );
        Token.transferFrom(msg.sender, address(tx1), tokenAmount);
        farmArray.push(address(tx1));
    }

    function getFarmArray() public view returns (address[] memory) {
        return farmArray;
    }
}
