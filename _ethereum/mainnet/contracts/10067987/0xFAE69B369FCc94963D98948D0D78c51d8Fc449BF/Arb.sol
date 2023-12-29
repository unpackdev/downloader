pragma solidity 0.5.17;

interface Uniswap{
    function getExchange(address token) external view returns (address exchange);
     // Trade ERC20 to ETH
    function tokenToEthSwapInput(uint256 tokens_sold, uint256 min_eth, uint256 deadline) external returns (uint256  eth_bought);
    // Trade ETH to ERC20
    function ethToTokenTransferInput(uint256 min_tokens, uint256 deadline, address recipient) external payable returns (uint256  tokens_bought);
    // Trade ERC20 to ERC20
    function tokenToTokenTransferInput(uint256 tokens_sold, uint256 min_tokens_bought, uint256 min_eth_bought, uint256 deadline, address recipient, address token_addr) external returns (uint256  tokens_bought);
    
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

contract Arb is Secondary{
    
    address constant public UniswapFactoryAddress = 0xc0a47dFe034B400B47bDaD5FecDa2621de6c4d95;
    address public OUSDPoolAddress;
    
    uint constant public INF = 33136721784;
    
    constructor () public {
        OUSDPoolAddress = Uniswap(UniswapFactoryAddress).getExchange(OUSDAddress);
        
        uint zero = 0;
        uint one = 1;
        
        address OSPVAddress  = 0xFCCe9526E030F1691966d5A651F5EbE1A5B4C8E4;
        address OSPVSAddress = 0xf7D1f35518950E78c18E5A442097cA07962f4D8A;
        
        address OSPVPoolAddress  = Uniswap(UniswapFactoryAddress).getExchange(OSPVAddress);
        address OSPVPoolSAddress = Uniswap(UniswapFactoryAddress).getExchange(OSPVSAddress);
        
        Token(OSPVAddress).approve(OSPVPoolAddress, zero - one);
        Token(OSPVSAddress).approve(OSPVPoolSAddress, zero - one);
    }
    
    function () external payable {}
    
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
        
        address TokenPoolAddress = Uniswap(UniswapFactoryAddress).getExchange(tokenAddress);
        
        uint zero = 0;
        uint one = 1;
        
        Token(tokenAddress).approve(TokenPoolAddress, zero - one);
    }
    
    function OUSDtoETH(uint OUSDInput, uint ETHOutput) public{
        
        //transfer ousd from user to this contract
        require( Token(OUSDAddress).transferFrom(msg.sender, address(this), OUSDInput), "Could not move OUSD to this contract, no approval?");
        
        //transfer ousd from this contract to uniswap
        uint ethReceived = Uniswap(OUSDPoolAddress).tokenToEthSwapInput(OUSDInput,1, INF);

        //send eth to OUSDcontract
        if(ETHOutput == 0){
            //send all output from uniswap to OUSD contract
            Token(OUSDAddress).getTokens.value(ethReceived)(msg.sender);
        
        }else{
            //send only some output from uniswap to OUSD contract, send only "ETHOutput" amount.
            Token(OUSDAddress).getTokens.value(ETHOutput)(msg.sender);
            msg.sender.transfer(ethReceived);
        }
    }
    
    function ETHtoOUSD(uint OUSDOutput) public payable{
        
        //Buy OUSD and give it to user
        uint OUSDbought = Uniswap(OUSDPoolAddress).ethToTokenTransferInput.value(msg.value)(1, INF, msg.sender);
        
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
        uint AssetBought = Uniswap(OUSDPoolAddress).tokenToTokenTransferInput(OUSDInput, 1, 1, INF, msg.sender, AssetAddress);
        
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
        
        address AssetPoolAddress = Uniswap(UniswapFactoryAddress).getExchange(AssetAddress);
        
        //transfer Asset from this contract to uniswap
        uint ethReceived = Uniswap(AssetPoolAddress).tokenToEthSwapInput(AssetInput, 1, INF);
       
        //send eth to Asset contract
        if(ETHOutput == 0){
            //send all output from uniswap to Asset contract
            Token(AssetAddress).getTokens.value(ethReceived)(msg.sender);
            
        }else{
            //send only some output from uniswap to Asset contract, send only "ETHOutput" amount.
            Token(AssetAddress).getTokens.value(ETHOutput)(msg.sender);
            msg.sender.transfer(ethReceived);
        }
    }
    
    function AssettoOUSD(address AssetAddress, uint AssetInput, uint OUSDOutput) public {
        
        //transfer Asset from user to this contract
        require( Token(AssetAddress).transferFrom(msg.sender, address(this), AssetInput), "Could not move Asset to this contract, no approval?");
        
        address AssetPoolAddress = Uniswap(UniswapFactoryAddress).getExchange(AssetAddress);
        
        //trade Asset for OUSD and send OUSD to user
        uint OUSDBought = Uniswap(AssetPoolAddress).tokenToTokenTransferInput(AssetInput, 1, 1, INF, msg.sender, OUSDAddress);
        
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