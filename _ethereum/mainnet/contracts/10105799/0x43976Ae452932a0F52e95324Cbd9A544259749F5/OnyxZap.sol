pragma solidity 0.6.1;

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
}

interface Uniswap{
    function swapExactTokensForETH(uint amountIn, uint amountOutMin, address[] calldata path, address to, uint deadline) external returns (uint[] memory amounts);
    function swapExactETHForTokens(uint amountOutMin, address[] calldata path, address to, uint deadline) external payable returns (uint[] memory amounts);
    function addLiquidityETH(address token, uint amountTokenDesired, uint amountTokenMin, uint amountETHMin, address to, uint deadline) external payable returns (uint amountToken, uint amountETH, uint liquidity);
    function getPair(address tokenA, address tokenB) external view returns (address pair);
}

interface Token{
    function transferFrom(address from, address to, uint tokens) external returns (bool success);
    function transfer(address to, uint tokens) external returns (bool success);
    function balanceOf(address tokenOwner) external view returns (uint balance);
    function approve(address spender, uint tokens) external returns (bool success);
    function allowance(address tokenOwner, address spender) external view returns (uint remaining);
    function primary() external view returns (address payable);
}

contract Secondary{
    
    address constant public OUSDAddress = 0xD2d01dd6Aa7a2F5228c7c17298905A7C7E1dfE81;

    function primary() internal view returns (address payable) {
        return Token(OUSDAddress).primary();
    }
}

contract OnyxZap is Secondary{
    
    using SafeMath for uint256;
    
    address constant public ROUTER      = 0xf164fC0Ec4E93095b804a4795bBe1e041497b92a;
    address constant public FACTORY     = 0x5C69bEe701ef814a2B6a3EDD4B1652CB9cc5aA6f;
    address constant public WETHAddress = 0xC02aaA39b223FE8D0A0e5C4F27eAD9083C756Cc2;
    
    uint constant public INF = 33136721784;

    function LetsInvest(address _TokenContractAddress, address _towhomtoissue) public payable{
        
        //get pool address for token
        address poolAddress = Uniswap(FACTORY).getPair(_TokenContractAddress, WETHAddress);
        require(poolAddress != address(0), "WETH/Token pool does not exist");
        
        uint a = msg.value;                                 //Eth given to Zap
        uint b = Token(WETHAddress).balanceOf(poolAddress); //Eth in uniswap
        
        //Eth to trade for token
        uint c = (a.mul(  b.mul(107000).add(a.mul(8030))  )).div(  b.mul(213679).add(a.mul(55916))  );
        
        uint tokensBefore = Token(_TokenContractAddress).balanceOf(address(this));
        
        //getting tokens
        address[] memory path = new address[](2);
        path[0] = WETHAddress;
        path[1] = _TokenContractAddress;
        Uniswap(ROUTER).swapExactETHForTokens.value(c)(1, path, address(this), INF);
        
        //pool eth and tokens
        uint tokensAfter = Token(_TokenContractAddress).balanceOf(address(this));
        uint amountTokenDesired = tokensAfter.sub(tokensBefore);
        Token(_TokenContractAddress).approve(ROUTER, amountTokenDesired); //allow pool to get tokens
        Uniswap(ROUTER).addLiquidityETH.value( a.sub(c) )(_TokenContractAddress, amountTokenDesired, 1, 1, _towhomtoissue, INF);
        
        //trade extra tokens back to eth
        uint tokensAfterAfter = Token(_TokenContractAddress).balanceOf(address(this));
        path[0] = _TokenContractAddress;
        path[1] = WETHAddress;
        Uniswap(ROUTER).swapExactTokensForETH(tokensAfterAfter.sub(tokensBefore), 1, path, _towhomtoissue, INF);
    }
    
    function getStuckTokens(address _tokenAddress) public {
        Token(_tokenAddress).transfer(primary(), Token(_tokenAddress).balanceOf(address(this)));
    }
    
    function getStuckETH() public {
        primary().transfer(address(this).balance);
    }
}