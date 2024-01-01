// File: Pigfox-Imports.sol

// File: @uniswap/v2-core/contracts/interfaces/IUniswapV2Pair.sol

pragma solidity >=0.5.0;

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

// File: @uniswap/v2-core/contracts/interfaces/IUniswapV2Factory.sol

pragma solidity >=0.5.0;

interface IUniswapV2Factory {
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

// File: contracts/@uniswap/v2-periphery/contracts/interfaces/IUniswapV2Router01.sol

pragma solidity >=0.6.2;

interface IUniswapV2Router01 {
    function factory() external pure returns (address);
    function WETH() external pure returns (address);

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
    function removeLiquidityWithPermit(
        address tokenA,
        address tokenB,
        uint liquidity,
        uint amountAMin,
        uint amountBMin,
        address to,
        uint deadline,
        bool approveMax, uint8 v, bytes32 r, bytes32 s
    ) external returns (uint amountA, uint amountB);
    function removeLiquidityETHWithPermit(
        address token,
        uint liquidity,
        uint amountTokenMin,
        uint amountETHMin,
        address to,
        uint deadline,
        bool approveMax, uint8 v, bytes32 r, bytes32 s
    ) external returns (uint amountToken, uint amountETH);
    function swapExactTokensForTokens(
        uint amountIn,
        uint amountOutMin,
        address[] calldata path,
        address to,
        uint deadline
    ) external returns (uint[] memory amounts);
    function swapTokensForExactTokens(
        uint amountOut,
        uint amountInMax,
        address[] calldata path,
        address to,
        uint deadline
    ) external returns (uint[] memory amounts);
    function swapExactETHForTokens(uint amountOutMin, address[] calldata path, address to, uint deadline)
        external
        payable
        returns (uint[] memory amounts);
    function swapTokensForExactETH(uint amountOut, uint amountInMax, address[] calldata path, address to, uint deadline)
        external
        returns (uint[] memory amounts);
    function swapExactTokensForETH(uint amountIn, uint amountOutMin, address[] calldata path, address to, uint deadline)
        external
        returns (uint[] memory amounts);
    function swapETHForExactTokens(uint amountOut, address[] calldata path, address to, uint deadline)
        external
        payable
        returns (uint[] memory amounts);

    function quote(uint amountA, uint reserveA, uint reserveB) external pure returns (uint amountB);
    function getAmountOut(uint amountIn, uint reserveIn, uint reserveOut) external pure returns (uint amountOut);
    function getAmountIn(uint amountOut, uint reserveIn, uint reserveOut) external pure returns (uint amountIn);
    function getAmountsOut(uint amountIn, address[] calldata path) external view returns (uint[] memory amounts);
    function getAmountsIn(uint amountOut, address[] calldata path) external view returns (uint[] memory amounts);
}

// File: @uniswap/v2-periphery/contracts/interfaces/IUniswapV2Router02.sol

// SPDX-License-Identifier: MIT
pragma solidity >=0.6.2;

interface IUniswapV2Router02 is IUniswapV2Router01 {
    function removeLiquidityETHSupportingFeeOnTransferTokens(
        address token,
        uint liquidity,
        uint amountTokenMin,
        uint amountETHMin,
        address to,
        uint deadline
    ) external returns (uint amountETH);
    function removeLiquidityETHWithPermitSupportingFeeOnTransferTokens(
        address token,
        uint liquidity,
        uint amountTokenMin,
        uint amountETHMin,
        address to,
        uint deadline,
        bool approveMax, uint8 v, bytes32 r, bytes32 s
    ) external returns (uint amountETH);

    function swapExactTokensForTokensSupportingFeeOnTransferTokens(
        uint amountIn,
        uint amountOutMin,
        address[] calldata path,
        address to,
        uint deadline
    ) external;
    function swapExactETHForTokensSupportingFeeOnTransferTokens(
        uint amountOutMin,
        address[] calldata path,
        address to,
        uint deadline
    ) external payable;
    function swapExactTokensForETHSupportingFeeOnTransferTokens(
        uint amountIn,
        uint amountOutMin,
        address[] calldata path,
        address to,
        uint deadline
    ) external;
}

// File: ../solc/Pigfox-Imports.sol

pragma solidity ^0.8.18;



interface IERC20 {
    function totalSupply() external view returns (uint256);
    function decimals() external view returns (uint8);
    function balanceOf(address account) external view returns (uint256);
    function allowance(address owner, address spender) external view returns (uint256);

    function transfer(address recipient, uint256 amount) external returns (bool);
    function approve(address spender, uint256 amount) external returns (bool);
    function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);

    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(address indexed owner, address indexed spender, uint256 value);
}

contract ERC20Basic is IERC20 {
    string public constant name = "ERC20Basic";
    string public constant symbol = "ERC";
    uint8 public constant decimals = 18;
    mapping(address => uint256) balances;
    mapping(address => mapping (address => uint256)) allowed;
    uint256 totalSupply_ = 10 ether;

    constructor() {
        balances[msg.sender] = totalSupply_;
    }

    function totalSupply() public override view returns (uint256) {
        return totalSupply_;
    }

    function balanceOf(address tokenOwner) public override view returns (uint256) {
        return balances[tokenOwner];
    }

    function transfer(address receiver, uint256 numTokens) public override returns (bool) {
        require(numTokens <= balances[msg.sender]);
        balances[msg.sender] = balances[msg.sender]-numTokens;
        balances[receiver] = balances[receiver]+numTokens;
        emit Transfer(msg.sender, receiver, numTokens);
        return true;
    }

    function approve(address delegate, uint256 numTokens) public override returns (bool) {
        allowed[msg.sender][delegate] = numTokens;
        emit Approval(msg.sender, delegate, numTokens);
        return true;
    }

    function allowance(address owner, address delegate) public override view returns (uint) {
        return allowed[owner][delegate];
    }

    function transferFrom(address owner, address buyer, uint256 numTokens) public override returns (bool) {
        require(numTokens <= balances[owner]);
        require(numTokens <= allowed[owner][msg.sender]);

        balances[owner] = balances[owner]-numTokens;
        allowed[owner][msg.sender] = allowed[owner][msg.sender]+numTokens;
        balances[buyer] = balances[buyer]+numTokens;
        emit Transfer(owner, buyer, numTokens);
        return true;
    }
}

contract Pigfox {
    event AssetSold(address sender, uint256 amount);
    event AssetBought(address sender, uint256 amount);
    event EtherReceived(address sender, uint amount);
    event LogMessage(string message);
    event LogMessages(string message, string message2);
    address private owner;
    address private _currentRouter0;
    address private _currentRouter1;
    address private _token;

    constructor() {
        owner = msg.sender; // The wallet that deploys the contract becomes the owner
    }

    //Enforce security everywhere
    modifier onlyOwner() {
        require(msg.sender == owner, "Only contract owner can call this function");
        _;
    }

    function _log(string memory message) private {
        emit LogMessage(message);
    }

    function swap(address token, uint256 ethToBorrow,  address tokenPairedWithWeth, address routerAddress0, address routerAddress1) public payable onlyOwner {
        _currentRouter0 = routerAddress0;
        _currentRouter1 = routerAddress1;
        _token = token;
        require(token != tokenPairedWithWeth, "Can't borrow ETH from the same pair as the one you're trading");
        address weth = IUniswapV2Router02(routerAddress0).WETH();
        address pairWeth = IUniswapV2Factory(IUniswapV2Router02(routerAddress0).factory()).getPair(weth, tokenPairedWithWeth);
        require(pairWeth != address(0), "This pool does not exist on router0");
        // Make sure the pools exist on both routers
        address pairAddress0 = IUniswapV2Factory(IUniswapV2Router02(routerAddress0).factory()).getPair(token, weth);
        require(pairAddress0 != address(0), "This pool does not exist on router0");
        address pairAddress1 = IUniswapV2Factory(IUniswapV2Router02(routerAddress1).factory()).getPair(token, weth);
        require(pairAddress1 != address(0), "This pool does not exist on router1");
        address token0 = IUniswapV2Pair(pairWeth).token0();
        address token1 = IUniswapV2Pair(pairWeth).token1();
        uint256 amount0 = weth == token0 ? ethToBorrow : 0;
        uint256 amount1 = weth == token1 ? ethToBorrow : 0;
        IUniswapV2Pair(pairWeth).swap(amount0, amount1, address(this), bytes("not empty"));

        // Revert to zero
        _currentRouter0 = address(0);
        _currentRouter1 = address(0);
        _token = address(0);
    }

    function uniswapV2Call(address, uint256 amount0, uint256 amount1, bytes calldata) external {

        address[] memory path = new address[](2);
        address token0 = IUniswapV2Pair(msg.sender).token0();
        address token1 = IUniswapV2Pair(msg.sender).token1();

        IUniswapV2Router02 router0 = IUniswapV2Router02(_currentRouter0);
        IUniswapV2Router02 router1 = IUniswapV2Router02(_currentRouter1);

        require(msg.sender == IUniswapV2Factory(router0.factory()).getPair(token0, token1), "Unauthorized"); // ensure that msg.sender is a V2 pair

        require(amount0 == 0 || amount1 == 0, "Invalid amounts");

        path[0] = router1.WETH();
        path[1] = _token;

        IERC20 wethContract = IERC20(path[0]);
        IERC20 tokenContract = IERC20(path[1]);
        uint256 wethBorrowed = wethContract.balanceOf(address(this));
        wethContract.approve(_currentRouter1, wethBorrowed);

        // Buy Token with WETH on Router 1 (where it's cheaper)
        uint256 tokensReceived = router1.swapExactTokensForTokens(wethBorrowed, 0, path, address(this), block.timestamp)[1];

        // Sell Token for WETH on Router 0 (where it's more expensive)
        tokenContract.approve(_currentRouter0, tokensReceived);
        address path1 = path[0];
        path[0] = path[1]; // Reverse path
        path[1] = path1;
        uint256 wethReceived = router0.swapExactTokensForTokens(tokensReceived, 0, path, address(this), block.timestamp)[1];

        uint256 profit = wethReceived > wethBorrowed ? wethReceived - wethBorrowed : 0;
        require(wethReceived > wethBorrowed, "Not enough to reimburse loan");

        wethContract.transfer(msg.sender, wethBorrowed);         
        wethContract.transfer(tx.origin, profit);
    }

    function sendProfitToWallet() private {
        //send profit from swap back to wallet
    }

    /**
    Only the current owner can transfer ownership to a new owner
     */
    function updateOwner(address _newOwner) public onlyOwner {
        owner = _newOwner;
    }

    // Function to receive Ether
    receive() external payable {
        emit EtherReceived(msg.sender, msg.value);
    }

    function getRemainingGas() public view returns (uint256) {
        return gasleft();
    }
}
