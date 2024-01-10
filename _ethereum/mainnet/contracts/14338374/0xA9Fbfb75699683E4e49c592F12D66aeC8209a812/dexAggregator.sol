// SPDX-License-Identifier: MIT

pragma solidity ^0.6.6 || ^0.8.0;
import "./IbalancerV2.sol";
import "./IERC20.sol";
import "./IAsset.sol";
import "./IUniswapV2Router02.sol";

contract aggregator{
       
    address private constant ETH =  0x0000000000000000000000000000000000000000;
    address private constant factory = 0x5C69bEe701ef814a2B6a3EDD4B1652CB9cc5aA6f;
    address private constant UNISWAP_ROUTER_ADDRESS = 0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D;
    address private constant balancerVault = 0xBA12222222228d8Ba445958a75a0704d566BF2C8;
     event BeeSwap(
        address sender,
        address tokenIn,
        address tokenOut,
        uint256 tokenInAmount,
        uint256 tokenOutAmount,
        uint256 timeStamp
    );

    uint optionIndex = 0;
    uint amountOut  = 0; 
    uint pathindex = 0;
    uint amountIn = 0;
    uint balOutput;
    address sender;
    address tokenOut;
    address tokenIn;
    address[]  updPath;
    
    fallback() external payable {
    //get facet from function selector
    //for receiving eth from Uniswap & balancer
    }
    
    function swapAggregatedRoute(
        
        address [] memory tokenInOut,
        uint[] memory dexRoute,   
        uint[] memory amountInOut,  
        int[] memory options,           
        address[] memory path,
        Ibal.SingleSwap memory singleswap,
        uint limit,
        Ibal.BatchSwapStep [] memory swaps,
        IAsset[] memory assets,
        Ibal.SwapKind kind,
        int256[] memory limits,
        uint deadline
        
        )
        external payable{
            uint [] memory dexRoute1 = dexRoute;
            uint256 [] memory output;
            Ibal.FundManagement memory funds; 
            funds.sender=address(this);
            funds.fromInternalBalance = false;
            funds.recipient = payable(address(this));
            funds.toInternalBalance = false;
            sender = msg.sender;
            amountIn  = amountInOut[0];
            amountOut = amountInOut[1];
            tokenIn  = tokenInOut[0];
            tokenOut = tokenInOut[1];
           
            for(uint i=0; i<dexRoute1.length; i++){

                if(dexRoute1[i] == 0)
                {      
                    updPath = [path[pathindex], path[pathindex+1]];                
                    
                    if(i==0)
                    {
                        if(options[optionIndex]==0){
                            IERC20(updPath[0]).transferFrom(sender, address(this), amountIn);
                            IERC20(updPath[0]).approve(UNISWAP_ROUTER_ADDRESS, amountIn);
                            output=IUniswapV2Router02(UNISWAP_ROUTER_ADDRESS).swapExactTokensForTokens(amountIn,amountOut,updPath,address(this),deadline);    
                        }

                        if(options[optionIndex]==1){
                            IERC20(updPath[0]).transferFrom(sender, address(this), amountIn);
                            IERC20(updPath[0]).approve(UNISWAP_ROUTER_ADDRESS, amountIn);
                            output=IUniswapV2Router02(UNISWAP_ROUTER_ADDRESS).swapExactTokensForETH(amountIn,amountOut,updPath,address(this),deadline);    
                        }

                        if(options[optionIndex]==2){
                            output=IUniswapV2Router02(UNISWAP_ROUTER_ADDRESS).swapExactETHForTokens{ value: msg.value }(amountOut,updPath,address(this),deadline);
                        }

                        else if(options[optionIndex]>2){
                            revert('invalid option');
                        }     
                    }

                    else if(i==1 || i == 2){
                        
                        if(options[optionIndex]==0){
                            IERC20(updPath[0]).approve(UNISWAP_ROUTER_ADDRESS, amountIn);
                            output=IUniswapV2Router02(UNISWAP_ROUTER_ADDRESS).swapExactTokensForTokens(amountIn,amountOut,updPath,address(this),deadline);
                        }

                        if(options[optionIndex]==1){
                            IERC20(updPath[0]).approve(UNISWAP_ROUTER_ADDRESS, amountIn);
                            output=IUniswapV2Router02(UNISWAP_ROUTER_ADDRESS).swapExactTokensForETH(amountIn,amountOut,updPath,address(this),deadline);
                        }

                        if(options[optionIndex]==2){
                            output=IUniswapV2Router02(UNISWAP_ROUTER_ADDRESS).swapExactETHForTokens{ value: amountIn }(amountOut,updPath,address(this),deadline);    
                        }

                        else if(options[optionIndex]>2){
                            revert('invalid option');
                        }
                    }
                    
                    else {
                        revert('invalid dexRoute');
                    }

                    if(dexRoute1.length == 3 && dexRoute1[1]==1){
                        pathindex++;  
                    }
                   
                   amountIn = output[1];  
                   pathindex++; 
                   optionIndex++;
                }

            if(dexRoute1[i] == 1)
            { 
                if(i==0){

                    if(address(singleswap.assetIn) == ETH){
                        balOutput= Ibal(balancerVault).swap{value: msg.value}(singleswap, funds, limit, deadline);    
                    }

                    else{
                        IERC20(address(singleswap.assetIn)).transferFrom(sender, address(this), singleswap.amount);
                        IERC20(address(singleswap.assetIn)).approve(balancerVault,  singleswap.amount);
                        balOutput=Ibal(balancerVault).swap(singleswap, funds, limit, deadline);
                    }
                    amountIn = balOutput;
                }
                else if(i==1 || i == 2){
                    if(address(singleswap.assetIn) == ETH){
                        singleswap.amount = output[1];
                        balOutput= Ibal(balancerVault).swap{value:  output[1]}(singleswap, funds, limit, deadline);         
                    }

                    else{
                        singleswap.amount = output[1];
                        IERC20(address(singleswap.assetIn)).approve(balancerVault,  output[1]);
                        balOutput=Ibal(balancerVault).swap(singleswap, funds, limit, deadline);   
                    }
                    amountIn = balOutput;
                }
                else {
                    revert('invalid dexRoute');            
                }
            }  

            if(dexRoute1[i] == 2)
            {
                if(i==0){
                    
                    if(address(assets[0]) == ETH){
                    Ibal(balancerVault).batchSwap { value: msg.value }(kind, swaps, assets, funds, limits, deadline);
                    }

                    else{
                        IERC20(address(assets[0])).transferFrom(sender, address(this),  swaps[0].amount);
                        IERC20(address(assets[0])).approve(balancerVault,  swaps[0].amount);
                        Ibal(balancerVault).batchSwap(kind, swaps, assets, funds, limits, deadline);
                    }    
                }

                else if(i==1 || i==2){
                    
                    if(address(assets[0]) == ETH){
                        swaps[0].amount = output[1];
                        limits[0] = int256(output[1]);    
                        Ibal(balancerVault).batchSwap { value: output[1] }(kind, swaps, assets, funds, limits, deadline);
                    }

                    else{
                        swaps[0].amount = output[1];
                        limits[0] = int256(output[1]);
                        IERC20(address(assets[0])).approve(balancerVault,  swaps[0].amount);
                        Ibal(balancerVault).batchSwap(kind, swaps, assets, funds, limits, deadline);
                    }
                }
                if(dexRoute1[0] == 2 && dexRoute1.length>1){
                    if(address(assets[0]) == ETH){
                        Ibal(balancerVault).batchSwap { value: msg.value }(kind, swaps, assets, funds, limits, deadline);
                        amountIn=IERC20(address(assets[2])).balanceOf(address(this));
                    }
                    else{

                        IERC20(address(assets[0])).transferFrom(sender, address(this),  swaps[0].amount);
                        IERC20(address(assets[0])).approve(balancerVault,  swaps[0].amount);
                        Ibal(balancerVault).batchSwap(kind, swaps, assets, funds, limits, deadline);
                        if(address(assets[2])==ETH){
                            amountIn = address(this).balance;
                        }
                        else{
                            amountIn=IERC20(address(assets[2])).balanceOf(address(this));
                        }
                    
                    } 
                }
            }
        }

        transfer(amountInOut[0],tokenIn,tokenOut,msg.sender);
        optionIndex = 0;
        pathindex = 0;
        amountOut=0;
        
    }

    
    function transfer(uint amountIn0, address TokenIn, address TokenOut, address msgSender) internal{
        uint amountReceived;
        if(TokenOut==ETH)
        {   
            amountReceived =address(this).balance;
            payable(msgSender).transfer(address(this).balance);
            emit BeeSwap(msgSender, TokenIn, TokenOut, amountIn0, amountReceived, block.timestamp); 
        }
        else{

            amountReceived = IERC20(TokenOut).balanceOf(address(this));
            IERC20(TokenOut).transfer(msgSender,amountReceived);
            emit BeeSwap(msgSender, TokenIn, TokenOut, amountIn0, amountReceived, block.timestamp);
        }
            
    }
        
    function swapV2Router(
        uint256 amountIn0,
        uint256 amountOut1,
        uint256 deadline,
        address[] calldata path,
        uint8 option
    ) external payable {
        require(path.length >= 2, "RouterInteraction:: Invalid Path length");
        require(
            path[0] != address(0) || path[path.length - 1] != address(0),
            "RouterInteraction:: Invalid token address"
        );

        address sender1 = msg.sender;
        uint[] memory amounts;
        if (option == 0) {
            IERC20(path[0]).transferFrom(sender1, address(this), amountIn0);
            IERC20(path[0]).approve(UNISWAP_ROUTER_ADDRESS, amountIn0);
            amounts = IUniswapV2Router02(UNISWAP_ROUTER_ADDRESS).swapExactTokensForTokens(
                amountIn0,
                amountOut1,
                path,
                sender1,
                deadline
            );
        } else if (option == 1) {

            IERC20(path[0]).transferFrom(sender1, address(this), amountIn0);
            IERC20(path[0]).approve(UNISWAP_ROUTER_ADDRESS, amountIn0);
            amounts = IUniswapV2Router02(UNISWAP_ROUTER_ADDRESS).swapExactTokensForETH(
                amountIn0,
                amountOut1,
                path,
                sender1,
                deadline
            );
        } else if (option == 2) {
            require(msg.value > 0, 'Invalid Eth amount.');
            require(amountIn0 == msg.value, 'Invalid input amounts.');
            amounts = IUniswapV2Router02(UNISWAP_ROUTER_ADDRESS).swapExactETHForTokens{ value: msg.value }(
                amountOut1,
                path,
                sender1,
                deadline
            );
        } else {
            revert('Invalid option.');
        }
        
        amountOut1 = amounts[amounts.length-1];
        emit BeeSwap(sender1, path[0], path[path.length - 1], amountIn0, amountOut1, block.timestamp);
    }       
}