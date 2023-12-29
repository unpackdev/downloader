// SPDX-License-Identifier: MIT
/*
                                           +##*:                                          
                                         .######-                                         
                                        .########-                                        
                                        *#########.                                       
                                       :##########+                                       
                                       *###########.                                      
                                      :############=                                      
                   *###################################################.                  
                   :##################################################=                   
                    .################################################-                    
                     .*#############################################-                     
                       =##########################################*.                      
                        :########################################=                        
                          -####################################=                          
                            -################################+.                           
               =##########################################################*               
               .##########################################################-               
                .*#######################################################:                
                  =####################################################*.                 
                   .*#################################################-                   
                     -##############################################=                     
                       -##########################################=.                      
                         :+####################################*-                         
           *###################################################################:          
           =##################################################################*           
            :################################################################=            
              =############################################################*.             
               .*#########################################################-               
                 :*#####################################################-                 
                   .=################################################+:                   
                      -+##########################################*-.                     
     .+*****************###########################################################*:     
      +############################################################################*.     
       :##########################################################################=       
         -######################################################################+.        
           -##################################################################+.          
             -*#############################################################=             
               :=########################################################+:               
                  :=##################################################+-                  
                     .-+##########################################*=:                     
                         .:=*################################*+-.                         
                              .:-=+*##################*+=-:.                              
                                     .:=*#########+-.                                     
                                         .+####*:                                         
                                           .*#:    */
pragma solidity 0.8.18;

import "./BaseProtocolProxy.sol";
import "./ISwap.sol";

/**
 * @title Swap Proxy contract
 * @author Pino development team
 * @notice Swaps tokens and send the new token to the recipient
 */
contract Swap is ISwap, BaseProtocolProxy {
    address public immutable zeroX;
    address public immutable oneInch;
    address public immutable paraSwap;

    /**
     * @notice Sets protocol addresses and approves WETH to them
     * @param _permit2 Permit2 contract address
     * @param _weth WETH9 contract address
     * @param _zeroX 0x contract address
     * @param _oneInch 1Inch contract address
     * @param _paraSwap ParaSwap contract address
     */
    constructor(address _permit2, address _weth, address _zeroX, address _oneInch, address _paraSwap)
        payable
        BaseProtocolProxy(_permit2, _weth)
    {
        zeroX = _zeroX;
        oneInch = _oneInch;
        paraSwap = _paraSwap;
    }

    /**
     * @notice Swaps using 0x protocol
     * @param _calldata 0x protocol calldata from API
     */
    function swapZeroX(bytes calldata _calldata) external payable {
        (bool success,) = zeroX.call(_calldata);

        if (!success) {
            revert FailedToSwapUsingZeroX(msg.sender);
        }
    }

    /**
     * @notice Swaps using 1Inch protocol
     * @param _calldata 1Inch protocol calldata from API
     */
    function swapOneInch(bytes calldata _calldata) external payable {
        (bool success,) = oneInch.call(_calldata);

        if (!success) {
            revert FailedToSwapUsingOneInch(msg.sender);
        }
    }

    /**
     * @notice Swaps using ParaSwap protocol
     * @param _calldata ParaSwap protocol calldata from API
     */
    function swapParaSwap(bytes calldata _calldata) external payable {
        (bool success,) = paraSwap.call(_calldata);

        if (!success) {
            revert FailedToSwapUsingParaSwap(msg.sender);
        }
    }
}
