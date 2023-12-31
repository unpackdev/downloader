// SPDX-License-Identifier: GPL-3.0
pragma solidity >=0.7.0 <0.9.0;

import "./SafeERC20.sol";

interface IUniswapRouterV2 {
    function getAmountOut(uint amountIn, uint reserveIn, uint reserveOut) external pure returns (uint amountOut);
    function getAmountsOut(uint amountIn, address[] memory path) external view returns (uint[] memory amounts);
    function swapExactETHForTokens(uint amountOutMin, address[] calldata path, address to, uint deadline)
    external
    payable
    returns (uint[] memory amounts);

    function swapExactTokensForTokens(
    uint amountIn,
    uint amountOutMin,
    address[] calldata path,
    address to,
    uint deadline) external
    returns (uint[] memory amounts);

    function swapExactTokensForETH(uint amountIn, uint amountOutMin, address[] calldata path, address to, uint deadline)
    external
    returns (uint[] memory amounts);
}

interface IUniswapRouterV3{

    struct ExactInputSingleParams {
        address tokenIn;
        address tokenOut;
        uint24 fee;
        address recipient;
        uint256 deadline;
        uint256 amountIn;
        uint256 amountOutMinimum;
        uint160 sqrtPriceLimitX96;
        }

    struct ExactInputParams {
        bytes path;
        address recipient;
        uint256 deadline;
        uint256 amountIn;
        uint256 amountOutMinimum;
        }

    function exactInputSingle(ExactInputSingleParams memory params) external payable returns (uint256 amountOut);
    function exactInput(ExactInputParams memory params) external returns (uint256 amountOut);
}

interface IPancakeRouterV3{
    struct ExactInputSingleParams {
        address tokenIn;
        address tokenOut;
        uint24 fee;
        address recipient;
        uint256 amountIn;
        uint256 amountOutMinimum;
        uint160 sqrtPriceLimitX96;}

    function exactInputSingle(ExactInputSingleParams memory params) external payable returns (uint256 amountOut);
}
interface IBancorNetworkInfo{
    function tradeOutputBySourceAmount(address sourceToken, address targetToken, uint256 sourceAmount)external view returns(uint);
    function tradingEnabled(address pool) external view returns (bool);
    function poolToken(address pool) external view returns (address);
}

interface IBancorNetwork{
        function tradeBySourceAmount(
        address sourceToken,
        address targetToken,
        uint256 sourceAmount,
        uint256 minReturnAmount,
        uint256 deadline,
        address beneficiary
    ) external payable returns(uint);
        function version()external view returns(uint);
        function pendingNetworkFeeAmount()external view returns(uint);
}

 interface IWERC20{
    function deposit()external payable;
    function withdraw(uint256 amount) external payable;
    function approve(address spender, uint256 amount) external returns (bool);
    function allowance(address owner, address spender) external view returns (uint256);
    function balanceOf(address owner)external view returns(uint);
    function transfer(address to , uint value)external view;
 }

interface ItypeData{

    struct EndResult{
        address pool;
        uint price;
        int decimalDifference;
        uint amountIn;
        uint24 fee;
        bool invert; 
        string dexVersion;
    }
}

interface IswapData{

    struct SwapInputs{
    address tokenIn;
    address tokenOut;
    address middleWareToken;
    address receiver;
    bytes pathV3;
    uint amountIn;
    uint24 fee;
    bool isCoin;
    uint deadline;
    uint amountOutMinimum;
    string contractType;
    }
}


contract swapEthereumV1{

    using SafeERC20 for IERC20;

    mapping(string =>mapping(string => address)) dexsToSymbols;
    mapping(string => uint24)feeOfTheDex;

    address admin;
    address Weth = 0xC02aaA39b223FE8D0A0e5C4F27eAD9083C756Cc2;

    event SetNewAddress(string , string);
    event Swap(address indexed user,uint amountIn, address tokenIn , uint indexed amountOut , address indexed tokenOut);
    event SetFeeDex(string , uint24);

    modifier onlyAdmin(){
        require(msg.sender == admin , "not the admin");
        _;
    }

    modifier isAmount(){
        require(msg.value > 0 , "amount does not exist");
        _;
    }

    modifier isToken(address token){
        require(token !=address(0) , "address token does not exits");
        _;
    }

    constructor(){
        admin = msg.sender;
    }

    receive()external payable{}

    function setDexSymbolContracts(string calldata dexName,string calldata symbol,address contractAddress) external onlyAdmin{
        require(dexsToSymbols[dexName][symbol] == address(0) , "dex address is set");
        dexsToSymbols[dexName][symbol] = contractAddress;
        emit SetNewAddress(dexName , symbol);
    }

    function setFeeOfDex(string memory contractType , uint24 feeAmount)external onlyAdmin{
        require(feeOfTheDex[contractType] == 0 ,"fee is set");
        feeOfTheDex[contractType] = feeAmount;
        emit SetFeeDex(contractType , feeAmount);
    }

    function removeFeeOfDex(string memory contractType)external onlyAdmin{
        delete feeOfTheDex[contractType];
    }

    function deletedexContractAddress(string  memory dex , string memory contractType)external onlyAdmin returns(bool){
        
      bool status = dexsToSymbols[dex][contractType] == address(0) ? false : true;
        
      delete dexsToSymbols[dex][contractType];

      return status;
    }

    function executeSwap(IswapData.SwapInputs memory swapInput)
    public payable 
    isToken(swapInput.tokenIn)
    returns(uint amountOut){
        if(swapInput.tokenIn != Weth && swapInput.isCoin != true)require(msg.value == 0 , "no funds accepted");

      if(checkDexName(swapInput.contractType , "UNISWAPV3")){
            
            amountOut = UniswapV3Execute(swapInput);

      }else if(checkDexName(swapInput.contractType , "PANCAKESWAPV3")){

            amountOut = PancakeSwapExecute(swapInput);

      }else if(checkDexName(swapInput.contractType , "UNISWAPV2")
      ||checkDexName(swapInput.contractType , "PANCAKESWAPV2")
      ||checkDexName(swapInput.contractType , "SUSHISWAPV2")){

            amountOut = UniswapV2Execute(swapInput);
        }else{
            amountOut = BancorExecute(swapInput);
        }

      emit Swap(swapInput.receiver , swapInput.amountIn, swapInput.tokenIn , amountOut , swapInput.tokenOut);
    } 

    function UniswapV2Execute(IswapData.SwapInputs memory swapInput)
    public payable 
    isToken(swapInput.tokenIn)
    returns(uint){
        address payable RouterV2 = payable (dexToContractAddress(swapInput.contractType ,"ROUTERV2"));
        address [] memory path;
        uint[] memory amountOut;
        address sender = msg.sender;

        require(RouterV2 != address(0) , "address for dex not found");
        if(swapInput.tokenIn == Weth && swapInput.isCoin)require(msg.value > 0 ,"not enough ETH");

        if(swapInput.middleWareToken != address(0)){
            path = new address[](3);
            path[0] = swapInput.tokenIn;
            path[1] = swapInput.middleWareToken;
            path[2] = swapInput.tokenOut; 
        }else{
            path = new address[](2);
            path[0] = swapInput.tokenIn;
            path[1] = swapInput.tokenOut; 
        }

        
        if(swapInput.tokenIn == Weth && swapInput.isCoin && !(checkDexName(swapInput.contractType,"PANCAKESWAPV2"))){
            
            require(msg.value > 0 ,"not enough ETH");
              
            amountOut = IUniswapRouterV2(RouterV2).swapExactETHForTokens{value: msg.value}(swapInput.amountOutMinimum , path, swapInput.receiver , swapInput.deadline);
            
        }else if(swapInput.tokenOut == Weth && swapInput.isCoin){
            require(IERC20(swapInput.tokenIn).balanceOf(sender)  >= swapInput.amountIn , "not enough tokens");

            IERC20(swapInput.tokenIn).safeTransferFrom(sender ,address(this) ,swapInput.amountIn);
            IERC20(swapInput.tokenIn).safeIncreaseAllowance(RouterV2 ,swapInput.amountIn);

            amountOut = IUniswapRouterV2(RouterV2).swapExactTokensForETH(swapInput.amountIn , swapInput.amountOutMinimum ,path ,swapInput.receiver ,swapInput.deadline);
        }else{

            if(!swapInput.isCoin || !checkDexName(swapInput.contractType,"PANCAKESWAPV2")){

                require(msg.value == 0 , "eth must not be send");
                require(IERC20(swapInput.tokenIn).balanceOf(swapInput.receiver)  >= swapInput.amountIn , "not enough tokens");
            }

            if(swapInput.tokenIn == Weth && swapInput.isCoin && checkDexName(swapInput.contractType,"PANCAKESWAPV2")){
                bool status = ethToWeth(swapInput.amountIn , true);
                require(status , "not deposited");
            }
            
            if(!swapInput.isCoin || !checkDexName(swapInput.contractType,"PANCAKESWAPV2")){
                IERC20(swapInput.tokenIn).safeTransferFrom(sender ,address(this) ,swapInput.amountIn);
                
            }
            
            IERC20(swapInput.tokenIn).safeIncreaseAllowance(RouterV2 ,swapInput.amountIn);
            
            amountOut = IUniswapRouterV2(RouterV2).swapExactTokensForTokens(swapInput.amountIn , swapInput.amountOutMinimum , path , swapInput.receiver ,swapInput.deadline);
        }
        return amountOut[path.length - 1];  
    }

    function ethToWeth( uint amount , bool zeroToOne)public payable returns(bool){
        //zero for withdraw , one for deposit
        if(zeroToOne){
            require(amount == msg.value ,"not the same amount for deposit");
            IWERC20(Weth).deposit{value:msg.value}();
            return true;
        }else{
            IWERC20(Weth).withdraw(amount);
            return true;
        }
    }

    function UniswapV3Execute(IswapData.SwapInputs memory swapInput)
    public payable 
    isToken(swapInput.tokenIn) 
    returns(uint){

        if(swapInput.tokenIn == Weth && swapInput.isCoin) require(msg.value == swapInput.amountIn , "not correct amount");
        
        address  RouterV3 = dexToContractAddress(swapInput.contractType , "ROUTERV3");
        address sender = msg.sender;
        address receiver = swapInput.receiver;
        uint160 sqrtPriceLimitX96 = 0;//for testing
        uint amountOut;
        IUniswapRouterV3.ExactInputSingleParams memory params;

        if(swapInput.tokenOut == Weth && swapInput.isCoin)receiver = address(this);

        params = IUniswapRouterV3.ExactInputSingleParams(swapInput.tokenIn , swapInput.tokenOut , swapInput.fee 
                                                        ,receiver , swapInput.deadline , swapInput.amountIn 
                                                        ,swapInput.amountOutMinimum ,sqrtPriceLimitX96);

        if(swapInput.tokenIn == Weth && swapInput.isCoin){
            
            amountOut = IUniswapRouterV3(RouterV3).exactInputSingle{value : msg.value}(params);
        
        }else {

            approving(swapInput.tokenIn,sender,RouterV3,swapInput.amountIn);

            if(swapInput.middleWareToken ==address(0) && (swapInput.pathV3).length == 0){

                amountOut = IUniswapRouterV3(RouterV3).exactInputSingle(params);

            }else if((swapInput.pathV3).length != 0){

                amountOut = multiHopSwapV3(swapInput,receiver);
                if(receiver != address(this))return(amountOut);

            }

            if(swapInput.tokenOut == Weth && swapInput.isCoin){
                ethToWeth(amountOut , false);
                (payable(swapInput.receiver)).transfer(amountOut);
            }
        }
        return amountOut;
    }

    function PancakeSwapExecute(IswapData.SwapInputs memory swapInput)
    public payable 
    isToken(swapInput.tokenIn) 
    returns(uint){ 
    
    require(swapInput.tokenIn != address(0) , "not correct address");

    if(msg.value > 0) require(msg.value == swapInput.amountIn , "not correct amount");
    
    address  RouterV3 = dexToContractAddress(swapInput.contractType , "ROUTERV3");
    address sender = msg.sender;
    address receiver = swapInput.receiver;
    uint amountOut;
    uint160 sqrtPriceLimitX96 = 0;//for testing
    IPancakeRouterV3.ExactInputSingleParams memory params;

    params = IPancakeRouterV3.ExactInputSingleParams(swapInput.tokenIn , swapInput.tokenOut , swapInput.fee 
                                                    ,receiver , swapInput.amountIn , swapInput.amountOutMinimum 
                                                    ,sqrtPriceLimitX96);

    if(swapInput.tokenIn == Weth && swapInput.isCoin){
            amountOut = IPancakeRouterV3(RouterV3).exactInputSingle{value : msg.value}(params);
        
    }else {

            IERC20(swapInput.tokenIn).transferFrom(sender , address(this) , swapInput.amountIn);
            IERC20(swapInput.tokenIn).safeIncreaseAllowance(RouterV3 ,swapInput.amountIn);
            // approving(swapInput.tokenIn,msg.sender,RouterV3,swapInput.amountIn);

            (bool status , bytes memory data) = RouterV3.call{value:0}(abi.encodeWithSelector(IPancakeRouterV3(RouterV3).exactInputSingle.selector,params));
            require(status , "swap failed");
            amountOut = abi.decode(data , (uint));

            if(swapInput.tokenOut == Weth && swapInput.isCoin){
                ethToWeth(amountOut , false);
                (payable(swapInput.receiver)).transfer(amountOut);
            }
        }
        return amountOut;
    
    }

    function BancorExecute(IswapData.SwapInputs memory swapInput)public payable isToken(swapInput.tokenIn) returns(uint){
        address beneficiary = swapInput.receiver;
        address sender = msg.sender;
        address router = dexToContractAddress(swapInput.contractType,"RouterV3");
        
        require(router !=address(0),"no address for router set");

        if(swapInput.tokenIn == Weth && swapInput.isCoin){
            require(msg.value == swapInput.amountIn , "not correct amount");
        }else{
            require(msg.value == 0 , "not correct amount");
            approving(swapInput.tokenIn , sender , router , swapInput.amountIn);
        }
        uint amountOut = IBancorNetwork(router).tradeBySourceAmount{value:msg.value}(swapInput.tokenIn, swapInput.tokenOut, swapInput.amountIn, swapInput.amountOutMinimum, swapInput.deadline, beneficiary);
        return amountOut;
    }

    function multiHopSwapV3(IswapData.SwapInputs memory swapInput , address recipient)public isToken(swapInput.tokenIn) returns(uint){
        address routerV3 = dexToContractAddress(swapInput.contractType, "ROUTERV3");
        uint amount;
        require(routerV3 !=address(0),"no address for router set");
        if((swapInput.pathV3).length != 0){
            IUniswapRouterV3.ExactInputParams memory params = IUniswapRouterV3.ExactInputParams(swapInput.pathV3 , recipient,swapInput.deadline,swapInput.amountIn,swapInput.amountOutMinimum);
            amount = IUniswapRouterV3(routerV3).exactInput(params);
            
        }
        require(amount > 0 , "not swapped");
        return amount;
    }

    function approving(address token,address sender,address approveAddress,uint amountIn)internal {
        IERC20(token).safeTransferFrom(sender , address(this) , amountIn);
        IERC20(token).safeIncreaseAllowance(approveAddress ,amountIn);
    }


    function checkDexName(string memory name , string memory dex)public pure returns(bool){
        return keccak256(abi.encodePacked(name)) == keccak256(abi.encodePacked(dex));
    }

    function dexToContractAddress(string  memory dex , string memory contractType)public view returns(address){
        return dexsToSymbols[dex][contractType];
    }

    function changeAdmin(address newAdmin)external onlyAdmin{
        admin = newAdmin;
    }
}