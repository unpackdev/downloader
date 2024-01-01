//SPDX-License-Identifier: MIT Licensed
pragma solidity 0.8.10;

interface IDexRouter {
    function WETH() external pure returns (address);

    function factory() external pure returns (address);

    function addLiquidity(
        address tokenA,
        address tokenB,
        uint256 amountADesired,
        uint256 amountBDesired,
        uint256 amountAMin,
        uint256 amountBMin,
        address to,
        uint256 deadline
    )
        external
        returns (
            uint256 amountA,
            uint256 amountB,
            uint256 liquidity
        );

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
        returns (
            uint256 amountToken,
            uint256 amountETH,
            uint256 liquidity
        );

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

interface IPair {
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

    function allowance(address owner, address spender)
        external
        view
        returns (uint256);

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
        returns (
            uint112 reserve0,
            uint112 reserve1,
            uint32 blockTimestampLast
        );

    function price0CumulativeLast() external view returns (uint256);

    function price1CumulativeLast() external view returns (uint256);

    function kLast() external view returns (uint256);

    function mint(address to) external returns (uint256 liquidity);

    function burn(address to)
        external
        returns (uint256 amount0, uint256 amount1);

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

interface dexFactory {
    function createPair(address tokenA, address tokenB)
        external
        returns (address pair);

    function getPair(address tokenA, address tokenB)
        external
        view
        returns (address pair);
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

    function sub(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
        require(b <= a, errorMessage);
        uint256 c = a - b;

        return c;
    }

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

    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        return div(a, b, "SafeMath: division by zero");
    }

    function div(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
        require(b > 0, errorMessage);
        uint256 c = a / b;
        // assert(a == b * c + a % b); // There is no case in which this doesn't hold

        return c;
    }

    function mod(uint256 a, uint256 b) internal pure returns (uint256) {
        return mod(a, b, "SafeMath: modulo by zero");
    }

    function mod(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
        require(b != 0, errorMessage);
        return a % b;
    }
}

interface IERC20 {
    event Approval(
        address indexed owner,
        address indexed spender,
        uint256 value
    );
    event Transfer(address indexed from, address indexed to, uint256 value);

    function name() external view returns (string memory);

    function symbol() external view returns (string memory);

    function decimals() external view returns (uint8);

    function totalSupply() external view returns (uint256);

    function balanceOf(address owner) external view returns (uint256);

    function allowance(address owner, address spender)
        external
        view
        returns (uint256);

    function approve(address spender, uint256 value) external;

    function transfer(address to, uint256 value) external;

    function transferFrom(
        address from,
        address to,
        uint256 value
    ) external;
}

contract preSale {
    using SafeMath for uint256;
    using SafeMath for uint8;

    address payable public preSaleOwner;
    IERC20 public token;
    IDexRouter public routerAddress;
    address public pancakePair;
    address public deadAddress = 0x000000000000000000000000000000000000dEaD;

    uint256 public tokenPrice;
    address[] public contributors;
    uint256 public preSaleStartTime;
    uint256 public preSaleEndTime;

    uint256 public hardCap;
    uint256 public listingPrice;
    uint256 public liquidityPercent;
    uint256 public soldTokens;
    uint256 public totalUser;
    uint256 public amountRaised;
    uint256 public walletHardcap;

    bool public allow;
    bool public lpUnlocked;
    bool public canClaim;
    bool public refundOrBurn; // true will be refund and false will be Burn

    mapping(address => uint256) public ethBalance;
    mapping(address => uint256) public tokenBalance;
    mapping(address => uint256) public claimCount;
    mapping(address => bool) public isExists;
    mapping(address => uint256) public claimAbleAmount;
    mapping(address => uint256) public claimedAmount;

    modifier onlypreSaleOwner() {
        require(msg.sender == preSaleOwner, "PRESALE: Not a token owner");
        _;
    }

    modifier allowed() {
        require(allow, "PRESALE: Not allowed");
        _;
    }

    event TokenBought(
        address indexed user,
        uint256 indexed numberOfTokens,
        uint256 indexed amountBusd
    );

    event TokenClaimed(address indexed user, uint256 indexed numberOfTokens);

    event EthClaimed(address indexed user, uint256 indexed numberOfEth);

    event TokenUnSold(address indexed user, uint256 indexed numberOfTokens);

    constructor(address _owner, IERC20 _token) {
        preSaleOwner = payable(_owner);
        token = _token;
        routerAddress = IDexRouter(0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D);
        preSaleStartTime = 1698868800;
        preSaleEndTime = 1699819200;
        tokenPrice = 750_000_000;
        listingPrice = 75_000_000_000;
        liquidityPercent = 19;
        hardCap = 100 * 10**18;
        walletHardcap = 3 * 10**18;
    }

    receive() external payable {}

    // to buy token during preSale time => for web3 use
    function buyToken() public payable allowed {
        require(
            block.timestamp > preSaleStartTime,
            "Wait For Presale Satrt Time"
        );
        require(
            msg.value + ethBalance[msg.sender] <= walletHardcap,
            "Wallet harcap Reached"
        );
        require(block.timestamp <= preSaleEndTime, "PRESALE: Time over"); // time check
        require(
            amountRaised.add(msg.value) <= hardCap,
            "PRESALE: Exceeding Hardcap"
        );
        uint256 numberOfTokens = ethToToken(msg.value);

        if (tokenBalance[msg.sender] == 0) {
            totalUser++;
        }
        if (!isExists[msg.sender]) {
            isExists[msg.sender] = true;
            contributors.push(msg.sender);
        }
        tokenBalance[msg.sender] = tokenBalance[msg.sender].add(numberOfTokens);
        claimAbleAmount[msg.sender] = claimAbleAmount[msg.sender].add(
            numberOfTokens
        );
        soldTokens = soldTokens.add(numberOfTokens);
        ethBalance[msg.sender] = ethBalance[msg.sender].add(msg.value);
        amountRaised = amountRaised.add(msg.value);

        emit TokenBought(msg.sender, numberOfTokens, msg.value);
    }

    // to claim token after launch => for web3 use
    function claim() public allowed {
        require(canClaim, "PRESALE: Wait for owner to end preSale");
        require(
            tokenBalance[msg.sender] > 0,
            "PRESALE: Do not have any tokens to claim"
        );
        require(claimAbleAmount[msg.sender] > 0, "No Claimable Amount");
        claimtokens();
    }

    function claimtokens() internal {
        uint256 transferAmount;
        transferAmount = claimAbleAmount[msg.sender];
        token.transfer(msg.sender, transferAmount);
        claimAbleAmount[msg.sender] -= transferAmount;
    }

    // withdraw the funds and initialize the liquidity pool
    function withdrawAndInitializePool() public onlypreSaleOwner allowed {
        require(!canClaim, "Presale: Already intialized");
        require(
            block.timestamp > preSaleEndTime,
            "Presale: PreSale not over yet"
        );
        uint256 EthAmountForLiquidity = amountRaised.mul(liquidityPercent).div(
            100
        );
        uint256 tokenAmountForLiquidity = listingTokens(EthAmountForLiquidity);

        // Create a pancake pair for this new token
        pancakePair = dexFactory(routerAddress.factory()).getPair(
            address(token),
            routerAddress.WETH()
        );
        token.approve(address(routerAddress), tokenAmountForLiquidity);
        addLiquidity(tokenAmountForLiquidity, EthAmountForLiquidity);

        preSaleOwner.transfer(getContractethBalance());
        uint256 leftOver = getContractTokenBalance().sub(soldTokens);
        address receiver;
        if (refundOrBurn) {
            receiver = deadAddress;
            if (leftOver > 0) token.transfer(receiver, leftOver);
            emit TokenUnSold(receiver, leftOver);
        } else {
            receiver = preSaleOwner;
            if (leftOver > 0) token.transfer(receiver, leftOver);
            emit TokenUnSold(receiver, leftOver);
        }

        canClaim = true;
    }

    function addLiquidity(uint256 tokenAmount, uint256 EthAmount) internal {
        // add the liquidity
        routerAddress.addLiquidityETH{value: EthAmount}(
            address(token),
            tokenAmount,
            0, // slippage is unavoidable
            0, // slippage is unavoidable
            address(this),
            block.timestamp + 300
        );
    }

    function unLockLiquidity() public onlypreSaleOwner {
        require(!lpUnlocked, "LP is already unlock");

        uint256 lpBalance = IPair(pancakePair).balanceOf(address(this));
        IPair(pancakePair).transfer(preSaleOwner, lpBalance);
        lpUnlocked = true;
    }

    function setPreSaleTime(uint256 _startTime, uint256 _endTime)
        public
        onlypreSaleOwner
    {
        preSaleStartTime = _startTime;
        preSaleEndTime = _endTime;
    }

    // to check number of token for buying
    function ethToToken(uint256 _amount) public view returns (uint256) {
        uint256 numberOfTokens = _amount.mul(tokenPrice).mul(1000).div(1e18);
        return numberOfTokens.mul(10**(token.decimals())).div(1000);
    }

    // to calculate number of tokens for listing price
    function listingTokens(uint256 _amount) public view returns (uint256) {
        uint256 numberOfTokens = _amount.mul(listingPrice).mul(1000).div(1e18);
        return numberOfTokens.mul(10**(token.decimals())).div(1000);
    }

    // to check contribution
    function userContribution(address _user) public view returns (uint256) {
        return ethBalance[_user];
    }

    // to check token balance of user
    function userTokenBalance(address _user) public view returns (uint256) {
        return tokenBalance[_user];
    }

    // to Stop preSale in case of scam
    function setAllow(bool _enable) external onlypreSaleOwner {
        allow = _enable;
    }

    function getContractethBalance() public view returns (uint256) {
        return address(this).balance;
    }

    function getContractTokenBalance() public view returns (uint256) {
        return token.balanceOf(address(this));
    }

    function getCurrentTime() public view returns (uint256) {
        return block.timestamp;
    }

    function getContributorsLenght() public view returns (uint256) {
        return contributors.length;
    }

    function transferOwnership(address _newOwner) public onlypreSaleOwner {
        preSaleOwner = payable(_newOwner);
    }
}