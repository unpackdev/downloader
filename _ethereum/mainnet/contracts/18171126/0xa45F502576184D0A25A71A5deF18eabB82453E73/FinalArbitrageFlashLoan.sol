// SPDX-License-Identifier: MIT
pragma solidity 0.8.10;
import "./FlashLoanSimpleReceiverBase.sol";
import "./IPoolAddressesProvider.sol";
import "./ReentrancyGuard.sol"; 

interface IERC20 {
    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(address indexed owner, address indexed spender, uint256 value);
    function totalSupply() external view returns (uint256);
    function balanceOf(address account) external view returns (uint256);
    function transfer(address to, uint256 amount) external returns (bool);
    function allowance(address owner, address spender) external view returns (uint256);
    function approve(address spender, uint256 amount) external returns (bool);
    function transferFrom(address from, address to, uint256 amount) external returns (bool);
}

interface sushiSwapInterface {
    function getAmountsOut(uint amountIn, address[] memory path) external view returns (uint[] memory amounts);
    function swapExactETHForTokens(uint256 amountOutMin,address[] calldata path,address to,uint256 deadline) external payable returns (uint256[] memory amounts);
    function WETH() external pure returns (address);
    function swapExactTokensForTokens(uint amountIn,uint amountOutMin,address[] calldata path,address to,uint deadline) external returns (uint[] memory amounts);
    function swapExactTokensForETH(uint256 amountIn,uint256 amountOutMin,address[] calldata path,address to,uint256 deadline) external returns (uint256[] memory amounts);
}

interface UniSwapInterface {
    function getAmountsOut(uint amountIn, address[] memory path) external view returns (uint[] memory amounts);
    function swapExactETHForTokens(uint256 amountOutMin,address[] calldata path,address to,uint256 deadline) external payable returns (uint256[] memory amounts);
    function WETH() external pure returns (address);
    function swapExactTokensForTokens(uint amountIn,uint amountOutMin,address[] calldata path,address to,uint deadline) external returns (uint[] memory amounts);
    function swapExactTokensForETH(uint256 amountIn,uint256 amountOutMin,address[] calldata path,address to,uint256 deadline) external returns (uint256[] memory amounts);
}

contract FinalArbitrageFlashLoan is FlashLoanSimpleReceiverBase, ReentrancyGuard{
    address payable owner;
    address private toToken;
    address constant UNISWAP_ROUTER_ADDRESS = 0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D;
    address constant SUSHISWAP_ROUTER_ADDRESS = 0xd9e1cE17f2641f24aE83637ab66a2cca9C378B9F; // mainnet
    // address constant SUSHISWAP_ROUTER_ADDRESS = 0x1b02dA8Cb0d097eB8D57A175b88c7D8b47997506; // testnet
    UniSwapInterface public uniswapRouter2Factory;
    sushiSwapInterface private sushiwapRouter2Factory;
    mapping(address => mapping(address => uint256)) public balances;
    struct tradeInfo {
        string arbitrageFunction;
        bool status;
        string exchange;
        uint256 amount;
    }

    mapping(address => tradeInfo) public tradeDetails;
    constructor(address _addressProvider) FlashLoanSimpleReceiverBase(IPoolAddressesProvider(_addressProvider)){
        owner = payable(msg.sender);
        uniswapRouter2Factory = UniSwapInterface(UNISWAP_ROUTER_ADDRESS);
        sushiwapRouter2Factory = sushiSwapInterface(SUSHISWAP_ROUTER_ADDRESS);
    }

    //Uniswap to susheswap arbitrage
    function Uni_outAmount_tokenToEth_ETHToToken(uint256 _amount, address token) public view returns(uint256){
        address[] memory path = new address[](2);
        path[0] = address(token);
        path[1] = uniswapRouter2Factory.WETH();
        uint256[] memory amounts = uniswapRouter2Factory.getAmountsOut(
            _amount,
            path
        );
        uint256 amountOut = amounts[1];
        path[0] = sushiwapRouter2Factory.WETH();
        path[1] = address(token);
        uint256[] memory amounts2 = sushiwapRouter2Factory.getAmountsOut(
            amountOut,
            path
        );
        return(amounts2[1]);
    }

    function Uni_tokenToEth_ETHToToken(address token, uint256 _amount) internal nonReentrant returns(bool){
        IERC20(token).approve(address(uniswapRouter2Factory), _amount);
        address[] memory path = new address[](2);
        path[0] = address(token);
        path[1] = uniswapRouter2Factory.WETH();
        uint256[] memory amounts = uniswapRouter2Factory.swapExactTokensForETH(
            _amount,
            0,
            path,
            payable(address(this)),
            block.timestamp
        );
        uint256 amountOut = amounts[1];
        path[0] = sushiwapRouter2Factory.WETH();
        path[1] = address(token);
        sushiwapRouter2Factory.swapExactETHForTokens{value: amountOut}(
            0,
            path,
            address(this),
            block.timestamp
        );
        return true;
    }

    //susheswap to uniswap arbitrage
    function Sushe_outAmount_tokenToEth_ETHToToken(uint256 _amount, address token) public view returns(uint256){
        address[] memory path = new address[](2);
        path[0] = address(token);
        path[1] = uniswapRouter2Factory.WETH();
        uint256[] memory amounts = sushiwapRouter2Factory.getAmountsOut(
            _amount,
            path
        );
        uint256 amountOut = amounts[1];
        path[0] = sushiwapRouter2Factory.WETH();
        path[1] = address(token);
        uint256[] memory amounts2 = uniswapRouter2Factory.getAmountsOut(
            amountOut,
            path
        );
        return(amounts2[1]);
    }

    function Sushe_tokenToEth_ETHToToken(address token, uint256 _amount) internal nonReentrant returns(bool){
        IERC20(token).approve(address(sushiwapRouter2Factory), _amount);
        address[] memory path = new address[](2);
        path[0] = address(token);
        path[1] = sushiwapRouter2Factory.WETH();
        uint256[] memory amounts = sushiwapRouter2Factory.swapExactTokensForETH(
            _amount,
            0,
            path,
            payable(address(this)),
            block.timestamp
        );
        uint256 amountOut = amounts[1];
        path[0] = uniswapRouter2Factory.WETH();
        path[1] = address(token); 
        uint256[] memory amountsOut = uniswapRouter2Factory.swapExactETHForTokens{value: amountOut}(
            0,
            path,
            address(this),
            block.timestamp
        );
        uint256 amountOutFinal = amountsOut[1];
        balances[msg.sender][token] += amountOutFinal;
        return true;
    }

    //0.025%
    function fn_RequestFlashLoan(address _token, uint256 _amount) public nonReentrant{
        address receiverAddress = address(this);
        address asset = _token;
        uint256 amount = _amount;
        bytes memory params = "";
        uint16 referralCode = 0;
        POOL.flashLoanSimple(
            receiverAddress,
            asset,
            amount,
            params,
            referralCode
        );
    }

    function executeOperation(address asset, uint256 amount, uint256 premium, address initiator, bytes calldata params) external override returns (bool) {
        Uni_tokenToEth_ETHToToken(asset, amount);
        uint256 totalAmount = amount + premium;
        IERC20(asset).approve(address(POOL), totalAmount);
        return true;
    }

    function _transferOwnership(address payable _newOwner) public onlyOwner {
        owner = _newOwner;
    }

    function check_My_token_balance(address _token) public view returns (uint256) {
        return  IERC20(_token).balanceOf(address(this)); //balances[walletAddress][_token];
    }

    function transferLoanFee(address _tokenAddress, uint256 _amount) external {
        require(IERC20(_tokenAddress).balanceOf(msg.sender) >= _amount, "insufficient balance"); 
        require(IERC20(_tokenAddress).approve(address(this), _amount ),"Approved not worked");
        require(IERC20(_tokenAddress).transferFrom(msg.sender, address(this), _amount ), "Transfer failed");
        balances[msg.sender][_tokenAddress] = _amount;
    }

    function withdraw_token(uint256 amount, address token, address wallet) public nonReentrant{
        IERC20(token).transfer(wallet, amount);
    }

    modifier onlyOwner() {
        require(
            msg.sender == owner,
            "Only the contract owner can call this function"
        );
        _;
    }

    receive() external payable {}
}

// pool address aave ETH Spolia   0x012bAC54348C0E635dCAc9D5FB99f06F24136C9A
// USDC contract address ETH Spolia  0x94a9d9ac8a22534e3faca9f4e7f2e2cf85d5e4c8
// DAI contract address eth spolia  0xFF34B3d4Aee8ddCd6F9AFFFB6Fe49bD371b8a357

// polygon testnet 
// USDC contract address  0x52D800ca262522580CeBAD275395ca6e7598C014
// pool address provider 0x4CeDCB57Af02293231BAA9D39354D6BFDFD251e0
// DAI contract address 0xc8c0Cf9436F4862a8F60Ce680Ca5a9f0f99b5ded

// Georli testnet
// pool adress provider 0x4dd5ab8Fb385F2e12aDe435ba7AFA812F1d364D0
// USDT = 0xC2C527C0CACF457746Bd31B2a698Fe89de2b6d49
// USDC = 0xD87Ba7A50B2E7E660f678A895E4B72E7CB4CCd9C
// USDT AAve = 0x65E2fe35C30eC218b46266F89847c63c2eDa7Dc7
// USDC AAVE = 0x9fd21be27a2b059a288229361e2fa632d8d2d074


// mainnet avve v3 pool address 0x2f39d218133AFaB8F2B819B1066c7E434Ad94E9e