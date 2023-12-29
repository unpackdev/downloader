pragma solidity 0.6.8;

library SafeMath {

    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b <= a, "SafeMath: subtraction overflow");
        uint256 c = a - b;
        return c;}
}

interface Uniswap{
    // Trade ERC20 to ETH
    function swapExactTokensForETH(uint amountIn, uint amountOutMin, address[] calldata path, address to, uint deadline) external returns (uint[] memory amounts);
    // Trade ETH to ERC20
    function swapExactETHForTokens(uint amountOutMin, address[] calldata path, address to, uint deadline) external payable returns (uint[] memory amounts);
    // Trade ERC20 to ERC20
    function swapExactTokensForTokens(uint amountIn,uint amountOutMin,address[] calldata path,address to,uint deadline) external returns (uint[] memory amounts);
}

interface Token{
    function getTokens(address sendTo) external payable;
    function transferFrom(address from, address to, uint tokens) external returns (bool success);
    function primary() external view returns (address payable);
    function transfer(address to, uint tokens) external returns (bool success);
    function balanceOf(address tokenOwner) external view returns (uint balance);
    function approve(address spender, uint tokens) external returns (bool success);
    function allowance(address tokenOwner, address spender) external view returns (uint remaining);
}

contract Secondary{
    
    address constant public OUSDAddress = 0xD2d01dd6Aa7a2F5228c7c17298905A7C7E1dfE81;
    
    modifier onlyPrimary() {
        require(msg.sender == primary(), "Secondary: caller is not the primary account");
        _;
    }

    function primary() internal view returns (address payable) {
        return Token(OUSDAddress).primary();
    }
}

contract Swappable{
    
    using SafeMath for uint256;
    
    address constant public UniswapV2Router01Address  = 0xf164fC0Ec4E93095b804a4795bBe1e041497b92a;
    address constant public WETHAddress               = 0xC02aaA39b223FE8D0A0e5C4F27eAD9083C756Cc2;
    
    uint constant public INF = 33136721784;
    
    function tokenToEth(address AssetAddress, uint amountIn) internal returns (uint){
        
        address[] memory path = new address[](2);
        path[0] = AssetAddress;
        path[1] = WETHAddress;
        
        uint balanceBefore = address(this).balance;
        
        Uniswap(UniswapV2Router01Address).swapExactTokensForETH(amountIn,1, path, address(this), INF);
        
        uint balanceAfter = address(this).balance;
        
        
        return balanceAfter.sub(balanceBefore);
    }
        
    function ethToToken(address AssetAddress) internal returns (uint){
        
        address[] memory path = new address[](2);
        path[0] = WETHAddress;
        path[1] = AssetAddress;
        
        uint balanceBefore = Token(AssetAddress).balanceOf( msg.sender );
        
        Uniswap(UniswapV2Router01Address).swapExactETHForTokens.value(msg.value)(1, path, msg.sender, INF);
        
        uint balanceAfter = Token(AssetAddress).balanceOf( msg.sender );
        
        
        return balanceAfter.sub(balanceBefore);
    }
        
    function tokenToToken(uint amountIn, address inputAddress, address outputAddress) internal returns (uint){
        
        address[] memory path = new address[](3);
        
        path[0] = inputAddress;
        path[1] = WETHAddress;
        path[2] = outputAddress;
        
        uint balanceBefore = Token(outputAddress).balanceOf( msg.sender );
        
        Uniswap(UniswapV2Router01Address).swapExactTokensForTokens(amountIn, 1, path, msg.sender, INF);
        
        uint balanceAfter = Token(outputAddress).balanceOf( msg.sender );
        
        
        return balanceAfter.sub(balanceBefore);
    }
}

contract Arb is Secondary, Swappable{
    
    constructor () public {
        
        uint zero = 0;
        uint one = 1;
        
        address OSPVAddress  = 0xFCCe9526E030F1691966d5A651F5EbE1A5B4C8E4;
        address OSPVSAddress = 0xf7D1f35518950E78c18E5A442097cA07962f4D8A;
        
        Token(OUSDAddress).approve(UniswapV2Router01Address, zero - one);
        Token(OSPVAddress).approve(UniswapV2Router01Address, zero - one);
        Token(OSPVSAddress).approve(UniswapV2Router01Address, zero - one);
    }
    
    receive() external payable {}
    
    //combines two calls into one, sees if this contract is approved to move your tokens
    function isitApproved(address UserAddress, address AssetAddress) public view returns (uint){
        
        uint value = 0;
        
        if(Token(OUSDAddress).allowance(UserAddress,address(this)) > 2**128 ){
            value = 2;
        }
        
        if(Token(AssetAddress).allowance(UserAddress,address(this)) > 2**128 ){
            value = value + 1;
        }
        
        return value;
    }
    
    function addToken(address tokenAddress) public onlyPrimary{
        
        uint zero = 0;
        uint one = 1;
        
        Token(tokenAddress).approve(UniswapV2Router01Address, zero - one);
    }
    
    function OUSDtoETH(uint OUSDInput, uint ETHOutput) public{
        
        //transfer ousd from user to this contract
        require( Token(OUSDAddress).transferFrom(msg.sender, address(this), OUSDInput), "Could not move OUSD to this contract, no approval?");
        
        //transfer ousd from this contract to uniswap
        uint ethReceived = tokenToEth(OUSDAddress, OUSDInput);

        //send eth to OUSDcontract
        if(ETHOutput == 0){
            //send all output from uniswap to OUSD contract
            Token(OUSDAddress).getTokens.value(ethReceived)(msg.sender);
        
        }else{
            //send only some output from uniswap to OUSD contract, send only "ETHOutput" amount.
            Token(OUSDAddress).getTokens.value(ETHOutput)(msg.sender);
            msg.sender.transfer( ethReceived.sub(ETHOutput) );
        }
    }
    
    function ETHtoOUSD(uint OUSDOutput) public payable{
        
        //Buy OUSD and give it to user
        uint OUSDbought = ethToToken(OUSDAddress);
        
        //send OUSD from user to OUSDcontract
        if(OUSDOutput == 0){
            //send all output from uniswap to OUSD contract
            require( Token(OUSDAddress).transferFrom(msg.sender, OUSDAddress, OUSDbought) , "Couldnt transfer OUSD from user to OUSD contract");
        
        }else{
            //send only some output from uniswap to OUSD contract, send only "OUSDOutput" amount.
            require( Token(OUSDAddress).transferFrom(msg.sender, OUSDAddress, OUSDOutput) , "Couldnt transfer OUSD from user to OUSD contract");
        }
    }
    
    function OUSDtoAsset(address AssetAddress, uint OUSDInput, uint AssetOutput) public {
        
         //transfer ousd from user to this contract
        require( Token(OUSDAddress).transferFrom(msg.sender, address(this), OUSDInput), "Could not move OUSD to this contract, no approval?");
        
        //trade OUSD for Asset and send asset to user
        uint AssetBought =  tokenToToken(OUSDInput, OUSDAddress, AssetAddress);
        
        if(AssetOutput == 0){
            //send all asset from user to asset contract
            require( Token(AssetAddress).transferFrom(msg.sender, AssetAddress, AssetBought), "Could not transfer Asset to Asset contract.");

        }else{
            //send some asset from user to asset contract
            require( Token(AssetAddress).transferFrom(msg.sender, AssetAddress, AssetOutput), "Could not transfer Asset to Asset contract.");
        }
    }
    
    function AssettoETH(address AssetAddress, uint AssetInput, uint ETHOutput) public {
        
        //transfer Asset from user to this contract
        require( Token(AssetAddress).transferFrom(msg.sender, address(this), AssetInput), "Could not move Asset to this contract, no approval?");
        
        //transfer Asset from this contract to uniswap
        uint ethReceived = tokenToEth(AssetAddress, AssetInput);
       
        //send eth to Asset contract
        if(ETHOutput == 0){
            //send all output from uniswap to Asset contract
            Token(AssetAddress).getTokens.value(ethReceived)(msg.sender);
            
        }else{
            //send only some output from uniswap to Asset contract, send only "ETHOutput" amount.
            Token(AssetAddress).getTokens.value(ETHOutput)(msg.sender);
            msg.sender.transfer( ethReceived.sub(ETHOutput) );
        }
    }
    
    function AssettoOUSD(address AssetAddress, uint AssetInput, uint OUSDOutput) public {
        
        //transfer Asset from user to this contract
        require( Token(AssetAddress).transferFrom(msg.sender, address(this), AssetInput), "Could not move Asset to this contract, no approval?");
        
        //trade Asset for OUSD and send OUSD to user
        uint OUSDBought = tokenToToken(AssetInput, AssetAddress, OUSDAddress);
        
        if(OUSDOutput == 0){
            //send all OUSD from user to asset contract
            require( Token(OUSDAddress).transferFrom(msg.sender, AssetAddress, OUSDBought), "Could not transfer OUSD to Asset contract.");

        }else{
            //send some OUSD from user to asset contract
            require( Token(OUSDAddress).transferFrom(msg.sender, AssetAddress, OUSDOutput), "Could not transfer OUSD to Asset contract.");
        }
    }
    
    function getStuckTokens(address _tokenAddress) public {
        Token(_tokenAddress).transfer(primary(), Token(_tokenAddress).balanceOf(address(this)));
    }
    
    function getStuckETH() public {
        primary().transfer(address(this).balance);
    }
}