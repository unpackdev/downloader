// SPDX-License-Identifier: GPL-3.0
pragma solidity >= 0.8.19 < 0.9.0;

import "./console.sol";
interface IUniswapFactoryV3{
  function getPool(address tokenA, address tokenB,uint24 fee) external view returns (address pair);
  function owner() external view returns (address);
}

interface IQuoterV2{

  struct QuoteExactInputSingleParams{
                        address tokenIn;
                        address tokenOut;
                        uint256 amountIn;
                        uint24 fee;
                        uint160 sqrtPriceLimitX96;}

  function quoteExactInput(
    bytes memory path,
    uint256 amountIn
  ) external returns (uint256 amountOut, uint160[] memory sqrtPriceX96AfterList, uint32[] memory initializedTicksCrossedList, uint256 gasEstimate);

    function quoteExactInputSingle(
    IQuoterV2.QuoteExactInputSingleParams memory params
  ) external returns (uint256 amountOut, uint160 sqrtPriceX96After, uint32 initializedTicksCrossed, uint256 gasEstimate);

}

interface IUniswapFactoryV2{
    function getPair(address tokenA, address tokenB) external view returns (address pair);
}

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
        uint160 sqrtPriceLimitX96;}

    function exactInputSingle(ExactInputSingleParams memory params) external payable returns (uint256 amountOut);
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

interface IUniswapPoolV2{
    function getReserves() external view returns (uint112 reserve0, uint112 reserve1, uint32 blockTimestampLast);
    function token0()external view returns(address);
}

interface IUniswapPoolsV3 {
    function slot0()external view returns (uint160 sqrtPriceX96 , 
                                      int24 tick, uint16 observationIndex,
                                      uint16 observationCardinality,
                                      uint16 observationCardinalityNext,
                                      uint8 feeProtocol,
                                      bool unlocked);// use for uniswap contracts
    function getReserves() external view returns (uint112 reserve0, uint112 reserve1, uint32 blockTimestampLast);
    function token0()external view returns(address);
    function liquidity() external view returns (uint128);
}

interface IBancorNetworkInfo{
    function tradeOutputBySourceAmount(address sourceToken, address targetToken, uint256 sourceAmount)external view returns(uint);
    function tradingEnabled(address pool) external view returns (bool);
    function poolToken(address pool) external view returns (address);
    function tradingFeePPM(address pool) external view returns (uint32);
}

interface IERC20{
    function decimals() external view returns(uint8);
    function balanceOf(address owner)external view returns(uint);
    function approve(address spender, uint256 amount) external returns (bool);
    function allowance(address owner, address spender) external view returns (uint256);
    function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);
    function transfer(address to , uint value)external;

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
        uint amonutIn;
        uint24 fee;
        bool invert; 
        string dexVersion;
    }

    struct EndResultMH{
        uint price;
        address middleWareToken;
        uint amountIn;
        uint24 dexFee;
        bytes path;
        string dexVersion;
    }

    struct MultiHop{
        address middleWareToken;
        uint price;
        uint amountIn;
        uint24 dexFee0;
        uint24 dexFee1;
        bytes path;
        string dexVersion;
    } 

    struct PoolsData{
        address pool;
        address middleWareToken;
        uint24 dexFee;
    }
}

contract QuoteEthereumV1{

    mapping(string =>mapping(string => address)) dexsToSymbols;
    mapping(string => uint24)feeOfTheDex;

    address admin;
    address constant Usdc = 0xA0b86991c6218b36c1d19D4a2e9Eb0cE3606eB48;
    address constant Usdt = 0xdAC17F958D2ee523a2206206994597C13D831ec7;
    address constant Weth = 0xC02aaA39b223FE8D0A0e5C4F27eAD9083C756Cc2;
    address Eth = 0xEeeeeEeeeEeEeeEeEeEeeEEEeeeeEeeeeeeeEEeE;
    string [] totalDexs;
    uint24 [] DexFees;

    event SetNewAddress(string , string);
    event SetFeeDex(string , uint24);
    event SetAllDexes(string []);
    event SetAllFees(uint24 []);

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

    function setDexSymbolContracts(string calldata dexName,string calldata symbol,address contractAddress) external onlyAdmin{
        require(dexsToSymbols[dexName][symbol] == address(0) , "dex address is set");
        dexsToSymbols[dexName][symbol] = contractAddress;
        emit SetNewAddress(dexName , symbol);
    }

    function setDexList(string [] memory _dexesName)external onlyAdmin returns(bool){
        totalDexs = _dexesName;
        emit SetAllDexes(_dexesName);
        return true;
    }

    function setDexFeeList(uint24 [] memory _fees)external onlyAdmin returns(bool){
        DexFees = _fees;
        emit SetAllFees(_fees);
        return true;
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

    function getAllPrices(address token0,address token1 , uint amountIn)public isToken(token0) returns(ItypeData.EndResult [] memory PriceRatios){

        require(token0 != address(0) , "not correct address");

        uint8 count;
        ItypeData.EndResult[] memory totalPairs = new ItypeData.EndResult[](11);
        

        for (uint i = 0 ; i < totalDexs.length ; i++){
            
            ItypeData.EndResult memory res = getPrice(token0 , token1 , amountIn , totalDexs[i] , DexFees[i]);
            
            
            if(res.pool != address(0)){
                totalPairs[count] = res;
                count++;
            }
        }

        ItypeData.EndResult[] memory availablePools = new ItypeData.EndResult[](count);

        for(uint8 i = 0 ; i < count ; i++){
            availablePools[i] = totalPairs[i];
        }

        return availablePools;

    }

    function getPrice(address token0 , address token1 , uint amountIn , string memory dexName ,uint24 fee) public returns(ItypeData.EndResult memory){
        require(fee != 0 , "fee is not set");
        
        if(checkDexName(dexName , "PANCAKESWAPV3") || checkDexName(dexName , "UNISWAPV3")){

            token0 = changeInput(token0);
            token1 = changeInput(token1);
            return quoterUniswapV3(token0 , token1 , amountIn , dexName , fee);

        
        }else if(checkDexName(dexName , "UNISWAPV2") || 
                checkDexName(dexName , "PANCAKESWAPV2") ||
                checkDexName(dexName , "SUSHISWAPV2")){

            token0 = changeInput(token0);
            token1 = changeInput(token1);
            return uniswapV2GetPrice(token0 , token1 , amountIn , dexName);
        }else{
            return BancorGetPrice(token0,token1 , amountIn,dexName);
        }
    }

    function uniswapV3GetPrice(address token0,address token1 , uint amountIn , string memory contractType , uint24 fee)public view returns( ItypeData.EndResult memory ){
        
        address pairAddress = uniswapV3GetSinglePool(token0 , token1 , contractType , fee);
        
        if(pairAddress == address(0)){
            return ItypeData.EndResult(pairAddress , 0 ,0 , amountIn , fee , false , contractType);
        }

        uint8 decimal0 = IERC20(token0).decimals();
        uint8 decimal1 = IERC20(token1).decimals();

        bool invert  = token0 == IUniswapPoolsV3(pairAddress).token0() ? true : false;

        uint liquidity = IUniswapPoolsV3(pairAddress).liquidity();
        if(liquidity == 0){
            return ItypeData.EndResult(pairAddress , 0 ,0 , amountIn , fee , false , contractType);
        }

        int decimalDifference = getDecimalDiffenrence(decimal0 , decimal1 , invert);
        decimalDifference = invert ? decimalDifference : decimalDifference * -1;
        
        (bool status , bytes memory data)= pairAddress.staticcall(abi.encodeWithSelector(IUniswapPoolsV3(pairAddress).slot0.selector));
        require(status , "not called");
        (uint160 sqrtPriceX96,,,,,,) = abi.decode(data , (uint160 , int24 , uint16, uint16,uint16,uint32 , bool));
        
        uint160 amountOut = sqrtPriceX96;

        return ItypeData.EndResult(pairAddress , amountOut ,decimalDifference , amountIn , fee , invert , contractType);
    }

     function quoterUniswapV3(address token0 , address token1 , uint amountIn ,string memory contractType, uint24 fee)public returns(ItypeData.EndResult memory){
        
        address uniswapV3Quoter = dexToContractAddress(contractType , "QUOTERV2");
        ItypeData.EndResult memory dexResult;

        IQuoterV2.QuoteExactInputSingleParams memory params = 
        IQuoterV2.QuoteExactInputSingleParams({
            tokenIn:token0,
            tokenOut:token1 ,
            fee:fee,
            amountIn:amountIn,
            sqrtPriceLimitX96: 0
        });
        
        
        try IQuoterV2(uniswapV3Quoter).quoteExactInputSingle(params) returns(uint amountOut,uint160,uint32,uint256){
            uint160 temp =  uint160(uint(bytes32(block.timestamp)));
            dexResult = ItypeData.EndResult({pool:address(temp), price:amountOut, decimalDifference:0,amonutIn:amountIn,fee:fee,invert:false, dexVersion:contractType});
            return dexResult;
        }catch{
            
            return ItypeData.EndResult({pool:address(0), price:0, decimalDifference:0,amonutIn:amountIn,fee:fee,invert:false, dexVersion:contractType});
        }
    
    }


    function uniswapV3GetSinglePool(address token0 , address token1 , string memory contractType , uint24 fee)public view returns(address){
        address  factoryAddress = dexsToSymbols[contractType]["FACTORYV3"];
        require(factoryAddress != address(0) , "facotry address not set");

        return IUniswapFactoryV3(factoryAddress).getPool(token0,token1,fee);
    }

    function uniswapV2GetPrice(address token0,address token1 , uint amountIn , string memory contractType)public
    isToken(token0) view returns(ItypeData.EndResult memory){
        address factory = dexToContractAddress(contractType , "FACTORYV2");
        address router  = dexToContractAddress(contractType ,"ROUTERV2");
        uint24 feeDexV2 = feeOfTheDex[contractType];
        address[] memory path = new address[](2);

        path[0] = token0;
        path[1] = token1;
        
        require(factory != address(0) , "dex factory address is not set");
        require(router != address(0) , "dex Router address is not set");
        
        
        address PairPool = UniswapV2GetPoolPair(token0 , token1 , factory);

        if(PairPool == address(0)){
            ItypeData.EndResult memory notFound = ItypeData.EndResult(PairPool , 0 , 0 , amountIn , feeDexV2 , false , contractType);
            return notFound;
        }
        bool invert  = token0 == IUniswapPoolsV3(PairPool).token0() ? false : true;

        uint256[] memory amounts = IUniswapRouterV2(router).getAmountsOut(amountIn , path);

        ItypeData.EndResult memory endResult = ItypeData.EndResult(PairPool , amounts[1] , 0 , amounts[0], feeDexV2 , invert , contractType );

        return endResult;
    }

    function UniswapV2GetPoolPair(address token0,address token1,address factoryAddress)
    public view returns(address){
        address poolAddress = IUniswapFactoryV2(factoryAddress).getPair(token0 , token1);
        
        return poolAddress;
    }

    function BancorGetPrice(address token0 , address token1 , uint amountIn , string memory contractType)public view returns(ItypeData.EndResult memory){
        address router = dexToContractAddress(contractType, "ROUTERV3");

        try IBancorNetworkInfo(router).tradeOutputBySourceAmount(token0, token1, amountIn)returns(uint amountOut){
            uint32 feeDex = IBancorNetworkInfo(router).tradingFeePPM(token0);
            return ItypeData.EndResult(token0 , amountOut , 0 , amountIn, uint24(feeDex) , false , contractType );
        }catch{
            return ItypeData.EndResult(token0 , amountIn , 0 , 0, 0 , false , contractType );
        }
    }

    function multiHopQuoterUniswapV2(address token0,address token1 , uint amountIn, string memory dexType)public view returns(ItypeData.MultiHop [] memory,uint){

        address [3]  memory middleWareToken = [Weth , Usdt , Usdc];
        address [] memory path = new address[](3);
        address routerV2 = dexToContractAddress(dexType , "ROUTERV2");
        uint count;
        ItypeData.MultiHop [] memory result = new ItypeData.MultiHop[](3);
        path[0] = token0;
        path[2] = token1;

        
        for(uint i = 0 ; i< 3 ; i++){

            if(middleWareToken[i] == token0)continue;
            path[1] = middleWareToken[i]; 
            try IUniswapRouterV2(routerV2).getAmountsOut(amountIn, path) returns(uint [] memory amounts){
                
                if(amounts[2] != 0){
                    result[count] = ItypeData.MultiHop(middleWareToken[i] , amounts[2] , amountIn , 3000 , 3000 ,bytes(""), dexType );
                    count++;
                }
            }catch {
            }   
        }
        
        if(count == 0)return (result,count);

        ItypeData.MultiHop[] memory availableMultiHops = new ItypeData.MultiHop[](count);

        for(uint8 i = 0 ; i < count ; i++){
            availableMultiHops[i] = result[i];
        }

        return (availableMultiHops,count);
    }

    function multiHopUniswapV3(address token0,address token1 , address middleWareToken, uint amountIn)public returns(ItypeData.MultiHop[9] memory result){
        (ItypeData.PoolsData [] memory tokenPool0,ItypeData.PoolsData [] memory tokenPool1) =
         availableUniswapV3Pools(token0 , token1 ,middleWareToken);

         address quoterV3 = dexToContractAddress("UNISWAPV3","QUOTERV2");
         uint count;
         
         for(uint i = 0 ; i < tokenPool0.length ; i++){
            for(uint j = 0 ; j < tokenPool1.length ; j++){
                bytes memory path=abi.encodePacked(token0 , tokenPool0[i].dexFee , middleWareToken , tokenPool1[j].dexFee , token1) ;
                try IQuoterV2(quoterV3).quoteExactInput(path,amountIn) returns(uint256 amountOut, uint160[] memory, uint32[] memory, uint256){
                    result[count++] = ItypeData.MultiHop(middleWareToken,amountOut,amountIn,tokenPool0[i].dexFee,tokenPool1[j].dexFee,path,"UNISWAPV3");
                }catch{

                }
            }
         }

    }

    function availableUniswapV3Pools(address token0,address token1 ,address _middleWareToken)internal view returns(ItypeData.PoolsData [] memory, ItypeData.PoolsData [] memory){
        uint24 [3] memory fees=[uint24(500),3000, 10000];
        ItypeData.PoolsData[3] memory token0Pools;
        ItypeData.PoolsData[3] memory token1Pools;
        address middleWareToken = _middleWareToken;
        uint counter0;
        uint counter1;

        for(uint i = 0 ; i < 3 ; i++){
            address poolAvailable0 = uniswapV3GetSinglePool(token0,middleWareToken,"UNISWAPV3",fees[i]);
            if(poolAvailable0 != address(0)){
                token0Pools[counter0] = ItypeData.PoolsData({pool:poolAvailable0, dexFee:fees[i],middleWareToken:middleWareToken});
                
                counter0++;
            }
            

            address poolAvailable1 = uniswapV3GetSinglePool(token1,middleWareToken,"UNISWAPV3",fees[i]);
            
            if(poolAvailable1 != address(0)){
                token1Pools[counter1] = ItypeData.PoolsData({pool:poolAvailable1, dexFee:fees[i],middleWareToken:middleWareToken});

                counter1++;
            }
            
        }

        ItypeData.PoolsData[] memory token0PoolsTotal = new ItypeData.PoolsData[](counter0);
        ItypeData.PoolsData[] memory token1PoolsTotal = new ItypeData.PoolsData[](counter1);
        
        if(counter0 == 0 || counter1 == 0)return (token0PoolsTotal,token1PoolsTotal); 

        for(uint i = 0 ; i <= counter0 - 1 ; i++){
                token0PoolsTotal[i] = token0Pools[i];
                
            }
        for(uint i = 0 ; i <= counter1 - 1 ; i++){
            
            token1PoolsTotal[i] = token1Pools[i];
        }
        

        return (token0PoolsTotal,token1PoolsTotal);
    } 


    function getDecimalDiffenrence(uint decimal0,uint decimal1 , bool invertInputs)public pure returns(int){
        unchecked{
        int temp;  
        if(invertInputs == true) {
         temp = int(int(decimal0) - int(decimal1));
        }else{
        
         temp = int(decimal1 - decimal0);
        }
        
        return temp;
        }
    }

    function dexToContractAddress(string  memory dex , string memory contractType)public view returns(address){
        return dexsToSymbols[dex][contractType];
    }

    function changeInput(address tokenIn)internal view returns(address){
        return tokenIn == Eth ? Weth : tokenIn;
    }

    function checkDexName(string memory name , string memory dex)public pure returns(bool){
        return keccak256(abi.encodePacked(name)) == keccak256(abi.encodePacked(dex));
    }

    function getPoolLiquidity(address pool)public view returns(uint128){
        return IUniswapPoolsV3(pool).liquidity();
    }

    function changeAdmin(address newAdmin)external onlyAdmin{
        admin = newAdmin;
    }
}