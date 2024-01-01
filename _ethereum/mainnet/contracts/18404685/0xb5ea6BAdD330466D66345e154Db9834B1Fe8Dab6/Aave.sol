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
import "./IAave.sol";
import "./ILendingPoolV2.sol";
import "./ILendingPoolV3.sol";
import "./IWethGateway.sol";

/**
 * @title Aave proxy contract
 * @author Pino development team
 * @notice Contract is used to deposit, withdraw, and repay tokens to the Aave lending pool
 */
contract Aave is IAave, BaseProtocolProxy {
    IWethGateway public immutable wethGateway;
    ILendingPoolV2 public immutable lendingPoolV2;
    ILendingPoolV3 public immutable lendingPoolV3;
    uint16 private constant REFERRAL_CODE = 0;

    /**
     * @notice Sets LendingPool addresses for different Aave versions
     * @param _permit2 Address of Permit2 contract
     * @param _weth Address of WETH9 contract
     * @param _lendingPoolV2 Aave lending pool V2 address
     * @param _lendingPoolV3 Aave lending pool V3 address
     * @param _wethGateway Aave WethGateway contract address
     */
    constructor(
        address _permit2,
        address _weth,
        ILendingPoolV2 _lendingPoolV2,
        ILendingPoolV3 _lendingPoolV3,
        IWethGateway _wethGateway
    ) payable BaseProtocolProxy(_permit2, _weth) {
        wethGateway = _wethGateway;
        lendingPoolV2 = _lendingPoolV2;
        lendingPoolV3 = _lendingPoolV3;
    }

    /**
     * @notice Deposits a token to the lending pool V2 and transfers aTokens to recipient
     * @param _token The underlying token to deposit
     * @param _amount Amount to deposit
     * @param _recipient Recipient of the deposit that will receive aTokens
     */
    function depositV2(address _token, uint256 _amount, address _recipient) external payable {
        lendingPoolV2.deposit(_token, _amount, _recipient, REFERRAL_CODE);

        emit Deposit(msg.sender, _recipient, _token, _amount);
    }

    /**
     * @notice Deposits a token to the lending pool V3 and transfers aTokens to recipient
     * @param _token The underlying token to deposit
     * @param _amount Amount to deposit
     * @param _recipient Recipient of the deposit that will receive aTokens
     */
    function depositV3(address _token, uint256 _amount, address _recipient) external payable {
        lendingPoolV3.supply(_token, _amount, _recipient, REFERRAL_CODE);

        emit Deposit(msg.sender, _recipient, _token, _amount);
    }

    /**
     * @notice Receives aToken and transfers ERC20 token to recipient using lending pool V2
     * @param _token The underlying token to withdraw
     * @param _amount Amount to withdraw
     * @param _recipient Recipient to receive ERC20 tokens
     * @return withdrawn The amount withdrawn from the lending pool
     */
    function withdrawV2(address _token, uint256 _amount, address _recipient)
        external
        payable
        returns (uint256 withdrawn)
    {
        withdrawn = lendingPoolV2.withdraw(_token, _amount, _recipient);

        emit Withdraw(msg.sender, _recipient, _token, _amount);
    }

    /**
     * @notice Burns aToken and transfers ERC20 token to recipient using lending pool V3
     * @param _token The underlying token to withdraw
     * @param _amount Amount to withdraw
     * @param _recipient Recipient to receive ERC20 tokens
     * @return withdrawn The amount withdrawn from the lending pool
     */
    function withdrawV3(address _token, uint256 _amount, address _recipient)
        external
        payable
        returns (uint256 withdrawn)
    {
        withdrawn = lendingPoolV3.withdraw(_token, _amount, _recipient);

        emit Withdraw(msg.sender, _recipient, _token, _amount);
    }

    /**
     * @notice Receives A_WETH and transfers ETH token to recipient using lending pool V2
     * @param _amount Amount to withdraw
     * @param _recipient Recipient to receive ETH
     */
    function withdrawETHV2(uint256 _amount, address _recipient) external payable {
        wethGateway.withdrawETH(address(lendingPoolV2), _amount, _recipient);

        emit Withdraw(msg.sender, _recipient, ETH, _amount);
    }

    /**
     * @notice Receives A_WETH and transfers ETH token to recipient using lending pool V3
     * @param _amount Amount to withdraw
     * @param _recipient Recipient to receive ETH
     */
    function withdrawETHV3(uint256 _amount, address _recipient) external payable {
        wethGateway.withdrawETH(address(lendingPoolV3), _amount, _recipient);

        emit Withdraw(msg.sender, _recipient, ETH, _amount);
    }

    /**
     * @notice Repays a borrowed token using lending pool V2
     * @param _token The underlying token to repay
     * @param _amount Amount to repay
     * @param _rateMode Rate mode, 1 for stable and 2 for variable
     * @param _recipient Recipient to repay for
     * @return repaid The final amount repaid
     */
    function repayV2(address _token, uint256 _amount, uint256 _rateMode, address _recipient)
        external
        payable
        returns (uint256 repaid)
    {
        repaid = lendingPoolV2.repay(_token, _amount, _rateMode, _recipient);

        emit Repay(msg.sender, _recipient, _token, _amount);
    }

    /**
     * @notice Repays a borrowed token using lending pool V3
     * @param _token The underlying token to repay
     * @param _amount Amount to repay
     * @param _rateMode Rate mode, 1 for stable and 2 for variable
     * @param _recipient Recipient to repay for
     * @return repaid The final amount repaid
     */
    function repayV3(address _token, uint256 _amount, uint256 _rateMode, address _recipient)
        external
        payable
        returns (uint256 repaid)
    {
        repaid = lendingPoolV3.repay(_token, _amount, _rateMode, _recipient);

        emit Repay(msg.sender, _recipient, _token, _amount);
    }

    /**
     * @notice Borrows an specific amount of tokens on behalf of the caller from lendingPoolV2
     * @param _token The underlying token to borrow
     * @param _amount Amount to borrow
     * @param _rateMode The interest rate mode at which the user wants to borrow
     * @dev This action transfers the borrowed tokens to the proxy contract
     */
    function borrowV2(address _token, uint256 _amount, uint256 _rateMode) external payable {
        lendingPoolV2.borrow(_token, _amount, _rateMode, REFERRAL_CODE, msg.sender);

        emit Borrow(msg.sender, _token, _amount, _rateMode);
    }

    /**
     * @notice Borrows an specific amount of tokens on behalf of the caller from lendingPoolV3
     * @param _token The underlying token to borrow
     * @param _amount Amount to borrow
     * @param _rateMode The interest rate mode at which the user wants to borrow
     * @dev This action transfers the borrowed tokens to the proxy contract
     */
    function borrowV3(address _token, uint256 _amount, uint256 _rateMode) external payable {
        lendingPoolV3.borrow(_token, _amount, _rateMode, REFERRAL_CODE, msg.sender);

        emit Borrow(msg.sender, _token, _amount, _rateMode);
    }
}
