pragma solidity 0.6.12;

library SafeMath {
   
    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a + b;
        require(c >= a, "SafeMath: addition overflow");
        return c;}

    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        return sub(a, b, "SafeMath: subtraction overflow");}

    function sub(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b <= a, errorMessage);
        uint256 c = a - b;
        return c;}

    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        if (a == 0) {return 0;}
        uint256 c = a * b;
        require(c / a == b, "SafeMath: multiplication overflow");
        return c;}

    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        return div(a, b, "SafeMath: division by zero");}

    function div(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b > 0, errorMessage);
        uint256 c = a / b;
        return c;}

    function mod(uint256 a, uint256 b) internal pure returns (uint256) {
        return mod(a, b, "SafeMath: modulo by zero");}

    function mod(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b != 0, errorMessage);
        return a % b;}
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

interface Uniswap{
    function swapExactTokensForETH(uint amountIn, uint amountOutMin, address[] calldata path, address to, uint deadline) external returns (uint[] memory amounts);
    function swapExactETHForTokens(uint amountOutMin, address[] calldata path, address to, uint deadline) external payable returns (uint[] memory amounts);
    function addLiquidityETH(address token, uint amountTokenDesired, uint amountTokenMin, uint amountETHMin, address to, uint deadline) external payable returns (uint amountToken, uint amountETH, uint liquidity);
    function getPair(address tokenA, address tokenB) external view returns (address pair);
    function WETH() external pure returns (address);
}

interface Kye {
    function routerAddress() external view returns (address);
    function primary() external view returns (address);
}

interface Router {
    function mint(address tokenAddress, uint toMint) external;
}

contract Routerable{
    
    address private constant _KYEADDRESS = 0xD5A4dc51229774223e288528E03192e2342bDA00;
    
    function kyeAddress() public pure returns (address) {
        return _KYEADDRESS;
    }
    
    function routerAddress() public view returns (address payable) {
        return toPayable( Kye(kyeAddress()).routerAddress() );
    }
    
    function primary() public view returns (address ) {
        return Kye(kyeAddress()).primary() ;
    }
    
    modifier onlyRouter() {
        require(msg.sender == routerAddress(), "Caller is not Router");
        _;
    }
    
    function toPayable(address input) internal pure returns (address payable){
        return address(uint160(input));
    }
}

interface Staker {
    function viewLPTokenAmount(address tokenAddress, address who) external view returns(uint);
}

contract Minter is Routerable{
    
    using SafeMath for uint256;
   
    address constant public UNIROUTER         = 0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D;
    address constant public FACTORY           = 0x5C69bEe701ef814a2B6a3EDD4B1652CB9cc5aA6f;
    address          public WETHAddress       = Uniswap(UNIROUTER).WETH();
    
    mapping (address => mapping (address => bool)) public blacklisted;
    
    address staker1 = 0xCe90991255932cE3A19defBb288370023d264369;
    address staker2 = 0x62A3bcF9E0163B34ffE925C0a20515a558e35dB5;
    address staker3 = 0x0954b0165a31d24D6023fd4151464D84Ec87cD10;
    
    bool On = false;
    
    function mint(address token) public {
        require(On                              || msg.sender == primary() );
        require(!blacklisted[msg.sender][token] || msg.sender == primary(), "You already called the function"); //only call the function once per token
        blacklisted[msg.sender][token] = true; //cant call function again per token
        
        //lptokens user has
        uint lpAmount = Staker(staker1).viewLPTokenAmount(token, msg.sender) +
                        Staker(staker2).viewLPTokenAmount(token, msg.sender) +
                        Staker(staker3).viewLPTokenAmount(token, msg.sender);
        
        address poolAddress = Uniswap(FACTORY).getPair(token, WETHAddress);
        
        uint lpTokenTotal = IERC20(poolAddress).totalSupply();      //lptokens total
        uint tokenInUniswap = IERC20(token).balanceOf(poolAddress); //token in uniswap
        
        uint usersTokens = (tokenInUniswap.mul(lpAmount)).div(lpTokenTotal); //token amount in uniswap that is the users
        usersTokens = usersTokens*2; //value amount that user has in lp tokens
        
        Router(routerAddress()).mint(token, usersTokens);
        IERC20(token).transfer(msg.sender, usersTokens);
    }
    
    function turnOn() public {
        require(msg.sender == primary());
        On = true;
    }
}